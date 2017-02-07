filename = 'file.txt'

with open(filename) as fn:
	content = fn.readlines()

print(content)
