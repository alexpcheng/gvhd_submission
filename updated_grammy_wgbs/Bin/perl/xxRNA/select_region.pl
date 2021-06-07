#!/usr/bin/perl
use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $header_row = get_arg("h", 0, \%args);
my $sum = get_arg("s", 0, \%args);
my $file = get_arg("o", 0, \%args);

# header row
my %values;
$_ = <STDIN>;
chomp $_;
my @header = split("\t", $_);

if ($header_row and $sum) {
  $values{'sum'} = [];
}
elsif ($header_row) {
  for(my $i = 0; $i < scalar(@header); $i++) {
    $values{$i} = [];
  }
}
elsif ($sum) {
  my $s = 0;
  foreach my $v (@header) { $s += $v }
  $values{'sum'} = [$s];
}
else {
  for(my $i = 0; $i < scalar(@header); $i++) {
    $values{$i} = [$header[$i]];
  }
}

# read input
while (<STDIN>) {
  chomp $_;
  my @l = split("\t", $_);

  if ($sum) {
    my $s = 0;
    foreach my $v (@l) { $s += $v }
    my $ref = $values{'sum'};
    push(@$ref, $s);
  }
  else {
    for(my $i = 0; $i < scalar(@l); $i++) {
      my $ref = $values{$i};
      push(@$ref, $l[$i]);
    }
  }
}

# calculate thresholds and maximal positions
# expand max position until threshold
foreach my $k (keys %values) {
  my $ref = $values{$k};
  my $length = scalar(@$ref);

  open (OFILE, ">tmp_data_$$.tab") or die "Cannot open tmp_data_$$.tab\n";
  my $max = 0;
  my $max_position = 0;
  for(my $i = 0; $i < $length; $i++) {
    my $v = $$ref[$i];
    if ($v == 0) {
      print OFILE "0.0001\n";
    }
    else {
      print OFILE "$v\n";
    }
    if ($v > $max) {
      $max = $v;
      $max_position = $i;
    }
  }
  close (OFILE);

  my $threshold = `vectorstats.pl tmp_data_$$.tab -s 0`;
  if ($threshold > $max) {
    $threshold = $max;
  }
  chomp $threshold;
  unlink("tmp_data_$$.tab");

  my $start = $max_position;
  while ($$ref[$start-1] >= $threshold and $start > 0) {
    $start--;
  }
  my $end = $max_position;
  while ($$ref[$end+1] >= $threshold and $end < $length) {
    $end++;
  }

  my $key = $k;
  if ($sum) {
    $key = 'sum';
  }
  elsif ($header_row) {
    $key = $header[$k];
  }
  print "$key\t$start\t$end\t$threshold\t$max_position\n";

  if ($file) {
    open(OFILE, ">$file.$k") or die "Cannot open $file.$k\n";
    for (my $i = $start; $i <= $end; $i++) {
      print OFILE "$i\t$$ref[$i]\n";
    }
    close(OFILE);
  }
}





# ------------------------------------------------
__DATA__

select_region.pl [options]

Read from STDIN a list of values in the format:
<v11> <v12> ...
<v21> <v22> ...
  :     :

and output for each column the longest segment of significant values.
Output format: [column key] [start row] [end row] [threshold] [max position]
(row numbers are zero-based)

 Options:
   -s         Sum the columns and calculate a single range for the sums.
   -h         Input contains header row
   -o <file>  Print selected region to file
