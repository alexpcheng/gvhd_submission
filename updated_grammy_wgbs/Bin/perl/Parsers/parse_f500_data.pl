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

my $normalize_time = &get_arg("norm_time", 1, \%args);
my $delta_track = &get_arg("delta", "", \%args);
my $over_track = &get_arg("over", "", \%args);
my $plate_layout_file = &get_arg("p", "", \%args);

my @labels;
my %labels_to_ids;
my $current_label_id = -1;

my @cycles;
my @num_cycles;
my @current_cycles;
my %cycles_with_data;

my %labels_times;
my %labels_temps;
my %labels_data;

my @labels_data_types;
my %labels_data_types_hash;

my $times_exist = 0;
my $temps_exist = 0;

my %plate_id_to_name;
if (length($plate_layout_file) > 0)
{
  open(PLATE, "<$plate_layout_file");
  while(<PLATE>)
  {
    chomp;

    my @row = split(/\t/);

    $plate_id_to_name{$row[0]} = $row[1];
  }
}

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

  # print STDERR "Row: @row\n";

  if ($row[0] eq "Mode")
  {
    $row[4] =~ s/ /_/g;
    $row[4] = lc $row[4];

    # print STDERR "Found the Mode $row[4]\n";

    my $num_labels = @labels;
    push(@labels, $row[4]);

    $labels_to_ids{$row[4]} = $num_labels;

    print "label$num_labels\t$row[4]\n";
  }

  if ($row[0] =~ /^Label([0-9]+)/)
  {
    $current_label_id = $1 - 1;

    #print STDERR "Processing data from label Label$current_label_id = '$labels[$current_label_id]'\n";
  }

  if ($row[0] =~ /^Cycle Nr/)
  {
    #print STDERR "Processing cycles '$row[0]' from label Label$current_label_id = '$labels[$current_label_id]'\n";
    @current_cycles = split(/\t/);
    for (my $i = 1; $i < @row; $i++)
    {
      $cycles[$current_label_id][$num_cycles[$current_label_id]] = $row[$i];
      $num_cycles[$current_label_id]++;
    }
  }

  if ($row[0] =~ /^Time/)
  {
    #print STDERR "Processing times '$row[0]' from label Label$current_label_id = '$labels[$current_label_id]'\n";
    $times_exist = 1;
    for (my $i = 1; $i < @row; $i++)
    {
      #print STDERR "TIMES labels_times{$current_label_id}{$current_cycles[$i]}=$row[$i]\n";
      $labels_times{$current_label_id}{$current_cycles[$i]} = &format_number($row[$i] / $normalize_time, 3);

      $cycles_with_data{$current_cycles[$i]} = 1;
    }
  }

  if ($row[0] =~ /^Temp/)
  {
    #print STDERR "Processing temps '$row[0]' from label Label$current_label_id = '$labels[$current_label_id]'\n";
    $temps_exist = 1;
    for (my $i = 1; $i < @row; $i++)
    {
      $labels_temps{$current_label_id}{$current_cycles[$i]} = $row[$i];

      $cycles_with_data{$current_cycles[$i]} = 1;
    }
  }

  if ($row[0] =~ /^[A-H][0-9]/)
  {
    $row[0] = length($plate_id_to_name{$row[0]}) > 0 ? $plate_id_to_name{$row[0]} : $row[0];

    #print STDERR "Processing data '$row[0]' from label Label$current_label_id = '$labels[$current_label_id]'\n";

    if (length($labels_data_types_hash{$row[0]}) == 0)
    {
      push(@labels_data_types, $row[0]);
      $labels_data_types_hash{$row[0]} = 1;
    }

    for (my $i = 1; $i < @row; $i++)
    {
      $labels_data{$current_label_id}{$row[0]}{$current_cycles[$i]} = $row[$i];

      $cycles_with_data{$current_cycles[$i]} = 1;
    }
  }
}

for (my $i = 0; $i < @labels; $i++)
{
  open(OUTPUT, ">$labels[$i].tab");

  &PrintHeader();

  for (my $j = 0; $j < $num_cycles[$i]; $j++)
  {
    my $cycle_id = $cycles[$i][$j];

    if ($cycles_with_data{$cycle_id} == 1)
    {
      print OUTPUT "$cycle_id";

      if ($times_exist == 1)
      {
	print OUTPUT "\t$labels_times{$i}{$cycle_id}";
      }

      if ($temps_exist == 1)
      {
	print OUTPUT "\t$labels_temps{$i}{$cycle_id}";
      }

      for (my $k = 0; $k < @labels_data_types; $k++)
      {
	print OUTPUT "\t$labels_data{$i}{$labels_data_types[$k]}{$cycle_id}";
      }

      print OUTPUT "\n";
    }
  }

  close(OUTPUT);
}

