#!/bin/bash

old_date='2015-05-26'
#old_date=`date --date=yesterday +%Y-%m-%d`


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
for i in `ls`
do
if [ -d $i -a $i != 'lost+found' ];then
	if [ $i == 'walletlogs' ];then	## If walletlogs dir found, then going into subdirectories one-by-one	
		cd $i
		for j in `ls`
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
nohup /bin/bash /root/script/backup.sh  &
}

main
#backup

