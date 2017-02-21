#!/usr/bin/env python
## Author :- Rohit Sharma
## Date:- 09-Feb-2017
## Purpose :- To put/remove maintenance on zabbix hosts 
import sys, getopt
from optparse import OptionParser

#use JSON;

url = "http://172.21.20.39/zabbix/api_jsonrpc.php" # change <zabbix server> to your zabbix server
apiuser = "maintenance" # API User's Username
apipassword = 'pT47_*Ac7J' # API User's password
global hostname
global duration
duration = 10800
hostid, maintenanceid = '',''

### Usage function
def usage():
	print """usage: {0} [-hr] [-s hostname] [-d duration]
 -h          : this (help) message   
 -r          : remove maintenance for specified host 
 -s hostname : hostname or IP 
                hostname must match what is in Zabbix.  Zabbix uses FQDN. OR IP required
 -d          : duration of maintenance in seconds.  leave blank to use default
                300  = 5 minutes
                1800 = half hour
                3600 = 1 hour
                10800 = 3 hour (default)
                etc.
 -s is required
 
example: {0} -s hostname -d 3600
example: {0} -s hostname -r""".format(sys.argv[0])



#### Main function
def main(argv):
	try:
		opts, args = getopt.getopt(argv, "hrs:d:",["help", "remove", "server=", "duration="])
	except getopt.GetoptError:
		print "Invalid Options supplied"
		usage()
		sys.exit(2)
	for opt, arg in opts:
		if opt in ("-h", "--help"):
			usage()
			sys.exit()	
		elif opt in ("-r", "--remove"):
			print "Call remove maint function"
		elif opt in ("-s", "--server"):
			hostname = arg
			print "Hostname, ", hostname
		elif opt in ("-d", "--duration"):
		        duration = arg
			print "Duration, ", duration
		else:
			usage()
			sys.exit()	

	
if __name__ == "__main__":
	main(sys.argv[1:])


