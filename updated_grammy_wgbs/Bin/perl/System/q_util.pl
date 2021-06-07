#! /usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub run_parallel_q_processes
{
  my $processes_cmd_lines_ptr;
  my $processes_num;
  my $num_of_sec_between_q_monitoring;
  my $is_delete_tmp_file;
  my $max_queue_length;
  my $max_user_p = 60;
  my $min_free_p = -1;
  my $user = `whoami`;
  chomp($user);
  
  

  if (scalar(@_) == 4)
  {
    ($processes_cmd_lines_ptr, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file) = @_;
    $max_queue_length = -1;
  }
  elsif (scalar(@_) == 5)
  {
    ($processes_cmd_lines_ptr, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file,$max_queue_length) = @_;
  }
  elsif (scalar(@_) == 7)
  {
    ($processes_cmd_lines_ptr, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file,$max_queue_length, $max_user_p, $min_free_p) = @_;
  }
  else
  {
	die "run_parallel_q_processes: input parameters num is not 4 or 5";
  }

  if ($processes_num < 1)
  {
    die "num of processes:$processes_num is less then one";
  }
  if ($num_of_sec_between_q_monitoring < 1)
  {
    print STDERR "run_parallel_q_processes warning:num_of_sec_between_q_monitoring(value:$num_of_sec_between_q_monitoring) was cahnged to min value:1";
    $num_of_sec_between_q_monitoring = 1;
  }


  my @processes_cmd_lines = @$processes_cmd_lines_ptr;
  my @processes_ids;
  my $cur_q_process_id;
  my $cur_q_process_str;
  
  print STDERR "User: $user\n";
  print STDERR "Max queue length: $max_queue_length\n";
  print STDERR "Max user processes: $max_user_p\n";
  print STDERR "Min free processes: $min_free_p\n";
  
  for (my $process_to_be_run_index = 0;$process_to_be_run_index < scalar(@processes_cmd_lines); ++$process_to_be_run_index)
  {
    if (scalar(@processes_ids) >= $processes_num)
    {
      # waiting for available process allocation
      print STDERR "Reach max processes number($processes_num) waiting for available process allocation\n";
      my $processes_ids_ptr = &wait_for_q_processes(\@processes_ids,$processes_num-1,$num_of_sec_between_q_monitoring,$is_delete_tmp_file);
      @processes_ids = @$processes_ids_ptr;
    }

    # caring to not create to long queue
    &wait_to_queue_length_shorter_then_len($max_queue_length,$num_of_sec_between_q_monitoring);
	
	if ($max_user_p > 0)
	{
		 &wait_for_max_user_processes($max_user_p,$user,$num_of_sec_between_q_monitoring);
	}
	
	if ($min_free_p > 0)
	{
		 &wait_for_min_free_processes($min_free_p,$num_of_sec_between_q_monitoring);
	}

    $cur_q_process_str = `q.pl \"$processes_cmd_lines[$process_to_be_run_index]\"`;  
    print STDERR $cur_q_process_str;

    $cur_q_process_str =~ /job ([^\ ]+)/;

    print STDERR "run process: $1\n";
    $cur_q_process_id = $1;

    push(@processes_ids,$cur_q_process_id);

  }

  # waiting for all to finish
  &wait_for_q_processes(\@processes_ids,0,$num_of_sec_between_q_monitoring,$is_delete_tmp_file);

}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub wait_for_q_processes
{
  my ($processes_ids_ptr,$max_processes_num_allow_for_finish_waiting,$num_of_sec_between_q_monitoring,$is_delete_tmp_file)= @_;
  my @processes_ids = @$processes_ids_ptr;
 
  if ($num_of_sec_between_q_monitoring < 1)
  {
    print STDERR "wait_for_q_processes warning:num_of_sec_between_q_monitoring(value:$num_of_sec_between_q_monitoring) was cahnged to min value:1\n";
    $num_of_sec_between_q_monitoring = 1;
  }

  if ($max_processes_num_allow_for_finish_waiting < 0)
  {
    print STDERR "wait_for_q_processes warning:max_processes_num_allow_for_finish_waiting(value:$max_processes_num_allow_for_finish_waiting) was cahnged to min value:0\n";
    $num_of_sec_between_q_monitoring = 0;
  }


  while (scalar(@processes_ids)> $max_processes_num_allow_for_finish_waiting)
  {
    for (my $i = 0; $i < scalar(@processes_ids); ++$i)
    {
      my $is_cur_process_id_in_q = &is_process_id_in_q($processes_ids[$i]);
      print STDERR "Checked process ($i): $processes_ids[$i] \n";
      if ($is_cur_process_id_in_q == 0)
      {
	print STDERR "Process: $processes_ids[$i], finished (not in q)\n";
	if ($is_delete_tmp_file == 1)
	  {
	    my $cur_process_id_to_delete = $processes_ids[$i];
	    `rm tmpjob*o$cur_process_id_to_delete`;
	    `rm tmpjob*e$cur_process_id_to_delete`;
	    print STDERR "Deleted tmp error and out files of process: $processes_ids[$i]\n";
	  }
	#removing from array
	if (scalar(@processes_ids) > 1)
	{
	  $processes_ids[$i] = $processes_ids[$#processes_ids];
        }
	pop(@processes_ids);
	--$i;
	my $length_processes_ids = scalar(@processes_ids);
	print STDERR "List of running (or not known to finish) processes size: $length_processes_ids\n";
      }

    }

    sleep($num_of_sec_between_q_monitoring);
  }

  return \@processes_ids;
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub is_process_id_in_q
{
  my $process_id = $_[0];

  my $q_stat = `qstat | grep \" $process_id \"`;

  print STDERR "q_stat($process_id):$q_stat\n";

  if ( scalar($q_stat) > 3)
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

# -------------------------------------------------------------------------
# if negative don't wait
# ------------------------------------------------------------------------
sub wait_to_queue_length_shorter_then_len
{
	my ($max_queue_length,$num_of_sec_between_q_monitoring) = @_;
	
	if ($max_queue_length < 0)
	{
		return;
	}
	
	my $cur_queue_length = &get_queue_length();
	
   while ($cur_queue_length> $max_queue_length)
  {
	print STDERR "Waiting For Queue Length smaller (or equal) to: $max_queue_length (cur len: $cur_queue_length)\n";
	sleep($num_of_sec_between_q_monitoring);
	$cur_queue_length = &get_queue_length();
  }
}

# -------------------------------------------------------------------------
# if negative don't wait
# ------------------------------------------------------------------------
sub wait_for_min_free_processes
{
	my ($min_free_p,$num_of_sec_between_q_monitoring) = @_;
	
	if ($min_free_p < 0)
	{
		return;
	}
	
	my $cur_free_process_num = &get_free_process_num();
	
   while ($min_free_p > $cur_free_process_num)
  {
	print STDERR "Waiting For at least $min_free_p free processes (cur free processes num: $cur_free_process_num)\n";
	sleep($num_of_sec_between_q_monitoring);
	$cur_free_process_num = &get_free_process_num();
  }
}

# -------------------------------------------------------------------------
# if negative don't wait
# ------------------------------------------------------------------------
sub wait_for_max_user_processes
{
	my ($max_user_p,$user,,$num_of_sec_between_q_monitoring) = @_;
	
	if ($max_user_p < 0)
	{
		return;
	}
	
	my $cur_user_process_num = &get_user_process_num($user);
	
   while ($max_user_p <= $cur_user_process_num)
  {
	print STDERR "Waiting For at most $max_user_p user processes (cur user processes num: $cur_user_process_num)\n";
	sleep($num_of_sec_between_q_monitoring);
	$cur_user_process_num = &get_user_process_num();
  }
  
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub get_user_process_num
{
	my ($user) = @_;
	my $tmp_u = `qstat -u $user | wc -l`;
	my $current_num_processes_user = ($tmp_u > 2) ? ($tmp_u - 2) : 0;
	
	print STDERR "User ($user) processes: $current_num_processes_user\n";
	return $current_num_processes_user;
}


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub get_free_process_num
{
	my $tmp_wt = `qstat -g c | tail -n 1 | sed -r 's/[\ ]+/\t/g' | cut.pl -f 3,5,7`;
	chomp($tmp_wt);
	my @tmp_wtr = split(/\t/,$tmp_wt);
	my $free_process_num = $tmp_wtr[1] - $tmp_wtr[0] - $tmp_wtr[2];
	
	print STDERR "Free processes num: $free_process_num\n";
	return $free_process_num;
}


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub get_queue_length
{
	my $queue_length  = (`qstat | grep \" qw \" | wc -l`);
	chomp($queue_length);
	
	print STDERR "Queue Length: $queue_length\n";
	return $queue_length;
}
