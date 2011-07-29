#!/usr/bin/perl
use warnings;
use strict;
use Time::Duration;
use Data::Dumper;
use Carp;
use Getopt::Long;
use File::Copy qw/move/;
use Time::Duration;

sub usage {
	print "USAGE: $0 <NAME> -I <interval> [-F <numframes> | -D <duration>] [--hookscript=/path/to/script]\n";
	exit(1);
}

our $SOURCE_DIR = '~/timelapse';
{
	use Cwd qw/realpath/;
	use File::Basename;
	$SOURCE_DIR = realpath(dirname($0));
	$ENV{LAPSE_SOURCE_DIR} = $SOURCE_DIR;
}

our %opt;
our ($interval, $numframes, $duration, $fps); # Commonly used options
$fps = 20;

GetOptions(\%opt,
	'sim',
	'hookscript|H=s', 'interval|I=s' => \$interval,
	'numframes|F=i' => \$numframes, 'duration|D=s' => \$duration,
	'fps=i' => \$fps
) or usage();

if (@ARGV < 1) {
	usage();
} 
#CONFIG
##HOOK="capture_hook.pl"

#ARGUMENTS
my $Name = $ARGV[0];

if ( -d $Name ) {
	print "$Name/ already exists, won't ovewrite.  Giving up.\n";
	exit(1);
}

for my $var (\$duration, \$interval) {
	if ($$var =~ /(\d+)\s*(s|m|h)/) {
		$$var = $1;
		$$var = $$var * 60 if ($2 eq 'm');
		$$var = $$var * 360 if ($2 eq 'h');
	}
}

if ($duration) {
	if ($numframes) { print "Ignoring specified numframes in favour of duration argument\n"; }
	$numframes = $duration * $fps;
} else {
	unless($interval && $numframes) {
		# Nothing is set, default to 15/30
		$interval = 15; 
		$numframes = 30;
	}
}
$duration ||= $numframes * $fps;

print "Taking photos every $interval seconds\n\n";

my $howlong = ($numframes * $interval);
printf("Final video duration:\t\t%s\nTime to create:\t\t\t%s\n",
	duration($duration), duration($howlong));
print "\nYou can press Ctrl+C now to cancel (waiting 5s)\n";
sleep 5 unless $opt{sim};

#SETUP
mkdir($Name) or croak($!) unless $opt{sim};
chdir($Name) or croak($!) unless $opt{sim};

# Set default hook script if not overridden from CLI args.
$opt{hookscript} //= $SOURCE_DIR . '/capture_hook.pl';

# Set environment vars for child scripts to use.
$ENV{LAPSE_INTERVAL} = $interval;
$ENV{LAPSE_NUMFRAMES} = $numframes;
$ENV{LAPSE_DURATION} = $duration;
$ENV{LAPSE_FPS} = $fps;
$ENV{LAPSE_STARTTIME} = time();

#CAPTURE
# Settings used for Canon EOS 400D
# $ gphoto2 --get-config imageformat
# 		Label: Image Format                                                            
# 		Type: RADIO
# 		* Current: Small Normal JPEG *
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
#		* Current: Internal RAM *
#		Choice: 0 Internal RAM
#		Choice: 1 Memory card
if ($opt{sim}) {
	system('./camsim.sh', $opt{hookscript});
} else {
	system('gphoto2',
		"-F$numframes",
		"-I$interval",
		($opt{hookscript} ? "--hook-script=$opt{hookscript}" : ''),
		## NOTE: Camera-specific settings here ##
		qw{
			--set-config imageformat=5
			--set-config capturetarget=0
			--set-config capture=on
			--capture-image-and-download
		}
	);
}

if ($opt{sim}) {
	exit 0;
}

#ENCODE
if ( -f 'capt0000.jpg' ) {
	system('ffmpeg', '-r', $fps, '-i', 'capt%04d.jpg', '-target', 'pal-dvd', 'cap.mpg');
} else {
	croak "Failed to save images for some reason? $!";
}


#PLAY
if ( -f 'cap.mpg' ) {
	system('mplayer', 'cap.mpg', '-loop', '0');
	move('cap.mpg', "$Name.mpg");
}
