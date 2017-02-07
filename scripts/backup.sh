#!/bin/bash
old_date=`date --date=yesterday +%Y-%m-%d`
#old_date="2015-02-28"
src_ip=10.140.31.76
des_ip=10.140.31.35


navigateFolders(){
cd /alog
for fldrs in `ls -l | grep '^d' | grep -v kafka | awk '{print $NF}' | tr -s '\n' ' '`
do
if [ $fldrs != 'lost+found' ];then
        if [ $fldrs == 'walletlogs' ];then  ## If walletlogs dir found, then going into subdirectories one-by-one   
		cd $fldrs
                for j in `ls -l | grep '^d' | awk '{print $NF}' | tr -s '\n' ' '`
                do
                        cd $j
			folder="$fldrs/$j"
			assignVariables $folder		
                        main
			cd ..
                done
                cd ..
        else
                	cd  $fldrs
			folder="$fldrs"
			assignVariables $folder		
                	main
			cd ..
        fi
fi

done

}

assignVariables(){

folder=$1

src_dir=/alog/$folder/$old_date
des_dir="/alog/$src_ip/$folder/$old_date"
src_logdir="/opt/backupreport/$src_ip/$folder/$old_date"
des_logdir="/alog/backupreport/$src_ip/$folder"
src_logRsync="$src_logdir/$src_ip.log"
des_logRsync="$des_logdir/$old_date"
src_md5dir=/opt/backupreport/$folder/md5sum
des_md5dir=$des_logdir/md5sum
src_logIntegrity="$src_logdir/${src_ip}_integrity.log"
des_logIntegrity="$des_logdir/${old_date}_integrity.log"

mkdir -p $src_logdir $src_md5dir

}





integrity_log()
{
        PARAMETER=$1
        echo "`date +%Y-%m-%d:%H-%m` `basename $0` $PARAMETER" >>  $src_logIntegrity

}

send_mail()
{
	CONTENT=$1
	echo -e "$CONTENT" | mail -s "Data backup issue | $src_ip to $des_ip" rohit.sharma@paytm.com pawan.sharma@paytm.com abhishek.upadhyay@one97.net
}

#rsync -avz --rsync-path="mkdir -p $des_dir  && rsync"  --progress $src_dir/wallet-web.log.$old_date*  $des_ip:$des_dir >> $src_logRsync

rsyncCmd(){
#echo $des_dir $des_logdir $des_md5dir 
rsync -avz --bwlimit=10240 --rsync-path="mkdir -p $des_dir $des_logdir $des_md5dir  && rsync"  --progress $src_dir/*  $des_ip:$des_dir/ >> $src_logRsync

integrity_chk

}


## retry $file  -  This function is called when the source & destincation files have difference md5sum. It retries 3 more times then sends the Email to respective user(s).
## $file - Filename which could not be copied successfully.

retry(){

file=$1
cnt=1

while [ $cnt -lt 4 ];do
	src_hash="src_${file}_hash"
	des_hash="des_${file}_hash"
	rsync -avz --rsync-path="mkdir -p $des_dir  && rsync"  --progress $src_dir/$file  $des_ip:$des_dir/ >> $src_logRsync
 	md5sum $src_dir/$file > $src_md5dir/$src_hash
	rsync -avz --rsync-path="cd $des_dir && md5sum $file > $des_md5dir/$des_hash && rsync" $des_ip:$des_md5dir/$des_hash $src_md5dir >> /dev/null
	src_hashVal=`cut -d' ' -f1 $src_md5dir/$src_hash`	
	des_hashVal=`cut -d' ' -f1 $src_md5dir/$des_hash`	
	logLocation=`grep -n $file $src_logIntegrity  | tail -1 | cut -d: -f1`
	if [ $src_hashVal == $des_hashVal ]
	then
		sed -i "${logLocation}a \\\t\t\t\t\t\t\tRetrying $cnt.. $file src_md5:$src_hashVal des_md5:$des_hashVal md5Matched:OK Backup:Success" $src_logIntegrity
		cnt=5		
	else
		sed -i "${logLocation}a \\\t\t\t\t\t\t\tRetrying $cnt.. $file src_md5:$src_hashVal des_md5:$des_hashVal md5Matched:NO Backup:Failed" $src_logIntegrity
		
	fi
	let cnt=cnt+1
done

	if [ $cnt -eq 4 ];then
		logLocation=`grep -n $file $src_logIntegrity  | tail -1 | cut -d: -f1`
		sed -i "${logLocation}a \\\t\t\t\t\tBackup of $file failed after 4 attempts... Manual intervention required!!!" $src_logIntegrity
		
		content="Dear Admin,\n\n\tBackup of $file failed after 4 attempts from $src_ip to $des_ip. Manual Intervention required.\n\nRegards\nPaytm Team\n"
		
		send_mail "$content"
	fi
}


log_transfer(){
rsync -avz --rsync-path="mkdir -p $des_logdir  && rsync" $src_logRsync $des_ip:$des_logRsync >> /dev/null
rsync -avz --rsync-path="mkdir -p $des_logdir && rsync"  $src_logIntegrity $des_ip:$des_logIntegrity >> /dev/null
}


### INTEGRITY CHECK -- Following code is to check the integrity of backed up files whether every file is copied successfully or not ###

integrity_chk(){

cd $src_dir; md5sum * > $src_md5dir/src_hashoffiles
#echo "COMMAND:-  rsync -avz --rsync-path=\"cd $des_dir && md5sum * > ~/des_hashofffiles && rsync\" $des_ip:~/des_hashofffiles ~ >> /dev/null"
rsync -avz --rsync-path="cd $des_dir && md5sum * > $des_md5dir/des_hashofffiles && rsync" $des_ip:$des_md5dir/des_hashofffiles $src_md5dir >> /dev/null
cd -

for i in `ls $src_dir`
do
src_md5=`grep $i  $src_md5dir/src_hashoffiles | cut -d' ' -f1`
des_md5=`grep $i $src_md5dir/des_hashofffiles | cut -d' ' -f1`
	if [ $src_md5 == $des_md5 ]
	then 
		integrity_log "$i	src_ip:$src_ip	des_ip:$des_ip	src_md5:$src_md5	des_md5:$des_md5	md5Matched:OK	Backup:Succes"
	else
		integrity_log "$i	src_ip:$src_ip	des_ip:$des_ip	src_md5:$src_md5	des_md5:$des_md5	md5Matched:NO	Backup:Failed"
		retry $i
		#send_mail "Issue in copying $i from $src_ip to $des_ip as md5sum differs on both sides. Please look into it at the earliest."  
	fi
done

### INTEGRITY CHECK -- END ###

log_transfer
}




main(){
rsyncCmd
}

navigateFolders
