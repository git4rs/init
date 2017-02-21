#!/usr/bin/env python
## Author :- Rohit Sharma
## Date:- 09-Feb-2017
## Purpose :- To put/remove maintenance on zabbix hosts 
from optparse import OptionParser
import sys
import pdb

parser = OptionParser()
parser.add_option("-f", "--file", dest="filename",
                  help="write report to FILE", metavar="FILE")
parser.add_option("-q", "--quiet",
                  action="store_false", dest="verbose", default=True,
                  help="don't print status messages to stdout")
#parser.add_option("-f", "--file", dest="filename", help="write report to FILE", metavar="FILE")
#parser.add_option("-f", "--file", dest="filename", help="write report to FILE", metavar="FILE")

#options, args = parser.parse_args()
#print 'Help:', options.h

#use JSON;

#url = "http://172.21.20.39/zabbix/api_jsonrpc.php" # change <zabbix server> to your zabbix server
#apiuser = "maintenance" # API User's Username
#apipassword = 'pT47_*Ac7J' # API User's password
#hostid, maintenanceid = '',''
#scriptName=sys.argv[0]

#print (len(sys.argv))

def main():
	print "Hello"

if __name__ == "__main__":
	main()
