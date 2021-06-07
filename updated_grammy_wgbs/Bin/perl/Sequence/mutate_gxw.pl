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

my $matrices_file = get_arg("f", 0, \%args);
my $number_positions_to_mutate = get_arg("n", 0, \%args);

my $matrices_str = `gxw2tab.pl $matrices_file`;
my @matrices = split(/\n/, $matrices_str);

my @all_positions;
my $all_positions_counter = 0;
my %positions2matrix;
my %positions2matrix_position;

my @matrices_numbers;
my @matrices_lengths;
for (my $i = 0; $i < @matrices; $i++)
{
    my @row = split(/\t/, $matrices[$i]);
    my $num_positions = @row;
    for (my $j = 1; $j < $num_positions; $j += 4)
    {
	push(@all_positions, $all_positions_counter);

	$positions2matrix{$all_positions_counter} = $i;
	$positions2matrix_position{$all_positions_counter} = $j;

	$all_positions_counter++;
    }

    for (my $j = 0; $j < @row; $j++)
    {
	$matrices_numbers[$i][$j] = $row[$j];
    }

    $matrices_lengths[$i] = $num_positions;
}

for (my $i = 0; $i < $all_positions_counter; $i++)
{
    my $p = int(rand($all_positions_counter));
    my $tmp = $all_positions[$i];
    $all_positions[$i] = $all_positions[$p];
    $all_positions[$p] = $tmp;
    #print STDERR "all_positions[$i] <-> all_positions[$p]\n";
}

for (my $i = 0; $i < $number_positions_to_mutate; $i++)
{
    my $position = $all_positions[$i];
    my $matrix_id = $positions2matrix{$position};
    my $position_start = $positions2matrix_position{$position};

    print STDERR "Mutating matrix $matrices_numbers[$matrix_id][0] at position " . int($position_start / 4) . "\n";

    my @row;
    my $sum = 0;
    for (my $j = 0; $j < 4; $j++)
    {
	my $num = rand(1);
	push(@row, $num);
	$sum += $num;
    }
    for (my $j = 0; $j < 4; $j++)
    {
	$matrices_numbers[$matrix_id][$position_start + $j] = $row[$j] / $sum;
    }

}

my $r = int(rand(100000));
open(TMP, ">tmp_$r");
for (my $i = 0; $i < @matrices; $i++)
{
    print TMP "$matrices_numbers[$i][0]";
    for (my $j = 1; $j < $matrices_lengths[$i]; $j++)
    {
	print TMP "\t$matrices_numbers[$i][$j]";
    }
    print TMP "\n";
}
system("tab2gxw.pl tmp_$r");
system("rm -f tmp_$r");

__DATA__

mutate_gxw.pl

   Given a gxw file, randomly select positions and
   permute the weights at that position.
   Assumes that matrices are A,C,G,T

   -f <str>: gxw file

   -n <num>: Number of different positions to mutate (default: 0)

