#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $DEBUG = 1;
my @dead_nodes;
my $deadnodes="";

my %args = load_args(\@ARGV);

my $user = get_arg("u", `whoami`, \%args);
chomp($user);

my $min_processes_user = get_arg("min_u", "1", \%args);
my $max_processes_user = get_arg("max_u", "40", \%args);
my $min_processes_total = get_arg("min_t", "6", \%args);
my $num_of_seconds_to_sleep = get_arg("sl", "10", \%args);
my $file = get_arg("f", "", \%args);
my $report_mode = get_arg("report", 0, \%args);
my $manual = get_arg("manual", 0, \%args);
my $no_quit = get_arg("no_quit", 0, \%args);
my $wait_for_finish = get_arg("finish", 0, \%args);
my $rerun = get_arg("rerun", 0, \%args);
my $ping = get_arg("ping", 0, \%args);
my $eqw = get_arg("eqw", 0, \%args);
my $debug = get_arg("debug", 0, \%args);
my $queue_name = get_arg("q", "", \%args);
my $memory_reserve = get_arg("l", "", \%args);
my $queue_name_in_file = get_arg("qf", "", \%args);
my $silent = get_arg("silent", 0, \%args);

if ($rerun and $manual) { die "ERROR: -rerun does not currently work with -manual\n" }
if ($report_mode) { print "Timestamp\t#\tWait\tCommand\n"; }

my $command;
my %joblist;

my $jobs_run = 0;


#print STDOUT "qp.pl: file: $file";

if ($file eq "" || $file == 1)
{
	$command = $ARGV[0];
	$command =~ s/\s*-q \S\S*//g;

	if (length($command) < 1) 
	{
	  print STDOUT "Error: qp.pl expects the first argument to be a string of the command to run.\n\n";
	  print STDOUT <DATA>;
	  exit;
	}
	
	my $jobid = &politeRun ($command);
	if ($report_mode)
	{
		logit ("\t$jobid\t$command");
	}
}
elsif (not $no_quit)
{
	my $file_ref;
	my $counter = 0;
	open(FILE, $file) or die ("Could not open file (1):'$file'.\n");
	$file_ref = \*FILE;
	
	while(<$file_ref>)
	{
		$counter++;
		chomp;
		$command = $_;
		
		my $jobid = &politeRun ($command);
		if ($report_mode)
		{
			logit ("$counter\t$jobid\t$command");
		}
	}
	
	close FILE;
}
else
{
  	my $file_ref;
	my $counter = 0;
	open(FILE, $file) or die ("Could not open file (2):'$file'.\n");
	$command = <FILE>;
	chomp $command;
	close(FILE);
	
	while($command ne "Q")
	{
		if ($command ne ""){
		  $counter++;
		  my $jobid = &politeRun ($command);
		  if ($report_mode)
		  {
		    logit ("$counter\t$jobid\t$command");
		  }
		}
		else {
		  sleep ($num_of_seconds_to_sleep);
		}

		open(FILE, $file) or die ("Could not open file (3):'$file'.\n");
		for (my $i = 0; $i < $counter; $i++) {
		  <FILE>;
		}
		$command = <FILE>;
		chomp $command;
		while ((not eof(FILE)) and ($command eq "")) { # ignore empty lines
		  $counter++;
		  $command = <FILE>;
		}
		close(FILE);
	}
	
	close FILE;
}

################################################################################

