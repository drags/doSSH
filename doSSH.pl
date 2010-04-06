#!/usr/bin/perl -w
use Getopt::Std;
use POSIX;
use File::Basename;
use strict;

my (@servers, @exec_servers); 

# options: user, filter, save output to
my %options;
getopts('u:f:s:',\%options);

unless (@ARGV>0) {
	&Usage;
	exit;
}
# find list
my $lists_dir = dirname($0) . '/lists/';
my $list = $lists_dir . 'list.' . $ARGV[0];

if (! -e $list) {
	die ("List file $list does not exist!\n");
}

#filter defaults to , as drop-thru regex
my $user = $options{'u'}?$options{'u'}:'root';
my $filter = $options{'f'}?$options{'f'}:'.';
my $cmd = $ARGV[1]?$ARGV[1]:'';
my $outputfile = $options{'s'}?$options{'s'}:undef;

# read in the server list
open (SERVS, "<$list") or die "Unable to open $list.";
chomp(@servers = <SERVS>); 

# filter server list based on all filters
@exec_servers = FilterList(@servers, $filter);

# foreach server, run the command
foreach (@exec_servers) {
	m/^#/ && next;
	my ($hostname, $ip) = split /,/;

	if ($outputfile) {
		my $fn = dirname($0) . '/output/' . $outputfile . "." . $hostname;
		open SRVOUT, '>', $fn or die "Unable to open output file $fn\n";
	}

	print "================= $_ =================\n";

	my $out = `ssh $user\@$ip \"$cmd\"`;
	print $out;
	WIFSIGNALED($?) && &Oops;

	if ($outputfile) {
		print SRVOUT $out;
		close SRVOUT;
	}

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

sub Usage {
	print <<USE;
Usage: $0 [-u user] [-f filter] [-s file prefix] list-name [cmd]
	-u user: user to connect as
	-f tilter: filter server list for servers only matching /filter/ (regex). Commas indicate multiple filters.
	-s file prefix: will save output from command to output/file-prefix.hostname
	list-name: suffix of list in lists/ e.g. app for list.app
	cmd: command to run. Optional; no command given causes doSSH to connect to each host in a row, same as "ssh host"
USE

}
