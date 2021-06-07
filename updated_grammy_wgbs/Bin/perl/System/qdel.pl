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

my $all_users = get_arg("a", 0, \%args);

my $qstat_str = `qstat`;
my @qstat = split(/\n/, $qstat_str);
foreach my $task (@qstat)
{
  $task =~ /([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)/;

  my $queue_id = $1;
  my $user = $4;
  my $status = $5;

  if ($status eq "r" and ($all_users == 1 or $ENV{"USER"} eq $user))
  {
    system("qdel $queue_id");
  }
}

__DATA__

qdel.pl <file>

   Deletes the jobs of the current user

   -a: Return the Eqw errors of all users

