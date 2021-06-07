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

my $no_normalization = get_arg("nonorm", 0, \%args);
my $matrix_type = get_arg("t", "PositionSpecific", \%args);
my $markov_order = get_arg("o", "0", \%args);

if ($markov_order > 1)
{
  print STDERR "tab2gxw.pl does not currently support Markov order > 1\n";
  exit;
}

print "<WeightMatrices>\n";

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

  print "<WeightMatrix Name=\"$row[0]\" Type=\"$matrix_type\" Order=\"$markov_order\">\n";

  for (my $i = 1; $i < @row; $i += 4)
  {
    if ($matrix_type eq "PositionSpecific")
    {
      print "  <Position ";
    }
    elsif ($matrix_type eq "MarkovOrder")
    {
      my $current_markov_order = 0;
      my $previous_base = 0;
      while (($i - $previous_base) > 4 ** ($current_markov_order + 1))
      {
	$previous_base += 4 ** ($current_markov_order + 1);

	$current_markov_order++;
      }

      print "  <Order Markov=\"$current_markov_order\" ";

      if ($current_markov_order > 0)
      {
	print "Parents=\"";
	print int(($i - $previous_base) / 4);
	print "\" ";
      }
    }

    print "Weights=\"";

    my $sum = 0;
    for (my $j = $i; $j < $i + 4; $j++)
    {
      $sum += $row[$j];
    }
  
    for (my $j = $i; $j < $i + 4; $j++)
    {
	if ($j > $i)
	{
	    print ";";
	}

	if ($no_normalization == 1) { print $row[$j]; }
	else { print ($row[$j] / $sum); }
    }

    print "\">";

    if ($matrix_type eq "PositionSpecific")
    {
      print "</Position>\n";
    }
    elsif ($matrix_type eq "MarkovOrder")
    {
      print "</Order>\n";
    }
  }

  print "</WeightMatrix>\n";
}

print "</WeightMatrices>\n";

__DATA__

tab2gxw.pl <gxm file>

   Given a tab file as input, converts it to a gxw file
   The format assumed, is name of the motif, followed by 
   probabilities/weights, with the weight for A,C,G,T 
   in this order

   -nonorm:  Do not normalize the probabilities per weight (default: normalize)

   -t <str>: Matrix type (PositionSpecific/MarkovOrder/Composite default: PositionSpecific)

   -o <num>: In case of MarkovOrder matrices, <num> is the Markov order (default: 0)
             NOTE: CURRENTLY SUPPORTS ONLY UP TO MARKOV ORDER 1!