sub politeRun {

	my ($command) = shift ;

	my $success = 0;
	my $waited = 0;
	my $jobid = "none";

	my $tmp_u;
	my $tmp_t;
	my $tmp_wt;

	my @tmp_wtr;
	my $total_working_nodes;
	my $max_processes_total;
	
	my $current_num_processes_user;
	my $current_num_processes_total;
	
	while (!$success)
	{
			
		update_settings_from_file(".qppl");
  		update_settings_from_file("$ENV{HOME}/.qppl");
 	 
		my $tmp_u = `qstat -u \\* | grep $user | wc -l`;
		my $tmp_t = `qstat -u \\* | wc -l`;
		my $tmp_wt = `qstat -g c | body.pl 3 -1 | sed -r 's/[\ ]+/\t/g' | cut.pl -f 6,8 | compute_column_stats.pl -skip 0 -skipc 0 -s | cut -f 2-`;
		chomp($tmp_wt);
		my @tmp_wtr = split(/\t/,$tmp_wt);
		my $total_working_nodes = $tmp_wtr[0] - $tmp_wtr[1];
		my $max_processes_total  = $total_working_nodes - $min_processes_total;
		
		#my $current_num_processes_user = ($tmp_u > 2) ? ($tmp_u - 2) : 0;
		my $current_num_processes_user = $tmp_u;
		my $current_num_processes_total = ($tmp_t > 2) ? ($tmp_t - 2) : 0;
		
		
		# print STDERR "User: $current_num_processes_user; Total: $current_num_processes_total ...\n";
		
		if ((($current_num_processes_user < $max_processes_user) 
			 and 
			 ($current_num_processes_total < $max_processes_total)) 
			or 
			($current_num_processes_user < $min_processes_user) )
	
		{
			my $cmd_to_run;
			
			my $rand_id=int(rand(100000000));
	
			if ($manual)
			{
				$cmd_to_run = "$command";
				if ($rerun){
				  /^(\S+)\s+(.*)/;
				  $cmd_to_run = "$1 \"$2;touch tmp_qppl_$rand_id\"";
				}
			}
			else
			{
			  if ($queue_name_in_file){
			    if($command=~/^\s*-q (\S+) (.*)$/){
			      $queue_name=$1;
			      $command=$2;
			    }
			  }
				$cmd_to_run = "q.pl " . ($silent ? " -silent_qpl " : ""). ($queue_name ? " -queue_qpl $queue_name " : ""). ($memory_reserve ? "-l_qpl $memory_reserve " : ""). "\"$command\" ";

			  if (! $silent) { print STDERR $cmd_to_run;}

				if ($rerun){
				  $cmd_to_run = "q.pl " . ($silent ? " -silent_qpl " : ""). ($queue_name ? " -queue_qpl $queue_name " : ""). ($memory_reserve ? "-l_qpl $memory_reserve " : ""). "\"$command;touch tmp_qppl_$rand_id\"";
				}
			}
				
			if ($rerun){
			  unlink "tmp_qppl_".$rand_id;
			}
			
			
			
# 			print STDERR "\ncurrent_num_processes_user:$current_num_processes_user\t";
# 			print STDERR "max_processes_user:$max_processes_user\t";
# 			print STDERR "current_num_processes_total:$current_num_processes_total\t";
# 			print STDERR "max_processes_total:$max_processes_total\t";
# 			print STDERR "current_num_processes_total:$current_num_processes_total\t";
# 			print STDERR "current_num_processes_user:$current_num_processes_user\t";
# 			print STDERR "min_processes_user:$min_processes_user\n";

			
			my $run_output=`$cmd_to_run`;
			$run_output=~/^Your job (\d+)/;
			$joblist{$1}{id}=$rand_id;
			$joblist{$1}{command}=$command;
			$jobid = $1;
			$success = 1;
			$jobs_run++;
			
		}
		else
		{
			sleep ($num_of_seconds_to_sleep);
			$waited+=$num_of_seconds_to_sleep;
		}
	}
	
	return ($jobid);
	
}

# wait for jobs to finish

