#!/usr/bin/perl
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my $RUNNING_LOG = "fail_log.txt";

my %args = load_args(\@ARGV);
my $wc = get_arg("wc", 0, \%args);
my $ok = get_arg("ok", "ok", \%args);
my $fail = get_arg("f", "fail", \%args);
my $mega_fail = get_arg("mf", "", \%args);
my $num_mega_fail = get_arg("n", 5, \%args);
my $d1 = get_arg("1", "", \%args);
my $d2 = get_arg("2", "", \%args);

if ($wc)
{
	$d1 = `cat $d1 | wc -l`;
	$d2 = `cat $d2 | wc -l`;
}

if ($d1 == $d2)
{
	print "$ok";
	system ("/bin/rm -rf $RUNNING_LOG");
}
else
{
	system ("echo `date` >> $RUNNING_LOG");
	my $log_count = `cat $RUNNING_LOG | wc -l`;

	if ($log_count < $num_mega_fail)
	{
		print "$fail";
	}
	else
	{
		print $mega_fail ? "$mega_fail" : "$fail";
	}
}


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__
assert.pl

Check if two given values are the same.
Print as output the next command.

OPTIONS:
  -1  <str>  First value
  -2  <str>  Second value
  -ok <str>  Command to output if values are the same (default: ok)
  -f  <str>  Command to output if values differ failed (default: fail)
  -mf <str>  Command to output in case of "mega fail", i.e., failed more than
             the suggested number of times.
  -n <num>   Number of repeats before "mega fail" (default: 5).
  -wc        Instead of comapring the two given values, compare the length (in lines) of 
             the two given files
             
             
