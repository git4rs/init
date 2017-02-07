#!/bin/bash
reten='+2'
log_filename=integrity.log
src_dir='/alog/'
LOGPATH='/var/log'

if [ -d $LOGPATH ];then
        echo "$LOGPATH exists"
else
        echo "creating folder $LOGPATH doesn't exists"
        echo  "creating $LOGPATH folder"
        mkdir -p $LOGPATH
        echo  "$LOGPATH folder created"
fi



info_log()
{
        PARAMETER=$1
        echo "`date +%Y-%m-%d-%H` $SERVER $INFO :[$$]: $0 $PARAMETER" >> $LOGPATH/deleted.log
      #  echo "`date +%Y-%m-%d-%H` $SERVER $INFO :[$$]: $0 'file deleted' " >> $LOGPATH/deleted.log

}

critical_log()
{
        PARAMETER=$1
        echo "`date +%Y-%m-%d-%H` $SERVER $CRITICAL :[$$]: $0 $PARAMETER" >> $LOGPATH/critical_deleted.log
        exit 1
}

for i in `find /opt/backupreport/ -type f -name "*$log_filename*" -mtime $reten -exec grep  md5Matched:OK {} \; | awk '{print $3}'`; 
do 
	filePath=`find $src_dir -type f -name $i`
	rm -f  $filePath 
	#echo  $filePath 
	if [ $? -eq 0 ]
        then
        info_log "$i exists and deleted as older than $reten days"
        fi
done

find /alog/ -type d -empty -name "*201*" -exec rmdir {} \;
#find /alog/ -type d -empty -name "*201*"
