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

my $empirical_shape_file = &get_arg("f", "", \%args);
my $distances_iter_str = &get_arg("d", "0,400,1", \%args);
my $peak_shape_type_str = &get_arg("peak_shape_type", "", \%args);
my $mean_iter_str = &get_arg("mean_iter", "0,0,1", \%args);
my $std_iter_str = &get_arg("std_iter", "10,100,1", \%args);

my @peak_shape_types;
if (length($peak_shape_type_str) == 0)
{
  push(@peak_shape_types, "Normal");
  push(@peak_shape_types, "Gamma");
}
else
{
  push(@peak_shape_types, $peak_shape_type_str);
}

my %empirical_peak_shape;
my $empirical_min = 10000;
my $empirical_max = -10000;
open(EMPIRICAL_PEAK_SHAPE, "<$empirical_shape_file") or die "Could not open empirical shape file $empirical_shape_file\n";
while(<EMPIRICAL_PEAK_SHAPE>)
{
  chomp;

  my @row = split(/\t/);

  $empirical_peak_shape{$row[0]} = $row[1];

  if ($row[1] > $empirical_max) { $empirical_max = $row[1]; }
  if ($row[1] < $empirical_min) { $empirical_min = $row[1]; }

  #print STDERR "Empirical\t$row[0]\t$row[1]\n";
}

my @distances_iter = split(/\,/, $distances_iter_str);
my @mean_iter = split(/\,/, $mean_iter_str);
my @std_iter = split(/\,/, $std_iter_str);

my $best_mean;
my $best_std;
my $best_peak_shape_type;
my $best_error = "";
for (my $mean = $mean_iter[0]; $mean <= $mean_iter[1]; $mean += $mean_iter[2])
{
  for (my $std = $std_iter[0]; $std <= $std_iter[1]; $std += $std_iter[2])
  {
    foreach my $peak_shape_type (@peak_shape_types)
    {
      my $peak_shape_str = `generate_peak_shape.pl -peak_shape_type $peak_shape_type -normal_mean $mean -normal_std $std -gamma_mean $mean -gamma_std $std -peak_shape_resolution 1`;
      my @peak_shape_array = split(/\n/, $peak_shape_str);
      my %test_peak_shape;
      foreach my $peak (@peak_shape_array)
      {
	my @row = split(/\t/, $peak);

	$test_peak_shape{$row[0]} = $row[1];

	#print STDERR "Test\t$row[0]\t$row[1]\n";
      }

      my $error = 0;
      for (my $i = $distances_iter[0]; $i <= $distances_iter[1]; $i += $distances_iter[2])
      {
	my $empirical = length($empirical_peak_shape{$i}) > 0 ? ($empirical_peak_shape{$i} - $empirical_min) / ($empirical_max - $empirical_min)  : 0;
	my $test = length($test_peak_shape{$i}) > 0 ? $test_peak_shape{$i} : 0;

	#print STDERR "Compare i=$i empirical=$empirical test=$test\n";

	$error += ($empirical - $test) * ($empirical - $test);
      }

      if (length($best_error) == 0 or $error < $best_error)
      {
	$best_error = $error;
	$best_mean = $mean;
	$best_std = $std;
	$best_peak_shape_type = $peak_shape_type;
      }

      print STDERR "$peak_shape_type\t$mean\t$std\t$error\n";
    }
  }
}

print "$best_peak_shape_type\t$best_mean\t$best_std\t$best_error\n";

__DATA__

generate_peak_shape.pl <file>

   Generates a peak shape

   -f <str>:                    File for empirical peak shape (format: <distance> <peak height>)
   -d <start,end,jump>:         Distances at which to compare peak shapes (default: 0,400,1)

   -peak_shape_type <str>:      Gamma/Normal (default: try all options)

   -mean_iter <start,end,jump>: Values over which to iterate (default: 0,0,1)
   -std_iter <start,end,jump>:  Values over which to iterate (default: 10,100,1)

