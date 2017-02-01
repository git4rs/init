#!/bin/bash
log='/etc/vip_failover/log.txt'

date >> $log
while [ true ]
do
	st=`ps -lef | grep '/etc/vip_failover/vip_failover.sh' | grep -vc grep`
	if [ $st -eq 0 ];then
		echo "Running script"
		nohup /bin/bash /etc/vip_failover/vip_failover.sh >> /etc/vip_failover/log.txt 2>&1 &
	else
		echo "Already running"
	fi
sleep 2
done
