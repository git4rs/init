#!/usr/bin/env python3
fahrenheit = 0.0
print ("Fahrenheit to Celcius")
while fahrenheit <= 250:
	celcius = ( fahrenheit - 32.0 ) / 1.8
	print ("Fehrenheit %5.1f => Celcius %7.2f" % (fahrenheit, celcius))
	fahrenheit = fahrenheit + 25.0
