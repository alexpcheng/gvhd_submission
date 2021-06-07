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
my $motif_name = get_arg("name", "Matrix", \%args);
my $skip_lines = get_arg("skip", 0, \%args);

for (my $i = 0; $i < $skip_lines; $i++)
{
  my $line = <$file_ref>;
}

print "<WeightMatrices>\n";
my $header_printed = 0;

my %weights;
my $markov_order;

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

  if ($header_printed == 0)
  {
    $header_printed = 1;

    $markov_order = length($row[0]);

    print "<WeightMatrix Name=\"$motif_name\" Type=\"MarkovOrder\" Order=\"" . ($markov_order - 1) . "\">\n";
  }

  for (my $i = 0; $i < $markov_order; $i++)
  {
    my $str = substr($row[0], 0, $i + 1);

    $weights{$str} += $row[1];
  }
}

for (my $i = 0; $i < $markov_order; $i++)
{
  for (my $j = 0; $j < 4 ** $i; $j++)
  {
    my $str = "";
    my $parents_str = "";
    my $current_num = $j;
    for (my $k = 0; $k < $i; $k++)
    {
      if ($k > 0) { $parents_str .= ";"; }

      my $num = $current_num % 4;

      if ($num == 0)    { $str .= "A"; $parents_str .= "0"; }
      elsif ($num == 1) { $str .= "C"; $parents_str .= "1"; }
      elsif ($num == 2) { $str .= "G"; $parents_str .= "2"; }
      elsif ($num == 3) { $str .= "T"; $parents_str .= "3"; }

      $current_num = int($current_num / 4);

      #print "Num=$num\n";
    }

    $str = &Reverse($str);
    $parents_str = &Reverse($parents_str);

    #print "Parents = $str\n";

    my $A_weight = length($weights{$str . "A"}) > 0 ? $weights{$str . "A"} : 0;
    my $C_weight = length($weights{$str . "C"}) > 0 ? $weights{$str . "C"} : 0;
    my $G_weight = length($weights{$str . "G"}) > 0 ? $weights{$str . "G"} : 0;
    my $T_weight = length($weights{$str . "T"}) > 0 ? $weights{$str . "T"} : 0;

    if ($no_normalization == 0)
    {
      my $sum = $A_weight + $C_weight + $G_weight + $T_weight;
      if ($sum > 0)
      {
	$A_weight /= $sum;
	$C_weight /= $sum;
	$G_weight /= $sum;
	$T_weight /= $sum;
      }
      else
      {
	$A_weight = 0;
	$C_weight = 0;
	$G_weight = 0;
	$T_weight = 0;
      }
    }

    print "  <Order Markov=\"$i\" ";

    if ($i > 0) { print "Parents=\"$parents_str\" "; }

    print "Weights=\"$A_weight;$C_weight;$G_weight;$T_weight\">";

    print "</Order>\n";
  }
}

print "</WeightMatrix>\n";

print "</WeightMatrices>\n";

sub Reverse
{
  my ($str) = @_;

  my $res = "";

  my $str_len = length($str);
  for (my $i = 0; $i < $str_len; $i++)
  {
    $res .= substr($str, $str_len - $i - 1, 1);
  }

  return $res;
}

__DATA__

list2markov_order.pl <gxm file>

   Given a list of sequences with weights, convert it to a gxw file.
   Input format: <Sequence><tab><Weight>

   -nonorm:     Do not normalize the probabilities per weight (default: normalize)

   -name <str>: The name of the motif to output (default: "Matrix")

   -skip <num>: Number of input lines to skip before the sequences begin (default: 0)

