#!/bin/bash
## Author:- Rohit Sharma
## Date:- 28-Oct-2016
## Purpose:- To delete ES indices older than specified days & matching patterns

esIP='10.140.31.29'
esPort='9200'
days=8 ## Days to preserve indices including today
dateFormat="%Y.%m.%d"  ## Indices date format
esIP='10.140.31.29'
esPort='9200'
patterns='logstash-|wallet_' ## Patterns to match indices for deletion. Multiple patterns to be separated by pipe 
excludePatterns='.kibana' ## Exclude index patterns for deletion. Multiple patterns to be separated by pipe
email='infraops@paytm.com udai.mehra@paytm.com'  ## List of Email IDs separated by space to send notification in case of index deletion failure
baseDir='/var/log/ES_Delete'
log="$baseDir/esIndices_delete_`date +%Y.%m.%d`.log"

if [ ! -d $baseDir ];then mkdir -p $baseDir;fi

date >> $log

excludeDates=`seq 0 $days | xargs -i date --date "{} days ago" "+$dateFormat" | tr -s '\n' '|' | sed 's/|$//'`
echo "Excluded Dates :- $excludeDates" >> $log

deletionEligibleIndices=`curl -s http://${esIP}:$esPort/_cat/shards  |  awk '{print $1}'| egrep "$patterns" | egrep -v "$excludePatterns" | egrep -v "$excludeDates" | sort -u`
echo "Deletion Eligible Indices:- $deletionEligibleIndices" >> $log
echo >> $log

if [ ! "$deletionEligibleIndices" ];then echo "Exiting as there is no eligible index for deletion is found" >> $log;exit;fi
echo >> $log

## Delete Eligible Indices
for index in $deletionEligibleIndices
do
echo "Deleting Index:- $index" >> $log
echo "curl -XDELETE http://$esIP:$esPort/$index" >> $log
status=`curl -s -XDELETE http://$esIP:$esPort/$index`
	if [[ $status =~ 'true' ]]
	then 
	echo "Index $index is deleted successfully" >> $log
	echo >> $log
	else 
	echo "Issue in deleting index $index. Sending Email" >> $log
	echo "Issue in deleting index $index on $esIp:$esPort" | mail -s "Issue in deleting Index $index" $email
	echo >> $log
	fi
done

echo "==================================" >> $log
echo >> $log