my $finished=0;
my $counter = 0;
while($wait_for_finish and scalar(keys %joblist)>0){
  sleep ($num_of_seconds_to_sleep);
  $counter += $num_of_seconds_to_sleep;

  my $qstat_output=`qstat -u $user | tail -n +3 | grep -v -P '\sd[tr]\s'`;

#  if ($debug)
#  {
#  	logit ("qstat output:\n$qstat_output");
#  }
  
  my %line_hash;
  my @lines=split /\n/,$qstat_output;
  for (@lines){
#    if(/^\s*(\d+).+\@(.*?)\..+/){
    if(/^\s*(\d+)\s+/){
      my $curjobid = $1;
      if (/\s*\@(.*?)\..+/)
      {
      	$line_hash{$curjobid}=$1;
      }
      else
      {
      	$line_hash{$curjobid}="unassigned";
	  }        
    }
  }
  
#  logit ("Line hash elements are: " . join (",", keys %line_hash));
#  for my $aa (keys %line_hash)
#  {
#  	logit ("$aa runs on $line_hash{$aa}");
#  }
  
  my @tmp=keys %joblist;

  update_settings_from_file(".qppl");
  update_settings_from_file("~/.qppl");
  
  if ($counter >= 150)
  {
 
  	if ($debug)
  	{
		my $str = join(",", @tmp);
		logit ("Waiting for: $str");
	}
	
	
	if ($eqw)
	{
		my $eqw_result = `qstat -u $user | tail -n +3 | grep Eqw | sed -e 's/^ *//' | cut -f 1 -d " "`;

		if ($eqw_result ne "")
		{
			$eqw_result =~ s/\n/ /g;
			
			logit ("Found Eqw jobs. Executing: qmod -cj $eqw_result");
			
			my $qmod_result = `qmod -cj $eqw_result`;
			logit ("Result was: $qmod_result");
		}
	}
	
	
	
	my $deleted_jobs = 0;
	
	if ($ping)
	{
		my %nodes;
		
		for my $i (@tmp)
		{
			if (exists $line_hash{$i})
			{
				$nodes{$line_hash{$i}} .= "$i ";
			}
		}
		
		if (exists $nodes{"unassigned"})
		{
			delete $nodes{"unassigned"};
		}
		
		my @active_nodes = keys %nodes;
		
		logit ("Will ping: " . join (",", @active_nodes) );
		
		for my $anode (@active_nodes)
		{
			
			my $ping_result = `ping $anode -c 1 -w 2`;
			
			$ping_result =~ / (\d+)\% packet loss/;
			my $packet_loss = $1;
			
			logit ("Pinging $anode. Running on it are jobs: " . $nodes{$anode} . " $packet_loss \% packet loss");
			
			if (($packet_loss > 0) or ((grep {$_ eq $anode} @dead_nodes)) )
			{
				logit ("Removing jobs: $nodes{$anode}");
				my $qdel_result = `qdel $nodes{$anode}`;
				logit ("qdel result: $qdel_result");
				
				my @jobs_to_remove = split (" ", $nodes{$anode});
				for my $job_to_remove (@jobs_to_remove)
				{
				
					my $jobid = &politeRun ($joblist{$job_to_remove}{command});

					print "After rerun: " . join (",", keys %joblist) . "\n";
					if ($report_mode)
					{
						logit ("rerun\t$jobid\t$joblist{$jobid}{command}");
					}
					
					delete $joblist{$job_to_remove};
					
					$deleted_jobs = 1;
				}
			}
		}
		
	}
	
	$counter = 0;
	if ($deleted_jobs)
	{
		next;
	}
  }


  for my $i (@tmp){
  	if (not exists $line_hash{$i}){
    	if ($rerun){
			if (-e "tmp_qppl_".$joblist{$i}{id}){
				unlink "tmp_qppl_".$joblist{$i}{id};
			}
			else{
	  			my $jobid = &politeRun ($joblist{$i}{command});
	  			if ($report_mode)
	    		{
					logit ("rerun\t$jobid\t$joblist{$i}{command}");
			    }
			}
      	}
      	
      	logit ("Job $i not found on qstat -- assuming it ended.");
      	
      	delete $joblist{$i};
    }
  }
}


sub logit
{
	my $msg = shift;
	
	if ($debug)
	{
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
		printf "%4d-%02d-%02d %02d:%02d:%02d\t", $year+1900,$mon+1,$mday,$hour,$min,$sec;
		
		print $msg . "\n";
	}
}

