# Lapse (especially in documentation) #

## Author ##
Luke Hudson <lukeletters@gmail.com>

## About ##

Badly organised but hpefully useful scripts to make timelapse films from Canon EOS (Especially 400D).

lapse.pl is the main script:

## Usage ##

USAGE: ./lapse.pl <NAME> -I <interval> [-F <numframes> | -D <duration>] [--hookscript=/path/to/script]

-I is interval, either in seconds or with 'm' suffix to denote minutes.
Eg.  '10m' means 1 photo every 10 min, and '1' means 1 every second.

-F Number of frames to capture.   You can omit this and use '-D' to specify the final video duration instead if you like.

-D Duration of final video, specified using same format as -I

--hookscript  This defaults to ./capture_hook.pl which attemps to show a preview of last image taken, using ./preview.pl
See the gphoto2 documentation for more info on hookscripts

--fps  Frames per second of output video.  Defaults to 20 (slightly slower than normal film at 24)


--sim Run simulation, don't call gphoto2.  This uses ./camsim.sh



## Requirements ##

Programs:
	- sudo aptitude install gphoto2 ffmpeg # Core requirements

Perl libraries:
	- sudo aptitude install libtime-duration-perl 

Optional (if you use the defaults, these are required):
	- sudo aptitude install libgtk2-perl libgtk2-gladexml-perl # For preview.pl, as below
	- cpan Gtk2::Ex::MPlayerEmbed; # For preview.pl, not needed if you omit, or use custom, hookscript
	- sudo aptitude install mplayer # For movie preview functions, still somewhat Work in progress here.
