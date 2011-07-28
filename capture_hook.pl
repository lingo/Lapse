#!/usr/bin/perl
use Data::Dumper;

my ($action, $arg) = ($ENV{ACTION}, $ENV{ARGUMENT});
#print "Hook: Action =  $action;  ARGUMENT = $arg\n";

if ($action eq 'download') {
    print "Displaying preview";
    $cmdline = "eog '$arg' &";
	#system($cmdline);
}
