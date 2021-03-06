#!/bin/bash

old_date=`date --date=yesterday +%Y-%m-%d`


mkdir_olddate(){
if [ ! -d $old_date ];then mkdir $old_date;fi
}

zipmove(){
mkdir_olddate
for file in `ls *log*$old_date*`
do
bzip2 -f $file
done
mv  *log*$old_date*bz2 $old_date/
cd ..
}



main(){
cd /alog
for i in `ls -l | grep '^d' | awk '{print $NF}' | tr -s '\n' ' '`
do
if [ $i != 'lost+found' -a $i != 'kafka' ];then
	if [ $i == 'walletlogs' ];then	## If walletlogs dir found, then going into subdirectories one-by-one	
		cd $i
		for j in `ls -l | grep '^d' | awk '{print $NF}' | tr -s '\n' ' '`
		do
		echo "PWD:- `pwd`"
			cd $j
			zipmove
		done
		cd ..
	else
		echo "PWD:- `pwd`"
		cd  $i
		zipmove
	fi
fi
done
}


backup(){
/bin/bash /root/script/backup.sh
if [ $? -eq 0 ]
then
/bin/bash /root/script/retention.sh
else
echo "Failed to sync backup Kindly check"| mail -s "Backup status Report of NetMagic $HOSTNAME" -r backup@paytm.com  sysadmin@paytm.com
fi
}

main
backup

