#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
#require "$ENV{PERL_HOME}/Lib/format_number.pl";
#require "$ENV{PERL_HOME}/GeneXPress/gxt_helpers.pl";

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
my $column = get_arg("c", 6, \%args);
my $null_value = get_arg("nu", 0, \%args);
my $name_vec = get_arg("n", "Dammi_id", \%args);
$column = $column - 1;    #1-base

my $chromosome = "";
my $start = 0;
my $end = 0;
my $val = 0;

print "$name_vec";

while(my $line = <$file_ref>)
{
  chomp($line);
  my @r = split(/\t/,$line);

  if ($chromosome ne $r[0])
  {
    $end = -1;  
    $chromosome = $r[0];
  }

  $start = ($r[2] < $r[3]) ? $r[2] : $r[3]; 

  $val = $null_value;

  for (my $i = ($end+1); $i < $start; $i++)
  {
    print "\t$val";
  }

  $end = ($r[2] < $r[3]) ? $r[3] : $r[2]; 
  $val = $r[$column];

  for (my $i = $start; $i <= $end; $i++)
  {
    print "\t$val";
  }
}

print "\n";


__DATA__

chr2vec.pl <chr file>

   convert a chr file to a vector format.
   The chr file must have uniq entries per location (otherwise use first 
   chr_merge_consecutive_locations.pl), and must be sorted by minimum of columns 3,4.

   -c <int>:  The column of the values to report in the vector. 1-based. (default: 6)

   -nu <num>: A null value for non defined locations. (default: 0)

   -n <str>:  The name/id of the vector. (default: Dammi_id)
