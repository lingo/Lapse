#!/usr/bin/perl
use Data::Dumper;

my ($action, $arg) = ($ENV{ACTION}, $ENV{ARGUMENT});
#print "Hook: Action =  $action;  ARGUMENT = $arg\n";

my $cmd = '/home/luke/code/timelapse/preview.pl';

if ($action eq 'download') {
	system("$cmd $arg &") == 0 or croak $!;
	system("$cmd --status $arg") == 0 or croak $!;
}
