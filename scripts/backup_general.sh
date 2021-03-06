#!/bin/bash

old_date=`date --date=yesterday +%Y-%m-%d`
old_date1=`date --date=yesterday +%m-%d-%Y`
old_date2=`date --date=yesterday +%d-%m-%Y`
#old_date='2016-09-25'
#old_date1='09-25-2016'
#old_date2='25-09-2016'


srcIP=`ifconfig  | grep 10.140 | awk -F: '{print $2}' | awk '{print $1}'`
dstIP="10.140.31.35" ## 10.140.31.121 in case of PG 
targetFldr='/alog' ## /alogs in case of PG
logFldrBase="/opt/backupreport/BACKUP"
logFldr="$logFldrBase/$old_date"
dstFldr="$targetFldr/$srcIP/$old_date"
bkpElgblFiles="$logFldr/BackupEligibleFiles.txt"
compressed_bkpElgblFiles="$logFldr/BackupEligibleFiles_Compressed.txt"
rsyncLog="$logFldr/rsync.log"
rsyncSuccessLog="$logFldr/rsync_successful.log"
integritySuccess="$logFldr/integrity_backup_success.log"
integrityFail="$logFldr/integrity_backup_failed.log"
delElgbl="$logFldrBase/deletion_eligible_files_${old_date}.txt"
deletedFiles="$logFldrBase/deleted_${old_date}.txt"


findNcompress_logs(){

if [ ! -d $logFldr ]; then mkdir -p $logFldr; fi

## Finding all log files except kafka containing yesterday's date in variuos formats 
find $targetFldr -type f  \( -name "*log*$old_date*" -o -name "*log*$old_date1*" -o -name "*log*$old_date2*" \) \( ! -name "*bz2" ! -name "*kafka*" \) -exec ls -1 {} \; >> $bkpElgblFiles

sort -u $bkpElgblFiles > ${bkpElgblFiles}_sorted ; mv ${bkpElgblFiles}_sorted $bkpElgblFiles

## Bzipping all log files found in above step
for i in `cat $bkpElgblFiles` 
do 
	/usr/bin/bzip2 $i
	if [ $? -eq 0 ];then echo $i.bz2 >> $compressed_bkpElgblFiles; fi
done 
}


## Sending compressed logs to backup server
transferLogs(){

## Rsync
for i in `cat $compressed_bkpElgblFiles`; do echo $i;/usr/bin/rsync -aR --bwlimit=10240 --rsync-path="mkdir -p $dstFldr && rsync" --log-file=$rsyncLog $i root@$dstIP:$dstFldr; done
#for i in `cat $compressed_bkpElgblFiles`; do echo $i;/usr/bin/rsync -aR  --log-file=$rsyncLog $i root@$dstIP:$dstFldr; done

## RSYNC SUCCESS CHK:-
grep '<f' $rsyncLog | awk '{print $NF}' >> $rsyncSuccessLog

## INTEGRITY CHK:-

for i in `cat $compressed_bkpElgblFiles`
do
  status=`grep -c "$i" $rsyncSuccessLog`
  if [ $status -eq 0 ];then
  	  echo $i >> $integrityFail
  else
	  echo $i >> $integritySuccess
  fi
done

## MAIL FOR FAILED BACKUPS:-
if [ -s $integrityFail ]  ## If file exists & has some content
then
/bin/cat $integrityFail | /bin/mail -s "Backup Failed on NetMagic host $srcIP to $dstIP for following log files" -r backup@paytm.com infraops@paytm.com
fi

}

delete_old(){

## Finding 4 days older deletion eligible files 
for i in `find $logFldrBase -type f -name "*integrity_backup_success.log*" -mtime +4`; do /bin/cat $i >> $delElgbl; done
sort -u $delElgbl > ${delElgbl}_sorted; mv ${delElgbl}_sorted $delElgbl

## Deleting eligible files
for i in `/bin/cat $delElgbl`
do
rm -f $i
if [ $? -eq '0' ];then echo $i >> $deletedFiles;fi
done

}

main(){
findNcompress_logs
transferLogs
delete_old
}

main
