file='/root/script/rem_elgbl_files.txt'
copyStatus='/root/script/s3copy_files.log'
deletedFiles='/root/script/removed_files.log'

mkdir /root/script

echo > $file
echo > $copyStatus
## Find files older than 100 days
for i in `find /alogs -type f  -mtime +100   | egrep -v 'backupreport|local_repo|paytm1|system-logs-oldbkp'`; do echo $i >> $file; done

## Filter the path & sort
rev $file | cut -d/ -f2- | rev | sed 's|^/||g' | sort -u > ${file}_filtered_sorted
mv ${file}_filtered_sorted $file


for i in `cat $file`
do
##Simulate folder:-
aws s3api put-object --bucket nm-pg-app-logs --key $i/

##Copy files:-
nohup trickle -s -u 10000 s3cmd put -r /$i/ s3://nm-pg-app-logs/$i/ >> $copyStatus &

## Remove copied files from server
for i in `awk -F"'" '{print $2}' $copyStatus  | sed '/^$/d'`; do  rm -f $i;if [ $? -eq '0' ];then echo $i >> $deletedFiles;fi; done

done
