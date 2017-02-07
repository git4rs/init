web_server=`ls /opt/backupreport/10.140.31.76/walletlogs/`
1day_ago=`date --date "1 days ago" +"20%y-%m-%d"`
2day-ago=`date --date "2 days ago" +"20%y-%m-%d"`

for a in `cat $web_server`
do

folder_todel=`ls /opt/backupreport/10.140.31.76/walletlogs/$a/|grep -v total|grep -v $1day_ago |grep -v $2day-ago`
cd /opt/backupreport/10.140.31.76/walletlogs/$a/
pwd


done
