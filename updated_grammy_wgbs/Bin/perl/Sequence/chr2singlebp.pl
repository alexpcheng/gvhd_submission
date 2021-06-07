#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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
my $singlebp_at_start = get_arg("s", 0, \%args);
my $singlebp_at_center = get_arg("c", 0, \%args);
my $singlebp_at_end = get_arg("e", 0, \%args);
my $singlebp_at_all = get_arg("a",0,\%args);
my $no_direction = get_arg("no_direction", 0, \%args);

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/, $_, 5);

  my $left = $row[2] < $row[3] ? $row[2] : $row[3];
  my $right = $row[2] < $row[3] ? $row[3] : $row[2];

  if ($singlebp_at_start == 1)
  {
    my $end_location;
    if ($no_direction == 1)
    {
      $end_location = $row[2];
    }
    elsif ($row[2] < $row[3])
    {
      $end_location = $row[2] + 1;
    }
    else
    {
      $end_location = $row[2] - 1;
    }

    print "$row[0]\t$row[1]\t$row[2]\t$end_location";
    if (length($row[4]) > 0) { print "\t$row[4]"; }
    print "\n";
  }

  if ($singlebp_at_center == 1)
  {
    my $start_location = int(($row[2] + $row[3]) / 2);
    my $end_location = $start_location + ($no_direction == 1 ? 0 : 1);

    if ($row[2] > $row[3])
    {
      my $temp = $end_location;
      $end_location = $start_location;
      $start_location = $temp;
    }

    print "$row[0]\t$row[1]\t$start_location\t$end_location";
    if (length($row[4]) > 0) { print "\t$row[4]"; }
    print "\n";
  }

  if ($singlebp_at_end == 1)
  {
    my $start_location;
    if ($no_direction == 1)
    {
      $start_location = $row[3];
    }
    elsif ($row[2] < $row[3])
    {
      $start_location = $row[3] - 1;
    }
    else
    {
      $start_location = $row[3] + 1;
    }

    print "$row[0]\t$row[1]\t$start_location\t$row[3]";
    if (length($row[4]) > 0) { print "\t$row[4]"; }
    print "\n";
  }

  if ($singlebp_at_all == 1)
  {
    if($row[2]<$row[3]){
      for (my $i=$row[2];$i<($row[3]+$no_direction);$i++){
	print "$row[0]\t$row[1]\t$i\t",$i+(1-$no_direction);
	if (length($row[4]) > 0) { print "\t$row[4]"; }
	print "\n";
      }
    }
    else{
      for (my $i=$row[2];$i>($row[3]-$no_direction);$i--){
	print "$row[0]\t$row[1]\t$i\t",$i+($no_direction-1);
	if (length($row[4]) > 0) { print "\t$row[4]"; }
	print "\n";
      }
    }
  }
}

__DATA__

chr2singlebp.pl <file>

   Convert a chr file to a chr with a single bp at the start and/or end of each location

   -s:            Create a single bp at the start of each location
   -c:            Create a single bp at the center of each location
   -e:            Create a single bp at the end of each location
   -a:            Create a single bp at all positions of each location

   -no_direction: Create the single bp without direction (start=end)

