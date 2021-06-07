#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $species = get_arg("s", "", \%args);
my $pseudo_counts = get_arg("p", 0.1, \%args);

print "<WeightMatrices>\n";

my %all_factors;
my %current_species;
my $current_id = "";
my $inside_matrix = 0;
my @positions;
my $num_sites = 0;
while(<$file_ref>)
{
  chop;

  if (/^[\/][\/]/)
  {
      foreach my $organism (keys %current_species)
      {
	  my $name = $current_species{$organism};
	  if ($all_factors{"${organism}_$name"} eq "1")
	  {
	      my $addon = 1;
	      my $done = 0;
	      while ($done == 0)
	      {
		  if ($all_factors{"${organism}_${name}_$addon"} eq "1")
		  {
		      $addon++;
		  }
		  else
		  {
		      $name .= "_$addon";
		      $done = 1;
		  }
	      }
	  }
	  $all_factors{"${organism}_$name"} = "1";

	  print "<WeightMatrix ";
	  print "Name=\"Literature_$current_id\" ";
	  print "Description=\"$name\" ";
	  print "Type=\"PositionSpecific\" ";
	  print "ZeroWeight=\"0\" ";
	  print "Source=\"Transfac\" ";
	  print "Sites=\"$num_sites\">\n";

	  for (my $i = 0; $i < @positions; $i++)
	  {
	      my @row = split(/\t/, $positions[$i]);
	      my $sum = 0;
	      for (my $i = 0; $i < @row; $i++)
	      {
		  $sum += $row[$i] + $pseudo_counts;
	      }

	      print "  <Position Weights=\"";
	      for (my $i = 0; $i < @row; $i++)
	      {
		  if ($i > 0) { print ";"; }

		  print &format_number(($row[$i] + $pseudo_counts) / $sum, 3);
	      }
	      print "\"></Position>\n";
	  }

	  print "</WeightMatrix>\n";
      }

      %current_species = ();
      $inside_matrix = 0;
      $current_id = "";
      @positions = ();
      $num_sites = 0;
  }
  elsif (/ID[ ]+[^ ]+[\$]([^ ]+)/)
  {
      $current_id = $1;
  }
  elsif (/BF[ ]+[^;]+; ([^;]+); Species[\:] ([^\.]+)[\.]/)
  {
      if (length($species) == 0 or $species eq $2)
      {
	  if (length($current_species{"$2"}) > 0) { $current_species{"$2"} .= "_$1"; }
	  else { $current_species{"$2"} = "$1"; }
	  print STDERR "Found $1\t$2\n";
      }
  }
  elsif (/^P0/)
  {
      $inside_matrix = 1;
  }
  elsif (/^XX/)
  {
      $inside_matrix = 0;
  }
  elsif ($inside_matrix == 1)
  {
      /^[^ ]+[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)/;
      push(@positions, "$1\t$2\t$3\t$4");

      if ($1 + $2 + $3 + $4 > $num_sites)
      {
	  $num_sites = $1 + $2 + $3 + $4;
      }
  }
}

print "</WeightMatrices>\n";

__DATA__

parse_transfac.pl <file>

   Parses a transfac .dat file

   -s <str>: Extract only this species (default: extract all)
   -p <num>: Use this as pseudo counts (default: 0.1)

