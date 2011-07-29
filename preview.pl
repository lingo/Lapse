#!/usr/bin/perl
package Preview;

use warnings;
use strict;

use File::Basename qw/dirname/;
use Glib qw(TRUE FALSE);
use Gnome2;
use Gtk2::GladeXML;
#use Gtk2::Ex::Simple::List;
#use Gtk2::Gdk::Keysyms;
#use Class::Struct;
use Carp;
use Data::Dumper;
#use YAML;
use IO::Socket;
use Gtk2::Helper;
use feature ':5.10';

our ($scaleX, $scaleY) = (640,480);

our $SOCKETFILE = dirname($0) . '/.preview_socket';

sub new { return bless({}, shift)->_init(@_); }

sub run {
	my $self = shift->new(@_);
	Gtk2->main;
}

sub _init {
    my $self = shift or confess("_init is NOT a class method -- should be called as \$obj->parsed_item");
	my ($image, $label) = @_;

	my $sock = $self->{_socket} = new IO::Socket::INET (
		LocalPort => 251177,
		Proto	=> 'udp'
	) or croak $!;

	$sock->autoflush();

    Gnome2::Program->init('Preview', '1.0');

    my $src = '/home/luke/code/timelapse/lapse_preview.glade';
    my $gui = $self->{_gui} = Gtk2::GladeXML->new($src);
	my $win = $gui->get_widget('window');

	$self->{_gui}->signal_autoconnect_from_package($self);

	use Gtk2::Ex::MPlayerEmbed;
	$self->{_imgwid} = $gui->get_widget('image');

	my $embed = Gtk2::Ex::MPlayerEmbed->new();
	$self->{_vidwid} = $embed;
	$embed->hide();
	my $box = $self->{_imgwid}->get_parent();
	$box->add($embed);
	$box->reorder_child($embed, 1);

	Gtk2::Helper->add_watch( $sock->fileno(), 'in', sub { my ($fd, $condition, $fh) = @_;  on_data_received($self, $fh); return 1; }, $sock);
	$gui->get_widget('status')->set_label($label // '');

	$win->show();
	if ( -f $image ) {
		if ($image =~ /\.mpg$/) {
			$self->show_video($image);
		} else {
			$self->show_image($image);
		}
	} else {
		$gui->get_widget('image')->set_from_stock('gtk-dialog-question', 'dialog');
	}

    return $self;
}

sub on_data_received {
	my ($self, $fh) = @_ or croak "No socket found in on_data_received";

	print "RECEIVED DATA: \n\t";
	my $txt;
	$fh->sysread($txt, 1024) or print "FAILED TO read : $!\n";
	return 1 unless $txt;

	print " -> $txt\n";
	my $gui = $self->{_gui};
	if ($txt =~ /--(?<command>\w+)(\s+(?<args>.*))?/s) {
		print Dumper(\%+);
		#print $+{args} . "\n";
		my $arg = $+{args};
		given ($+{command}) {
			when (/die/) { Gtk2->main_quit(); }
			when (/status/) { 
				my $txtItem = $gui->get_widget('status');
				$txtItem->set_label($arg);
			}
			default { print "Unknown command $_\n"; }
		}
	} else {
		if ( -f $txt ) {
			if ($txt =~ /\.mpg$/) {
				$self->show_video($txt);
			} else {
				$self->show_image($txt);
			}
		}
	}
	return 1;
}

sub show_video {
	my ($self, $vid) = @_ or croak;
	$self->{_imgwid}->hide();
	$self->{_imgwid}->set('visible', 0);
	$self->{_vidwid}->stop() if $self->{_vidwid}->get('state') eq 'playing';
	$self->{_vidwid}->play($vid);
	$self->{_vidwid}->show();
}

sub show_image {
	my ($self, $image) = @_ or croak;
	$self->{_vidwid}->hide();
	my $px = Gtk2::Gdk::Pixbuf->new_from_file_at_scale($image, $scaleX, $scaleY, 1);
	$self->{_imgwid}->set_from_pixbuf($px);
	$self->{_imgwid}->show();
}

sub copy_props {
	my $elt = shift;
	my %wanted = (
		#'app-paintable' => 1,
		'can-default' => 1,
		'can-focus' => 1,
		#'composite-child' => 1,
		'height-request' => 1,
		'sensitive' => 1,
		'style' => 1,
		'visible' => 1,
		'width-request' => 1,
		'xalign' => 1,
		'xpad' => 1,
		'yalign' => 1,
		'ypad' => 1
	);
	my @avail = $elt->list_properties();
	my %props = ();
	for my $p (@avail) {
		$props{$p->{name}} = $elt->get($p->{name});
	}
	print Dumper(\%props);
	return \%props;
}

#==-{ Signal handler methods }-================================================#

sub on_window_delete_event {
	my $self = shift or croak;
	$self->{_vidwid}->stop() if $self->{_vidwid}->get('state') eq 'playing';
    Gtk2->main_quit;
	unlink($SOCKETFILE);
}


1;

package main;
use Fcntl qw(:flock);
use IO::Socket;

my $sock = new IO::Socket::INET ( LocalPort => 251177, Proto => 'udp');
unless ($sock) { #flock(DATA, LOCK_EX|LOCK_NB)) {
	my $client = IO::Socket::INET->new(PeerPort => 251177, PeerAddr => '127.0.0.1', Proto => 'udp')
		or croak $!;
	$client->autoflush();
	print $client join(" ", @ARGV);
	$client->close;
	exit;
}
$sock->close();

# REAPER code from http://www.rocketaware.com/perl/perlipc/Signals.htm#Signals
sub REAPER {
	my $waitedpid = wait;
	# loathe sysV: it makes us not only reinstate
	# the handler, but place it after the wait
	$SIG{CHLD} = \&REAPER;
}
$SIG{CHLD} = \&REAPER;
# now do something that forks.

our $pid;
unless($pid = fork()) {
	use POSIX qw/setsid/;
	setsid();
	open STDIN, '</dev/null';
	open STDOUT, '>>/dev/null';
	open STDERR, '>>/dev/null';
	Preview->run(@ARGV);
}

__DATA__
