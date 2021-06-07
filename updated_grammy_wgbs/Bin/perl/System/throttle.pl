#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $max_processes_user = get_arg("max_u", "", \%args);
my $min_processes_user = get_arg("min_u", "", \%args);
my $min_processes_total = get_arg("min_t", "", \%args);
my $local = get_arg("local", 0, \%args);
my $reset = get_arg("reset", 0, \%args);
my $kill = get_arg("kill", "", \%args);
my $deadnodes = get_arg("dead", "", \%args);

my $filename = ($local or $kill) ? ".qppl" : "$ENV{HOME}/.qppl";

if ($reset)
{
	unlink $filename;
	print STDERR "Removed $filename.\n";
}
else
{
	if ($max_processes_user . $min_processes_user . $min_processes_total eq "" and ($kill eq ""))
	{
	  print STDOUT <DATA>;
	  exit;
	}

	my $kill_str = $kill ? "KILL" : "RUN";
	
	my $cmd = "echo \"$max_processes_user\t$min_processes_user\t$min_processes_total\t$kill_str\t$deadnodes\" > $filename";	
	system ($cmd);
	print STDERR "Created $filename.\n";
}

#-----------------------------------------------------------------------------------------
# --help 
#-----------------------------------------------------------------------------------------

__DATA__

 Syntax:         throttle.pl
 
 Description:    Create the .qppl file containing the updated process limits which are
 				 read by qp.pl

 				 
 Flags:

  -min_u <int>:  The minimum number of jobs in the queue that the user allows himself to send without
                 considering others... (default: 1 job)
  -max_u <int>:  The maximum number of jobs in the queue allowed for the user name. (default = 40 jobs)
  -min_t <int>:  The minimum number of jobs must be left available for all other users. (default = 6 jobs)

  -local      :  Create the .qppl locally (rather than in the users home directory) so that it only
                 affects qp.pl instances running in the current directory

  -reset      :  Reset throttle by removing .qppl file. Note that this does not return the
                 original settings to running qp.pl instances.
                 
  -kill       :  Kill all processes of that specifc (if used with -local) or all qp.pl instances
                 and quit qp.pl.

  -dead       :  Comma-separated list of dead nodes. Any process running on those nodes will be
                 rerun even if pinging the node returns fine.
