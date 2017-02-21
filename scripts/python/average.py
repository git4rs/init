#!/usr/bin/env python3
N = 10
sum = 0
count = 0
while count < N:
	number = float(input("Enter number: "))
	sum = sum + number
	count = count + 1
average = float(sum)/N
print "Average of %d numbers is: %f" % (N, average)
