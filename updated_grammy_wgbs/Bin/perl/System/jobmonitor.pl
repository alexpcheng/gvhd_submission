#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my %args = load_args(\@ARGV);

my $delay = get_arg("d", 1, \%args);
my $beeps = get_arg("b", 0, \%args);
my $beeps_last = get_arg("bl", 0, \%args);
my $mail = get_arg("m", "", \%args);
my $help = get_arg("-help", 0, \%args);
my $ping = get_arg("ping", 0, \%args);

$beeps_last = $beeps_last - $beeps;
if ($beeps_last < 0) { $beeps_last = 0; }

if($help)
{
    print STDOUT <DATA>;
    exit(0);
}

my %jobs;
my %jobstart;
my $sleep=1;
my $user=$ENV{USER};

my @q=(`qstat \| grep $user`=~/^\s*(\d+)/gm);

for my $j (@q){
    $jobs{$j}=1;
    $jobstart{$j}=1;
}

while (getppid>1){
    sleep $delay;
    @q=(`qstat \| grep $ENV{USER}`=~/^\s*(\d+)/gm);

    my %newjobs;
    for my $j (@q)
    {
		$newjobs{$j}=1;
		if (!$jobstart{$j}) { $jobstart{$j}=time; }
    }

    for my $j (keys %jobs)
    {
		if (!$newjobs{$j})
		{
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
			printf "Job $j completed at %02d:%02d:%02d. ",$hour,$min,$sec;
			if ($jobstart{$j} > 1)
			{
				my $seconds = time - $jobstart{$j};
				my @parts = gmtime($seconds);
				
				print "Execution time: ";
				if (@parts[7]) { print @parts[7] . "d "; }
				printf "%02d:%02d:%02d. ", @parts[2,1,0];
			}
			my $remaining = keys (%newjobs);
			if ($remaining)
			{
				print "$remaining other job" . ($remaining > 1 ? "s" : "") . " running.";
			}
			else
			{
				print "No other jobs running.";
				print "\a" x $beeps_last . "\n";
			}
			
			print "\a" x $beeps . "\n";
			if ($mail){
			  system("sendmail.pl -t $user" . "\@stanford.edu -s 'CLUSTER MESSAGE: Job $j has finished.' -m 'This message is generated automatically.'")
			}
		}
    }
    %jobs=%newjobs;
}


 
__DATA__

jobmonitor.pl 

    Job monitor for reporting when your cluster jobs finish running. Should be
    run in the background (jobmonitor.pl &).

    -d <num>:    Check job status every <num> seconds. Jobs that finish faster
                 than <num> seconds will not be reported. (default: 1)

    -b <num>:    Number of beeps to sound when job is done. (default: 0)
    -bl <num>:   Number of beeps to sound when LAST job is done. (default: 0)

    -m:          Send yourself email for each job finished.
