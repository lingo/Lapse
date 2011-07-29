#!/bin/bash
HOOK="$1"

for I in {1..6000}; do
	echo "Capturing frame #$I/$TOTAL..."
	FN=$(perl -e "printf(qq{capt%04d.jpg}, $I);")
	echo "New file is in location /$FN on the camera"
	echo "Saving file as $FN"
	export ACTION=download
	export ARGUMENT=$FN
	$HOOK
	echo "Deleting file /$FN on the camera"
	echo "Deleting '$FN' from folder '/'..."
	echo "Sleeping for 3 second(s)..."
	sleep 3
done

