#!/usr/bin/perl

use strict;
#use POSIX ":sys_wait_h";

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $matlabPath = "matlab";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


$SIG{INT} = \&child_killed;

my %args = load_args(\@ARGV);
my $matlabDev = get_arg("path", "$ENV{DEVELOP_HOME}/Matlab", \%args);

my $MATLAB_DEV_PATH = "$ENV{DEVELOP_HOME}/Matlab";

my $running = 1;

my $tmp_matlabDev = get_arg("local", 0, \%args);

if ($tmp_matlabDev)
{
   $matlabDev = `pwd`;
   chomp($matlabDev);
}
my $print_output = get_arg("po", 0, \%args);
my $silent = get_arg("silent", 0, \%args);
my $mfile  = get_arg("m", "", \%args);
my $input_params = get_arg("p", "", \%args);
my $script = get_arg("script", 0, \%args);
my $jvm    = get_arg("jvm", 0, \%args);
my $disp_fun_output  = get_arg("disp_fun_output", 0, \%args);
my $print_dont_run  = get_arg("print_dont_run", 0, \%args);
my $multi_threading    = get_arg("multi_threading", 0, \%args);


my $params = "";

if (!$silent){
    print STDERR "Parsing input parameters\n";
}
if ($input_params ne "")
{
   
   # old TODO remove
   #$params = join ('\',\'', @r_params);
   #$params = "(\'$params\')";

   $params = "(";

   my @r_params = split (',',$input_params);


	for (my $i = 0; $i <= $#r_params; $i++)
	{
      my  $param = $r_params[$i];

      $param = trim($param);

      if ($i > 0)
      {
	$params = "$params,";
      }

      my $param_suf = "";

      if ($param =~ /^\{.*$/ || $param =~ /.*\}$/ )
	{
	  if ($param =~ /^\{.*$/)
	    {
	      $params = "$params" . substr($param,0,1);
	      $param = substr($param,1);
	      $param = trim($param);
	    }

	  if ($param =~ /.*\}$/)
	    {
	      my $cur_str_len = length $param;
	      $param_suf = substr($param,$cur_str_len-1,1);
	      $param = substr($param,0,$cur_str_len-1);
	      $param = trim($param);
	    }
	}

      if ($param =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ||
	  $param =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ||
	  $param =~ /^NaN$/ ||
	  $param =~ /^nan$/ ||
	  $param =~ /^NAN$/ ||
	  $param =~ /^eps$/ ||
	  $param =~ /^\[.*$/ ||
	  $param =~ /.*\]$/ )
      {
	  $params = "$params$param";
      }
      else
      {
	  $params = "$params\'$param\'";
	if (!$silent) {  
	    print STDERR "matlabrun param:$param\n";
	}
      }
      $params = "$params$param_suf";
    }

   $params = "$params)";

 }

if ($mfile eq "")
  {
    die ("Must supply name of .m file to be run\n");
  }

my $done_running_flag = 0;
my $command;
my $matlab_output;

my $sendtonull="";

#setpgrp (0, 0);

while ($done_running_flag == 0) {
  
  $sendtonull="";
  
  $command = "$matlabPath -nodisplay -nodesktop -nosplash";
  
  if ($jvm == 0) {
    $command = $command ." -nojvm";
  }
  
  if ($multi_threading == 0) {
    $command = $command ." -singleCompThread";
  }
    
  if ($script) 
    {
      $command = $command . " -r \"try addpath('$matlabDev', 0); addpath(genpath('$MATLAB_DEV_PATH'), 1); $mfile; catch err= lasterror; disp(['MATLAB_SCRIPT_Error:' err.message]); disp(['error massage: ' err.message]); disp(['error identifier: ' err.identifier]); for i=1:length(err.stack) disp(sprintf('stack %d - file: %s, name: %s, line: %d', i, err.stack(i).file, err.stack(i).name, err.stack(i).line)); end;     end; exit;\" $sendtonull";
    }
  else 
    {
      if ($disp_fun_output) {
	$command = $command . " -r \"try addpath('$matlabDev', 0); addpath(genpath('$MATLAB_DEV_PATH'), 1); disp($mfile$params); catch err = lasterror; disp(['MATLAB_SCRIPT_Error:' err.message]);      disp(['error massage: ' err.message]); disp(['error identifier: ' err.identifier]); for i=1:length(err.stack) disp(sprintf('stack %d - file: %s, name: %s, line: %d', i, err.stack(i).file, err.stack(i).name, err.stack(i).line)); end;    end; exit;\" $sendtonull";
      }
      else {
	$command = $command . " -r \"try addpath('$matlabDev', 0); addpath(genpath('$MATLAB_DEV_PATH'), 1); $mfile$params; catch err = lasterror; disp(['MATLAB_SCRIPT_Error:' err.message]);      disp(['error massage: ' err.message]); disp(['error identifier: ' err.identifier]); for i=1:length(err.stack) disp(sprintf('stack %d - file: %s, name: %s, line: %d', i, err.stack(i).file, err.stack(i).name, err.stack(i).line)); end;    end; exit;\" $sendtonull";
      }
    }
  

  if ($print_dont_run) 
    {
	  print STDERR "Printing (not running) Matlab command:\n$command\n";
	  $done_running_flag = 1;
	  
    }
  else 
    {
	if (!$silent) {
	    print STDERR "Calling Matlab with:\n$command\n";
	}
	
	$matlab_output =  `$command`;
	
	if (!$silent) {
	    print STDERR "Finish a Matlab run.\n";
	}
      
      if ($print_output) 
      {
		print STDERR "#################################################################\n############################\n## Matlab output (look here for WARNINGS!):\n############################\n\n$matlab_output\n\n#################################################################\n\n";
      }

      if ( ((index($matlab_output, "MATLAB_SCRIPT_Error") >= 0) || (index($matlab_output, "Segmentation") >= 0)) && (index($matlab_output, "License checkout failed") < 0) ) 
      {
		die "#################################################################\nMATLAB ERROR -- MATLAB ERROR -- MATLAB ERROR -- MATLAB ERROR -- MATLAB ERROR -- MATLAB ERROR\n############################\n## Failed to run Matlab:\n############################\n\n$matlab_output\n\nMATLAB ERROR -- MATLAB ERROR -- MATLAB ERROR -- MATLAB ERROR -- MATLAB ERROR -- MATLAB ERROR\n#################################################################\n\n";
      }

      $done_running_flag = 1;

      if (index($matlab_output, "License checkout failed") >= 0) 
	{
	  $done_running_flag = 0;
          print STDERR "#####License checkout failed running Matlab again.#####\n";
	}

}
  
}

# Echo the result of matlab (should be placed in matlab.out)

my $outFile = 'matlab.out';

if (open(OUTFILE, $outFile)) {
  my @lines = <OUTFILE>;
  close(OUTFILE);
  print @lines;
  system("rm matlab.out");
}

sub child_killed
{ 

   my $ps_out = `pstree -p $$ | tr '(' '\n' | grep '^[0-9]' | cut -f 1 -d ')'`;

   #print STDERR "Child processes: $ps_out\n";

   for my $pid (split(/\n/, $ps_out)) 
   {
      my $curr_p = `ps -p $pid | grep -v PID`;
      if (length ($curr_p) > 0 and $pid != $$ )
      {
	 #print STDERR "Killing: $curr_p\n";
	 kill ('KILL', $pid);
      }
   }
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
  {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
  }
# Left trim function to remove leading whitespace
sub ltrim($)
{
  my $string = shift;
  $string =~ s/^\s+//;
  return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim($)
	  {
	    my $string = shift;
	    $string =~ s/\s+$//;
	    return $string;
	  }
	  
	  

# matlabrun.pl <file_name> -s <stat_type>

__DATA__

matlabrun.pl

    Run an arbitrary matlab script/function from within perl. If the script creates a file called
    "matlab.out" then it is echoed to stdout.

    *** For running a script (e.g. test.m) from the current directory run:    matlabrun.pl -m test -local -script



    -path    path where the matlab .m file can be found 
            (if the script is in ~/develop/Matlab or one of its sub-directories there is no need to give the path)
    -local   Set the path to the current directory (`pwd`)
    -m       name of the matlab .m file to be called (without the .m)
    -script  Run a script instead of a function (i.e. without parameters)
    -p       parameters to be passed to the .m file
    -print_dont_run - just prints the run command but do not run it
    -po      print matlab session to screen (this is important in order to see matlab WARNINGS)
    -jvm    call matlab with java virtual machine (needed for some functions). using this option might reduce performance
    -disp_fun_output calls matlab with disp(func(<params>)); this will printout the function output
    -multi_threading    call matlab with multi threding abilities. (Leon asked not to use this option on mcluster01)
