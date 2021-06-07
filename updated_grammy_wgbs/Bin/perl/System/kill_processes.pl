#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) 
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);

my $user_str = get_arg("u", "", \%args);
my $process_str = get_arg("s", "", \%args);
my $force_kill = get_arg("f", "0", \%args);

my $user_search = length($user_str) > 0 ? " | grep $user_str" : "";
my $process_search = length($process_str) > 0 ? " | grep $process_str" : "";
my $force_str = $force_kill == 1 ? " -9 " : "";

my $processes_str = `ps -aux $user_search $process_search`;
my @processes = split(/\n/, $processes_str);

foreach my $process (@processes)
{
  $process =~ /[ ]+([^ ]+)/;

  print STDERR "Killing process $1\n";
  `kill $force_str $1\n`;
}

__DATA__

kill_processes.pl <file>

   Kills processes with specific criteria

   -u <str>: Kill processes only by user <str>
   -s <str>: Kill processes that contain the string <str>

   -f:       Force killing process

