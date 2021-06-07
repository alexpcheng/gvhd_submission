#!/usr/bin/perl

use strict;
use File::Basename;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $DEBUG = 1;

my %args = load_args(\@ARGV);

my $user = `whoami`;
chomp($user);

my $hostn = `hostname`;
chomp ($hostn);

$user .= "@" . $hostn;

my $coop_dir = get_arg("dir", "~/Genie/Coop", \%args);
my $num_of_seconds_to_sleep = get_arg("sl", "10", \%args);

my $running_time = 0;
my $stopped = 0;

logit ("STARTING");

while (!$stopped)
{

	my @files_found = <$coop_dir/*>;
	my $to_execute = "";
	
	foreach my $fname (@files_found)
	{
		my $pure_fn = fileparse ($fname);

		if ($pure_fn eq "quitall")
		{
			logit ("QUITING");
			exit;
		}
		
		if (($to_execute eq "") && (substr ($pure_fn, 0, 3) eq "job"))
		{
			open INPUT, "<$fname";

			my @lines = <INPUT>;
			close INPUT;
			
			system ("mv $coop_dir/$pure_fn $coop_dir/running_$pure_fn");
			
			$to_execute = $lines[0];
			chomp ($to_execute);

			logit ("starting to execute $pure_fn");

			system ("$to_execute");

			logit ("finished executing $pure_fn");

			system ("mv $coop_dir/running_$pure_fn $coop_dir/executed_$pure_fn");
		}
	}
	
	sleep ($num_of_seconds_to_sleep);

	$running_time += $num_of_seconds_to_sleep;

	if ($running_time >= 60)
	{
		logit ("waiting");
		$running_time = 0;
	}
}

sub logit {

	my $message = $_;

	system ("echo `date` $user $message >> $coop_dir/status.txt");
}

#-----------------------------------------------------------------------------------------
# --help 
#-----------------------------------------------------------------------------------------

__DATA__

 Syntax:         coop.pl
 