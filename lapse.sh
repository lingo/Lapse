#!/bin/bash

#CONFIG
##HOOK="capture_hook.pl"

#ARGUMENTS
name="$1"
itval="$2"
hook="$4"
frames="$3"

if [ "x$frames" = "x" ]; then
	frames=30
fi

if [ "x$itval" = "x" ]; then
    itval="15"
fi
if [ "x$name" = "x" ]; then
    echo "You must give a name";
	echo "Usage: $0 <name> <interval_in_s(15)> [<num_frames(30)>] [/path/to/hook_script]"
    exit 1
fi
if [ -d "$name" ]; then
    echo "$name/ exists already -- aborting"
    exit 1
fi

[ "x$hook" = "x" ] && hook="$HOOK"


#SETUP
mkdir $name
pushd $name

echo "Using interval $itval"
echo
echo
rm capt*.jpg > /dev/null 2>&1

#GPHOTO OPTIONS
[ "x$hook" != "x" ] && hookopt="--hook-script=$hook"


#CAPTURE
# Settings used for Canon EOS 400D
# $ gphoto2 --get-config imageformat
# 		Label: Image Format                                                            
# 		Type: RADIO
# 		Current: Small Normal JPEG
# 		Choice: 0 Large Fine JPEG
# 		Choice: 1 Large Normal JPEG
# 		Choice: 2 Medium Fine JPEG
# 		Choice: 3 Medium Normal JPEG
# 		Choice: 4 Small Fine JPEG
# 		Choice: 5 Small Normal JPEG
# 		Choice: 6 RAW
# 		Choice: 7 RAW + Large Fine JPEG
#
# $ gphoto2 --get-config capturetarget
#		Label: Capture Target                                                          
#		Type: RADIO
#		Current: Internal RAM
#		Choice: 0 Internal RAM
#		Choice: 1 Memory card


gphoto2 -F$frames --set-config imageformat=5 --set-config capturetarget=0 --set-config capture=on -I "$itval" --capture-image-and-download $hookopt

#ENCODE
[ -f capt0000.jpg ] && ffmpeg -r 20 -i capt%04d.jpg -target pal-dvd cap.mpg


#PLAY
[ -f cap.mpg ] && mplayer -fps 14 -loop 0 cap.mpg
mv cap.mpg "$name.mpg" > /dev/null 2>&1


#CLEANUP
popd
rmdir "$name" >/dev/null 2>&1
