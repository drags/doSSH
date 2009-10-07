#!/usr/bin/perl -w
use Getopt::Std;
use POSIX;
use File::Basename;
use strict;

# declare vars
my (@servers, @exec_servers); 

# get user to connect as, filter for list
our ($opt_u, $opt_f);
getopts('u:f:');

# find list
my $lists_dir = dirname($0) . '/lists/';
my $list = $lists_dir . 'list.' . $ARGV[0];

if (! -e $list) {
	die ("List file $list does not exist!\n");
}

if (! -r $list) {
	die ("Unable to read from $list.\n");
}

# user, filter, command to run remotely
my $user = $opt_u?$opt_u:'root';
my $filter = $opt_f?$opt_f:'.';
my $cmd = $ARGV[1]?$ARGV[1]:'';

# read in the server list
open (SERVS, "<$list") or die "Sorry, can't find list $list.";
chomp(@servers = <SERVS>); 

# filter server list based on all filters
@exec_servers = FilterList(@servers, $filter);

# foreach server, run the command
foreach (@exec_servers) {
	my ($hostname, $ip) = split /,/;
	m/^#/ && next;
	print "================= $_ =================\n";
	system "ssh $user\@$ip \"$cmd\"";
	WIFSIGNALED($?) && &Oops;
	print "========================== fin =========================\n";
}


# filter out servrs wanted from list
sub FilterList {
	my(@wanted_servers, $filters, @filter_true);
	my(@serverlist) = @_;
	$filters = pop(@serverlist);
	my @filters = split /,/, $filters;

	foreach (@filters) {
		# greo resets $_ to current value, need to assign grep filter to other var
		# for insertion into grep call
		my $grepfil = $_;
		@filter_true = grep(/$grepfil/, @serverlist);
		push(@wanted_servers, @filter_true);
	}
	return @wanted_servers;
}

# fortune spitting on-abort routine
sub Oops {
	my (@fortunes, $frtn);
	open (FRTN, "fortunes.dat");
	chomp (@fortunes = <FRTN>);
	if (scalar @fortunes > 0) {
		$frtn = $fortunes[int rand ($#fortunes + 1)];
	} else {
		$frtn = "Shit...";
	}
	print "\n" . $frtn . "\n";
	close (FRTN);
	exit (0);
}

