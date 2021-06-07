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

my $leading_organism_chromosome = get_arg("c", "", \%args);

my $synteny_block_number = 1;
while (<$file_ref>)
{
  chop;

  if (/<b>unplaced/)
  {
      last;
  }
  elsif (/>[\~][\~]</)
  {
      $synteny_block_number++;
  }
  else
  {
      my @row = split(/\t/);

      if ($row[2] =~ /go_l[\'], [\']([^\']+)[\']/)
      {
	  my $gene_id = $1;

	  my $other_chromosome = "";
	  if ($row[3] =~ /color[^\>]+>([^\<]+)<[\/]font/)
	  {
	      $other_chromosome = $1;
	  }

	  my $other_gene_id = "";
	  if ($row[5] =~ /go_l[\'], [\']([^\']+)[\']/)
	  {
	      $other_gene_id = $1;
	  }

	  print "Chr$leading_organism_chromosome sytenic block $synteny_block_number\t$gene_id\tChr$leading_organism_chromosome";
	  if (length($other_chromosome) > 0) { print ":$other_chromosome"; }
	  if (length($other_gene_id) > 0) { print " ($other_gene_id)"; }
	  print "\n";
      }
  }
}

__DATA__

parse_ncbi_homology_maps.pl <source file>

   Parse an NCBI homology map from an html file
   Note: Assumes that htmltable2list.pl was run on the original html file

   -c <str>: Chromosome name of the main organism

