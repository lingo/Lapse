#!/bin/bash
while true; do
	rm tmp.mpg
	ffmpeg -i test2/capt%04d.jpg -r 20 -target pal-dvd tmp.mpg
	pkill mplayer
	(mplayer -fps 20 tmp.mpg -loop 0 -fs &)  
	sleep 240 
done
