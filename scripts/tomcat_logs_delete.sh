find /paytm*/apache-tomcat-7.0.47/logs/ -mtime +15 -name "*.log" -exec rm -f {} \;
find /paytm*/apache-tomcat-7.0.47/logs/ -mtime +15 -name "*.txt" -exec rm -f {} \;
