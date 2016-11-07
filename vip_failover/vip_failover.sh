#!/bin/bash
## Purpose:- To Achieve automatic VIP Failover in AWS Environment as available tools such as (Keepalived,Heartbeat) does not 
## work in AWS since AWS does not support Multicast
## Please change following values:-
  ## <VIP>
  ## <SELF_CHK>
  ## <REMOTE_CHK>
  ## <STATUS>


VIP='10.0.5.74'
baseDir='/etc/vip_failover'
ifaceDetails="$baseDir/ifaceDetails.txt"

if [ ! -d $baseDir ]; then mkdir -p $baseDir;fi
date

cat /dev/null > $ifaceDetails 

## Check VIP on Self
output=`/sbin/ifconfig | /bin/grep -c $VIP`
if [ $output -eq '1' ];then
	echo "VIP exists"
	exit
else
	echo "VIP does not exist"
	## Chk Self Nginx
	nginx_self=$(/usr/bin/curl -k -s -o /dev/null -w "%{http_code}" http://localhost/health)
	if [ $nginx_self -ne '200' ];then
		echo "VIP & Nginx both are not working on this server. So VIP switchover is neither eligible not possible. Exitting"
		exit
	else
		## Chk remote Nginx
		nginx_remote=$(/usr/bin/curl -k -s -o /dev/null -w "%{http_code}" http://$VIP/health)  ## Use VIP in this command
		if [ $nginx_remote -eq '200' ];then
			echo "VIP & Nginx on remote server are working fine. Exitting"
		else
			echo "Nginx on remote server is not working. Hence switching over VIP to current host"
			## Getting N/W Interface details
			aws ec2 describe-network-interfaces --filters "Name=private-ip-address,Values=$VIP" --output json | egrep "NetworkInterfaceId|Status|AttachmentId" | grep -v in-use > $ifaceDetails
			
			## Exit if no details of NW Iface is captured
			if [ ! -s $ifaceDetails ];then echo "No details of NW Interface Captured. Hence Exitting";exit;fi

			attachmentID=$(grep -i AttachmentId $ifaceDetails | awk '{print $2}' | sed 's/[",]//g')
			echo "attachmentID:- $attachmentID"
			ifaceID=$(grep -i NetworkInterfaceId $ifaceDetails | awk '{print $2}' | sed 's/[",]//g')
			echo "ifaceID:-$ifaceID"
			
			## Detaching Interface if any/both variable(s) exist(s)
			if [[ ! $ifaceID ]];then echo "Exitting in absence of any/both variables";exit;fi
			if [[ $attachmentID ]];then aws ec2 detach-network-interface --attachment-id $attachmentID;fi
			if [ $? -ne '0' ];then echo "Interface could not be detached. Hence exitting";exit;fi
			
			cnt=600
			while [ $cnt -ge 0 ]
			do
				aws ec2 describe-network-interfaces --filters "Name=private-ip-address,Values=$VIP" --output json | egrep "NetworkInterfaceId|Status|AttachmentId" | grep -v in-use > $ifaceDetails
				ifaceID=$(grep -i NetworkInterfaceId $ifaceDetails | awk '{print $2}' | sed 's/[",]//g')
				Status=$(grep -i Status $ifaceDetails | awk '{print $2}' | sed 's/[",]//g')
				if [ $Status == 'available' ];then
					## Attaching Interface now to self
					instID=$(ec2metadata --instance-id)
					if [[ ! $ifaceID || ! $instID ]];then echo "Exitting in absence of any/both variables";exit;fi
					aws ec2 attach-network-interface --network-interface-id  $ifaceID --instance-id $instID --device-index 1
					## Check if inteface is attached successfully
					counter=600
					while [ $counter -ge 0 ]
					do
						output=`/sbin/ifconfig | /bin/grep -c $VIP`
						if [ $output -eq '1' ];then
						        echo "VIP has been attached to self - $instID"
						        exit
							sleep 0.5
							cnt=$(( $cnt - 1 ))
						fi
					done
						echo "Issue is attaching VIP. Please check !!!!"
						exit
				fi
				sleep 0.5
				cnt=$(( $cnt - 1 ))
			done	
				echo "ENI could not be detached successfully, hence VIP switchover is not possible. Please check"
				exit
		fi			
			
	fi
fi