sub update_settings_from_file
{
	my $qppl_fn = shift;
	
	if (-e $qppl_fn)
	{
		open (QPPL, $qppl_fn);
		my $settings = <QPPL>;
		chomp ($settings);
		close (QPPL);
		
		my ($env_max_u, $env_min_u, $env_min_t, $killall, $env_deadnodes) = split (/\t/, $settings);
	
		if (($env_max_u ne "") and ($max_processes_user ne $env_max_u))
		{
			logit ("Updated MAX_U from $qppl_fn: $max_processes_user => $env_max_u");
			$max_processes_user = $env_max_u;
		}
		
		if (($env_min_u ne "") and ($min_processes_user ne $env_min_u))
		{
			logit ("Updated MIN_U from $qppl_fn: $min_processes_user => $env_min_u");
			$min_processes_user = $env_min_u;
		}
		
		if (($env_min_t ne "") and ($min_processes_total ne $env_min_t))
		{
			logit ("Updated MIN_T from $qppl_fn: $min_processes_total => $env_min_t");
			$min_processes_total = $env_min_t;
		}

		if (($env_deadnodes ne "") and ($deadnodes ne $env_deadnodes))
		{
			logit ("Updated deadnodes from $qppl_fn: $deadnodes => $env_deadnodes");
			$deadnodes = $env_deadnodes;
			@dead_nodes = split (",", $deadnodes);
		}
		
		if ($killall eq "KILL")
		{
			my $jobs_to_kill = join " ", (keys %joblist);
			logit ("Killing $jobs_to_kill");
			
			my $qdel_result = `qdel $jobs_to_kill`;
			logit ("qdel result: $qdel_result");

			logit ("qp.pl exiting...");
			exit;
		}
	}
}



#-----------------------------------------------------------------------------------------
# --help 
#-----------------------------------------------------------------------------------------

__DATA__

 Syntax:         qp.pl <str>
 
 Description:    Send a command line <str> to the queue (using q.pl) only when the number of jobs 
                 of a certain user is below a predefined limit, and that at least some number of nodes
                 are left available for all users. 

                 **** The flag -max_t was removed and instead we use now -min_t and determine on-the-fly 
                      the number of active nodes (15 Oct 2006). ****

 Flags:

  -u <str>:      The user name to monitor the jobs according. (default: the sending user = `whoami`)
  -min_u <int>:  The minimum number of jobs in the queue that the user allows himself to send without
                 considering others... (default: 1 job)
  -max_u <int>:  The maximum number of jobs in the queue allowed for the user name. (default = 40 jobs)
  -min_t <int>:  The minimum number of jobs must be left available for all other users. (default = 6 jobs)
  -sl <int>:     The number of seconds the process 'sleeps' between each attempt to send the job. (default = 10 sec)
  -f <file>:     Name of file containing the commands to be executed (one per line)
  -report:       When on, reports to STDOUT the execution of each command and the wait time in seconds
  -manual:       Do not automatically add a "q.pl" before the command. Assumes the command includes the queue submission request.
  -no_quit       Keep running even if all the commands in the file were executed, until it sees a line "Q".
  -finish:       Wait for jobs to finish before returning control.
  -rerun:        Rerun jobs that did not finish properly. doesnt work with -manual.
  -debug         Debug information every 5 minutes
  -ping          Ping all nodes on which jobs are running every 5 minutes. Jobs that are on non-responsive nodes
                 are automatically re-run.
  -eqw:          Monitor Eqw jobs every 5 minutes and attempt to release them by qmod -cj.
  -q <str>:      Send the job to the queue named "str".  
  -l <str>:      Reserves "str" of memory for the job. Example for str: 2500M
  -qf            Queue name for each job is specified in -f file. For queue specification, line should start
                 with -q qname.
  -silent        supresses all output from qp.pl and q.pl




