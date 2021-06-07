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

my $comparison_file = get_arg("c", "", \%args);

my @comparison_names;
my @comparison_starts;
my @comparison_ends;
my @comparison_direction;
my %comparison_counts;
my %chromosome2id;
my $last_id = 0;

open(COMPARISON_FILE, "<$comparison_file") or die "Could not open comparison file $comparison_file\n";
while(<COMPARISON_FILE>)
{
    chop;

    my @row = split(/\t/);

    my $id = $chromosome2id{$row[0]};
    if (length($id) == 0)
    {
	$chromosome2id{$row[0]} = $last_id;
	$id = $last_id;
	$last_id++;
    }

    if ($row[3] < $row[2])
    {
	my $tmp = $row[3];
	$row[3] = $row[2];
	$row[2] = $tmp;
	$comparison_direction[$id][$comparison_counts{$row[0]}] = "Reverse";
    }
    else
    {
	$comparison_direction[$id][$comparison_counts{$row[0]}] = "Forward";
    }

    $comparison_names[$id][$comparison_counts{$row[0]}] = $row[1];
    $comparison_starts[$id][$comparison_counts{$row[0]}] = $row[2];
    $comparison_ends[$id][$comparison_counts{$row[0]}] = $row[3];
    $comparison_counts{$row[0]}++;

    #print STDERR "$id\t$comparison_counts{$row[0]}\t$_\n";
}

print "Relationship\tDistance\tCmp. name\tCmp. start\tCmp. end\tCmp. Direction\tChr\tName\tStart\tEnd\n";

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $id = $chromosome2id{$row[0]};

  if ($row[3] < $row[2])
  {
      my $tmp = $row[3];
      $row[3] = $row[2];
      $row[2] = $tmp;
  }

  my $relationship = "Outside";

  my $min_distance = 999999999;
  my $comparison_str = "";
  for (my $i = 0; $i < $comparison_counts{$row[0]}; $i++)
  {
      my $comparison_start = $comparison_starts[$id][$i];
      my $comparison_end = $comparison_ends[$id][$i];

      if ($row[2] >= $comparison_start and $row[3] <= $comparison_end)
      {
	  $relationship = "Contained";
	  $min_distance = &Min2($row[2] - $comparison_start, $comparison_end - $row[3]);
	  $comparison_str = "$min_distance\t$comparison_names[$id][$i]\t$comparison_start\t";
	  $comparison_str .="$comparison_end\t$comparison_direction[$id][$i]";
	  last;
      }
      elsif ($row[2] <= $comparison_start and $row[3] >= $comparison_end)
      {
	  $relationship = "Contains";
	  $min_distance = &Min2($comparison_start - $row[2], $row[3] - $comparison_end);
	  $comparison_str = "$min_distance\t$comparison_names[$id][$i]\t$comparison_start\t";
	  $comparison_str .="$comparison_end\t$comparison_direction[$id][$i]";
	  last;
      }
      elsif ($row[2] <= $comparison_end and $row[3] >= $comparison_start)
      {
	  $relationship = "Intersects";
	  $min_distance = &Min4($comparison_start - $row[2],
				$comparison_start - $row[3],
				$comparison_end - $row[2],
				$comparison_end - $row[3]);
	  $comparison_str = "$min_distance\t$comparison_names[$id][$i]\t$comparison_start\t";
	  $comparison_str .="$comparison_end\t$comparison_direction[$id][$i]";
	  last;
      }
      elsif ($row[2] > $comparison_end and $row[2] - $comparison_end < $min_distance)
      {
	  $relationship = "Outside";
	  $min_distance = $row[2] - $comparison_end;
	  $comparison_str = "$min_distance\t$comparison_names[$id][$i]\t$comparison_start\t";
	  $comparison_str .="$comparison_end\t$comparison_direction[$id][$i]";
      }
      elsif ($row[3] < $comparison_start and $comparison_start - $row[3] < $min_distance)
      {
	  $relationship = "Outside";
	  $min_distance = $comparison_start - $row[3];
	  $comparison_str = "$min_distance\t$comparison_names[$id][$i]\t$comparison_start\t";
	  $comparison_str .="$comparison_end\t$comparison_direction[$id][$i]";
      }
  }

  if ($relationship eq "Outside") # Determine the type of 'Outside'
  {
      my $min_left_distance = 9999999;
      my $min_right_distance = 9999999;
      my $left_outside_type = "";
      my $right_outside_type = "";
      for (my $i = 0; $i < $comparison_counts{$row[0]}; $i++)
      {
	  my $comparison_start = $comparison_starts[$id][$i];
	  my $comparison_end = $comparison_ends[$id][$i];

	  if ($row[2] > $comparison_end and $row[2] - $comparison_end < $min_left_distance)
	  {
	      $min_left_distance = $row[2] - $comparison_end;
	      $left_outside_type = $comparison_direction[$id][$i];
	  }
	  elsif ($row[3] < $comparison_start and $comparison_start - $row[3] < $min_right_distance)
	  {
	      $min_right_distance = $comparison_start - $row[3];
	      $right_outside_type = $comparison_direction[$id][$i];
	  }
      }

      if ((length($left_outside_type) == 0 and $right_outside_type eq "Forward") or 
	  (length($right_outside_type) == 0 and $left_outside_type eq "Reverse") or
	  ($left_outside_type eq "Reverse" and $right_outside_type eq "Forward"))
      {
	  $relationship = "Outside 5p";
      }
      elsif ((length($left_outside_type) == 0 and $right_outside_type eq "Reverse") or
	     (length($right_outside_type) == 0 and $left_outside_type eq "Forward") or
	     ($left_outside_type eq "Forward" and $right_outside_type eq "Reverse"))
      {
	  $relationship = "Outside 3p";
      }
      else
      {
	  $relationship = "Outside Mixed";
      }
  }

  print "$relationship\t$comparison_str\t$_\n";
}

sub Min2
{
    my ($num1, $num2) = @_;

    return $num1 < $num2 ? $num1 : $num2;
}

sub Min4
{
    my ($num1, $num2, $num3, $num4) = @_;

    if ($num1 < 0) { $num1 = -$num1; }
    if ($num2 < 0) { $num2 = -$num2; }
    if ($num3 < 0) { $num3 = -$num3; }
    if ($num4 < 0) { $num4 = -$num4; }

    return &Min2(&Min2($num1, $num2), &Min2($num3, $num4));
}

__DATA__

compare_genomic_locations.pl <file>

   Takes in a genomic location file in the format <chr>\t<name>\t<start>\t<end>
   and compares it against another genomic location file, where the comparison
   specifies the relationship (Contains/Contained/Intersects/Outside) between each feature
   and the closest location in the comparison file

   -c <str>: Comparison file (format: <chr>\t<name>\t<start>\t<end>)

