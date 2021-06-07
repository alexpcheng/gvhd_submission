#!/usr/bin/perl

use strict;
use File::Copy;
use POSIX qw(ceil floor);

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $t_sleep = get_arg("t", 5, \%args);
my $totalLines = get_arg("lines", 0, \%args);
my $file_that_matters = get_arg("matters", "", \%args);

my $start_time = time;
my $start_lines = -1;
my $last_time = 0;
my $last_lines = -1;
my $current_time = 0;

my %jobmachine;

while (1) 
{
	my $i = 1;
	my $total_count = 0;
	my $stats = sprintf (" %-5s   %-30s %-7s\n", "Node", "File", "Lines");
	
	my @jobs=(`qstat`);
	
	for my $j (@jobs)
	{
		my @jobdata = split (" ", $j);
		$jobdata[7]=~/\@genie(\d+)/gm;
		$jobmachine{$jobdata[0]}=$1;
	}
	
	# my @jobnumber=(`qstat`=~/^\s*(\d+)/gm);
	
	while (-d $i)
	{
		my @jobfiles = <$i/_*.o*>;
		$jobfiles[0]=~/\.o(\d+)/gm;
		my $curjobnum = $1;

		opendir(DIR, "$i/Output") or die "Can't open directory $i/Output";
		my @files = readdir(DIR);
		for my $file (@files)
		{
			$file eq '.'  and next;
			$file eq '..' and next;
			
			if ( ($file_that_matters ne "") and ($file ne $file_that_matters) )
			{
				next;
			}
			
			my $count = `wc -l < $i/Output/$file`;
			die "wc failed: $?" if $?;
			chomp ($count);
			$total_count += $count;
			$stats .= sprintf ("\n %02d      %-30s %-7s", "$jobmachine{$curjobnum}", "$i/Output/$file", "$count");
		}
		closedir(DIR);
		$i++;
	}
	
	$stats .= "\n\nTotal $total_count lines";
	
	if (($totalLines > 0) and ($totalLines >= $total_count))
	{
		$stats .= " out of $totalLines (" . floor (100 * $total_count / $totalLines) . "%)";
	}
	
	$stats .= ".\n\n";
	
	$current_time = time;
	
	if ($start_lines == -1)
	{
		$start_lines = $total_count;
		$last_lines = $total_count;
		$last_time = $current_time;
	}
	else
	{
		my $cur_lps = format_number(($total_count - $last_lines) / ($current_time - $last_time), 2); 
		my $avg_lps = format_number(($total_count - $start_lines) / ($current_time - $start_time), 2); 

		my $cur_eta = "";
		my $avg_eta = "";
		
		if ($totalLines > $total_count)
		{
			if ($cur_lps > 0)
			{
				my $cur_sec_left = ($totalLines - $total_count) / $cur_lps;			
				$cur_eta = "ETA: " . &seconds2string ($cur_sec_left);
			}
			
			if ($avg_lps > 0)
			{
				my $avg_sec_left = ($totalLines - $total_count) / $avg_lps;
				$avg_eta = "ETA: " . &seconds2string ($avg_sec_left);
			}
		}
		
		$stats .= "Currently: $cur_lps lines per second. \t$cur_eta\n";
		$stats .= "Average:   $avg_lps lines per second. \t$avg_eta\n";


	}
	
	$last_time = $current_time;
	$last_lines = $total_count;
	
	system("clear");
	print $stats;
	
	for (my $sleeper = 0; $sleeper < $t_sleep; $sleeper++)
	{
		print ".";
		sleep 1;
	}
}

################################################################################

sub seconds2string {

	my $seconds = $_[0];
	my $result = "";
	
	my $days = floor ($seconds / 86400);
	$seconds -= ($days * 86400);
	
	#print "days = $days; ";
	
	my $hours = floor ($seconds / 3600);
	$seconds -= ($hours * 3600);
	
	#print "hours = $hours; ";
	
	my $minutes = floor ($seconds / 60);
	$seconds -= ($minutes * 60);
	
	#print "minutes = $minutes; ";
	
	if ($days > 0)
	{
		$result = "$days day" . ($days > 1 ? "s" : "") . ", ";
	}
	
	$result .= sprintf ("%d:%02d:%02d", $hours, $minutes, $seconds);
	return $result;
}


__DATA__

parallel_stats.pl <file>

	When run in the /Parallel directory, this script collectes statistics about
	the size of the output files in each of the directories under it.
	
	-t <seconds>:   Time between every two calls (default: 5. Use 0 for single run).
	
	
   