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

my $composite_name = get_arg("n", "", \%args);
my $composite_markov_order_name = get_arg("no", "Matrix", \%args);
my $alphabet_size = 4;
my $left_padding_positions = 0;
my $right_padding_positions = 0;
my $extend_length_by = get_arg("ext", 0, \%args);

#<WeightMatrices>
my $line = <$file_ref>;
chomp($line);
($line =~ m/WeightMatrices/) or die("Expected first line to be: \n'<WeightMatrices>'\n");
print STDOUT "$line\n";

#<WeightMatrix Name="Background" Type="MarkovOrder" LeftPaddingPositions="0" RightPaddingPositions="0" Order="5">
$line = <$file_ref>;
chomp($line);
($line =~ m/WeightMatrix/) or die("Expected a '<WeightMatrix>' token\n");

if (length($composite_name) == 0)
{
   $line =~ m/Name="([^"]*)"/;
   $composite_name = $1;
}

$line = <$file_ref>;
chomp($line);

my @markov_order_lines = ();
my %markov_order2line_start = ();

my $order = -1;
my $line_counter = 0;

while ($line =~ m/Order Markov="([\d]*)"/)
{
   $markov_order_lines[$line_counter] = $line;
   my $new_order = $1;
   if ($new_order > $order)
   {
      $markov_order2line_start{$new_order} = $line_counter;
      $order = $new_order;
   }
   $line_counter++;
   $line = <$file_ref>;
   chomp($line);
}

#</WeightMatrix> *
($line =~ m/\/WeightMatrix/) or die("Expected a '</WeightMatrix>' token\n");

#</WeightMatrices> *
$line = <$file_ref>;
chomp($line);
($line =~ m/\/WeightMatrices/) or die("Expected a '</WeightMatrices>' token\n");

for (my $i=0; $i <= $order; $i++)
{
   &PrintMarkovOrder($i);
}

&PrintComposite();

print STDOUT "</WeightMatrices>\n";

#---------------------------------------------#
# Subroutines                                 #
#---------------------------------------------#

#---------------------------------------------#
# PrintMarkovOrder($i)                        #
#---------------------------------------------#
sub PrintMarkovOrder
{
   my $i = shift;
   print STDOUT "<WeightMatrix Name=\"$composite_markov_order_name$i\" Type=\"MarkovOrder\" LeftPaddingPositions=\"0\" RightPaddingPositions=\"0\" DoubleStrandBinding=\"false\" EffectiveAlphabetSize=\"4\"  Order=\"$i\">\n";
   my $start = $markov_order2line_start{$i};
   my $end = $start + ($alphabet_size ** $i) -1;

   for (my $k = 0; $k <= $end; $k++)
   {
      my $str = $markov_order_lines[$k];
      print STDOUT "$str\n";
   }

   print STDOUT "</WeightMatrix>\n";
}

#---------------------------------------------#
# PrintComposite()                            #
#---------------------------------------------#
sub PrintComposite
{
   print STDOUT "<WeightMatrix Name=\"$composite_name\" Type=\"Composite\" LeftPaddingPositions=\"$left_padding_positions\" RightPaddingPositions=\"$right_padding_positions\" DoubleStrandBinding=\"false\" EffectiveAlphabetSize=\"$alphabet_size\" Alphabet=\"ACGT\" Symmetric=\"false\" Even=\"false\" >\n";

   for (my $k=0; $k <= $order; $k++)
   {
      print STDOUT "  <SubMatrix Name=\"$composite_markov_order_name$k\"></SubMatrix>\n";
   }

   for (my $kext=0; $kext < $extend_length_by; $kext++)
   {
      print STDOUT "  <SubMatrix Name=\"$composite_markov_order_name$order\"></SubMatrix>\n";
   }

   print STDOUT "</WeightMatrix>\n";
}

__DATA__

gxw_markov2composite.pl <file.gxw>

   Takes in a weight matrix (.gxw format) of type MarkovOrder and output an equivalent Composite weight matrix.

   ** gxw2stats.pl at the time of writing (Aug 31, 2007) does not work for predicting a MarkovOrder's posterior probability,
      but works well with a Composite format **

   -n <str>           The name of the Composite weight matrix (default: take the original MarkovOrder weight matrix's name)

   -no <str>          The template name for the internal MarkovOrder weight matrices (default: 'Matrix')

   -ext <num>         Extend the composite by <num> bp (default: 0)

                      E.g., having a 5-order Markov model '6mers.gxw',
                      we can generate a composite that scores for 8mers by:
                      gxw_markov2composite.pl 6mers.gxw -ext 2 > 8mers.gxw
