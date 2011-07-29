#!/usr/bin/perl
use Data::Dumper;
use Time::Duration;

my ($action, $arg) = ($ENV{ACTION}, $ENV{ARGUMENT});
#print "Hook: Action =  $action;  ARGUMENT = $arg\n";

my $path = $ENV{LAPSE_SOURCE_DIR};
my $cmd = $path . '/preview.pl';

return unless ($action eq 'download');

my $N = $arg;
$N =~ s/.*(\d+)\.jpg/$1/;

my $pc = $N / $ENV{LAPSE_NUMFRAMES};
my $now = time();
my $taken = $now - $ENV{LAPSE_STARTTIME};
my $trem = $taken / $pc;

my $status = sprintf("Current frame: %12s  %3.2f%% done, %s remaining (%s so far)",
	$arg, $pc * 100.0, duration($trem), duration($taken));

system("$cmd $arg &") == 0 or croak $!;
system($cmd, '-status', $status) == 0 or croak $!;
