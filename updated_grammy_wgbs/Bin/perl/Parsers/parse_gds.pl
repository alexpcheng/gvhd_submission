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

my $add_gsm_to_experiment_name = get_arg("GSM", 0, \%args);
my $gene_id_column = get_arg("id", 0, \%args);

my $inside_file = 0;
my %gsm2name;

while (<$file_ref>)
{
  chop;

  if (/^\#(GSM[^ ]+) = Value for (GSM[^:]+:)(.*)/)
  {
    $gsm2name{$1} = $add_gsm_to_experiment_name ? $2 . $3 : $3;
    #print STDERR "$1\t$2\n";
  }
  elsif (/^ID_REF	IDENTIFIER	GSM/)
  {
    $inside_file = 1;

    my @row = split(/\t/);

    print "$row[$gene_id_column]\t";
    for (my $i = 2; $i < @row; $i++)
    {
      my $column = length($gsm2name{$row[$i]}) > 0 ? $gsm2name{$row[$i]} : $row[$i];

      print "$column\t";
    }
    print "\n";
  }
  elsif ($inside_file == 1)
  {
    my @row = split(/\t/);

    print "$row[$gene_id_column]\t";
    for (my $i = 2; $i < @row; $i++)
    {
      print "$row[$i]\t";
    }
    print "\n";
  }
}

__DATA__

parse_gds.pl <source file>

   Parse a GDS file and extract it as a tab-delimited file

   -GSM:      Add the GSM identifier to each experiment name

   -id <num>: Take gene ids from this column (default: 0)

