#!/usr/bin/perl

use strict;
use Time::HiRes;
use Time::HiRes qw ( setitimer ITIMER_VIRTUAL time gettimeofday tv_interval );

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my %args = load_args(\@ARGV);

my $delay = get_arg("d", 10, \%args);
my $cmd = get_arg("c", "ls ~/Genie/Develop", \%args);
my $mail = get_arg("m", "", \%args);
my $help = get_arg("-help", 0, \%args);

if($help)
{
    print STDOUT <DATA>;
    exit(0);
}


while (getppid>1){

	my $t0 = [gettimeofday];
	my $result = `$cmd`;
  
	my $elapsed = tv_interval ($t0);	# equivalent code

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	printf "%4d-%02d-%02d %02d:%02d:%02d\t", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	print $elapsed, "\n";

	sleep ($delay);
}


 
__DATA__

iotimer.pl 

	Utility to time the I/O response time by executing an ls command to
	a specific directory and timing the response time.
	
    -d <num>:    Check I/O response every <num> seconds (default: 10)
    -c <str>:    Command to execute (default: "ls ~/Genie/Develop")
