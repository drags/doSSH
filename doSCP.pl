#!/usr/bin/perl -w
use Getopt::Std;
use File::Basename;
use strict;

# declare vars
my (@servers, @exec_servers); 

# get user to connect as, filter for list
our ($opt_u, $opt_f);
getopts('u:f:');

# user to send to, file, location, server filter
my $user = $opt_u?$opt_u:'root';
my $file = $ARGV[1];
my $location = exists($ARGV[2])?$ARGV[2]:'';
my $filter = $opt_f?$opt_f:'.';

# find list
my $lists_dir = dirname($0) . '/lists/';
my $list = $lists_dir . 'list.' . $ARGV[0];

if (! -e $list) {
	die ("List file $list does not exist!\n");
}

if (! -r $list) {
	die ("Unable to read from $list.\n");
}

# grab server list into array
open (SERVS, "<$list") or die "Sorry, can't find list $list.";
chomp (@servers = <SERVS>); 

# filter server list based on all filters
@exec_servers = FilterList(@servers, $filter);

# send it on up
foreach (@exec_servers) {
	my ($hostname,$ip) = split /,/;
	m/^#/ && next;
	print "Sending $file to $hostname...\n";
	system "scp $file $user\@$ip:$location";
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

