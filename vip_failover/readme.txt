## Please uncomment the following commented commands when using them

############## PLEASE CONFIGURE AWS CLI BEFORE IT. ##############

### Make the changes mentioned in script "vip_failover.sh"


### Make cron entry like below(Uncomment following command once script is placed properly):-
#@reboot nohup /bin/bash /etc/vip_failover/run_vipfailover.sh >> /etc/vip_failover/log.txt 2>&1 &


### Run script on terminal as below
#nohup /bin/bash /etc/vip_failover/run_vipfailover.sh >> /etc/vip_failover/log.txt 2>&1 &


### LOGICAL-FLOW OF THE SCRIPT FOR VIP FAILOVER IN AWS EC2 (SHOULD RUN ON EACH SERVER):-

#CHK-SELF-VIP
#	IF YES -> EXIT
#	IF NO -> CHK-SELF-APPLICATION
#				-> IF NO -> EXIT
#				-> IF YES -> CHK-REMOTE-APPLICATION (PLEASE USE VIP HERE)
#								-> IF NO -> SWITCHOVER VIP TO ITSELF
#								-> IF YES -> EXIT