&create_difference_tracks($delta_track, "Delta");
&create_difference_tracks($over_track, "Over");

sub create_difference_tracks
{
  my ($labels_str, $action) = @_;

  if (length($labels_str) > 0)
  {
    my @label_names = split(/\,/, $labels_str);
    my $first_label_id = $labels_to_ids{$label_names[0]};
    my $second_label_id = $labels_to_ids{$label_names[1]};

    if (length($first_label_id) == 0 or length($second_label_id) == 0)
    {
      print STDERR "Could not find one of the two specified labels: $labels_str\n";

      exit;
    }

    print STDERR "CreateDifferenceTracks: Labels=$labels_str Action=$action FirstLabelID=$first_label_id SecondLabelID=$second_label_id\n";

    my $file_name;
    if ($action eq "Delta") { $file_name = "delta_$label_names[0]_by_$label_names[1]"; }
    elsif ($action eq "Over") { $file_name = "$label_names[0]_by_$label_names[1]"; }
    open(OUTPUT, ">$file_name.tab");

    &PrintHeader();

    my $start_index;
    if ($action eq "Delta") { $start_index = 1; }
    elsif ($action eq "Over") { $start_index = 0; }

    for (my $i = $start_index; $i < $num_cycles[$first_label_id]; $i++)
    {
      my $cycle_id = $cycles[$first_label_id][$i];

      if ($cycles_with_data{$cycle_id} == 1)
      {
	print OUTPUT "$cycle_id";

	if ($times_exist == 1)
	{
	  print OUTPUT "\t$labels_times{$first_label_id}{$cycle_id}";
	}

	if ($temps_exist == 1)
	{
	  print OUTPUT "\t$labels_temps{$first_label_id}{$cycle_id}";
	}

	for (my $j = 0; $j < @labels_data_types; $j++)
	{
	  if ($action eq "Over")
	  {
	    my $n1 = $labels_data{$first_label_id}{$labels_data_types[$j]}{$cycle_id};
	    my $m1 = $labels_data{$second_label_id}{$labels_data_types[$j]}{$cycle_id};

	    if (length($m1) > 0)
	    {
	      print OUTPUT "\t" . &format_number($n1 / $m1, 3);
	    }
	    else
	    {
	      print OUTPUT "\t";
	    }
	  }
	  elsif ($action eq "Delta")
	  {
	    my $prev_cycle_id = $cycles[$first_label_id][$i - 1];
	    my $n1 = $labels_data{$first_label_id}{$labels_data_types[$j]}{$cycle_id};
	    my $n0 = $labels_data{$first_label_id}{$labels_data_types[$j]}{$prev_cycle_id};
	    my $m1 = $labels_data{$second_label_id}{$labels_data_types[$j]}{$cycle_id};
	    my $m0 = $labels_data{$second_label_id}{$labels_data_types[$j]}{$prev_cycle_id};

	    if (length($m1) > 0 and length($m0) > 0)
	    {
	      print OUTPUT "\t" . &format_number(($n1 - $n0) / (($m1 + $m0) / 2), 3);
	    }
	    else
	    {
	      print OUTPUT "\t";
	    }
	  }
	}

	print OUTPUT "\n";
      }
    }

    close(OUTPUT);
  }
}

sub PrintHeader
{
  print OUTPUT "Cycles";
  if ($times_exist == 1) { print OUTPUT "\tTime"; }
  if ($temps_exist == 1) { print OUTPUT "\tTemp"; }
  for (my $i = 0; $i < @labels_data_types; $i++)
  {
    print OUTPUT "\t$labels_data_types[$i]";
  }
  print OUTPUT "\n";
}

__DATA__

parse_f500_data.pl <file>

   Parse a file from F500.

   -norm_time <num>:       Normalize the time by dividing by num (e.g., divide sec by 60 to min.)

   -delta <label1,label2>: Create a file of delta of two consecutive points from label1,
                           divided by the average of two consecutive points from label2

   -over <label1,label2>:  Create a file of points from label1 divided by the corresponding point from label2

   -p <str>:               File for plate layout in the format <PlateID><tab><Name>

