#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $CONST_p0 = 1.000000000190015;
my $CONST_p1 = 76.18009172947146;
my $CONST_p2 = -86.50532032941677;
my $CONST_p3 = 24.01409824083091;
my $CONST_p4 = -1.231739572450155;
my $CONST_p5 = 1.208650973866179*0.001;
my $CONST_p6 = -5.395239384953*0.000001;
my $CONST_M_PI = 3.1428;

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

my $peak_shape_type = &get_arg("peak_shape_type", "Normal", \%args);
my $peak_shape_resolution = &get_arg("peak_shape_resolution", 1, \%args);
my $gamma_mean = &get_arg("gamma_mean", 200, \%args);
my $gamma_std = &get_arg("gamma_std", 100, \%args);
my $normal_mean = &get_arg("normal_mean", 0, \%args);
my $normal_std = &get_arg("normal_std", 60, \%args);

my $TOLERANCE = 0.0001;

if ($peak_shape_type eq "Gamma")
{
  my $beta = $gamma_mean / ($gamma_std * $gamma_std);
  my $alpha = $gamma_mean * $beta;

  my $x = 0;
  my $height = 1.0;
  while($height > $TOLERANCE)
  {
    $height = 1 - &IncompleteGamma($alpha + 1, $x * $beta) / &GammaIntegral($alpha + 1) - $x * (1 - &IncompleteGamma($alpha, $x * $beta) / &GammaIntegral($alpha)) * $beta / $alpha;

    print "$x\t$height\n";

    $x++;
  }
}
elsif ($peak_shape_type eq "Normal")
{
  my $x = 0;
  my $height = 1.0;
  while($height > $TOLERANCE)
  {
    $height = (&Normal($x) / &Normal($normal_mean));

    print "$x\t$height\n";

    $x++;
  }
}

sub Normal
{
  my ($x) = @_;

  return (1.0 / (2 * 3.1428 * $normal_std) * exp(-($x - $normal_mean) * ($x - $normal_mean) / (2 * $normal_std * $normal_std)));
}

sub GammaIntegral
{
   my ($z) = @_;

   my $P = $CONST_p0 + ($CONST_p1 / ($z + 1)) + ($CONST_p2 / ($z + 2)) + ($CONST_p3 / ($z + 3)) + ($CONST_p4 / ($z + 4)) + ($CONST_p5 / ($z + 5)) + ($CONST_p6 / ($z + 6));

   return (sqrt(2 * $CONST_M_PI) / $z) * $P * (($z + 5.5) ** ($z + 0.5)) * exp(-($z + 5.5));
}

sub IncompleteGamma
{
   my ($alpha1, $x1) = @_;

   my $sum = 0;
   my $term = 1.0 / $alpha1;
   my $n = 1;
   while ($term != 0)
   {
	   $sum = $sum + $term;
	   $term = $term * ($x1 / ($alpha1 + $n));
	   $n++;
   }
   return ($x1 ** $alpha1) * exp(-$x1) * $sum;
}

__DATA__

generate_peak_shape.pl <file>

   Generates a peak shape

   -peak_shape_type <str>:       Gamma/Normal (default: Normal)
   -peak_shape_resolution <num>: Resolution for the peak shape (default: 1)

   -gamma_mean <num>:            Mean for a gamma function peak shape (default: 200)
   -gamma_std <num>:             Std for a gamma function peak shape (default: 100)

   -normal_mean <num>:           Mean for a normal distribution peak shape (default: 0)
   -normal_std <num>:            Std for a normal distribution peak shape (default: 60)

