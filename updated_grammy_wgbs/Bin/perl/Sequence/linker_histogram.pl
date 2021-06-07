#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = &load_args(\@ARGV);

my $plus_strand_reads_file = get_arg("p", "", \%args);
die "ERROR - No plus strand nucleosome reads file given\n" if ( $plus_strand_reads_file eq "" );
die "ERROR - Plus strand nucleosome reads file '$plus_strand_reads_file' not found\n" unless ( -f $plus_strand_reads_file );

my $minus_strand_reads_file = get_arg("m", "", \%args);
#die "ERROR - No minus strand nucleosome reads file given\n" if ( $minus_strand_reads_file eq "" );
die "ERROR - Minus strand nucleosome reads file '$minus_strand_reads_file' not found\n" if ( $minus_strand_reads_file ne "" and not(-f $minus_strand_reads_file) );

my $window = get_arg("w", 1000, \%args);
die "ERROR - Window length is not positive\n" if ( $window <= 0 );
die "ERROR - window value not properly given\n" if ( $window eq "" );
print STDERR "WARNING - Small window length\n" if ( $window < 50 );

my $histogram_output_file = get_arg("o", "linker_histogram.tab", \%args);


# Unique read start positions will be read into the following two vectors:
my @minus_strand_starts = ();
my @plus_strand_starts = ();

# The following vector will map each minus strand start to the first plus strand start that is greater or equal to it:
my @minus_start_index_2_plus_start_index = ();

# The linker lengths histogram array:
my @histogram = ();
for ( my $i=0 ; $i <= $window ; $i++ ) {
  push (@histogram, 0);
}


# getting unique minus strand start positions (from file, if given):

my $last_inserted = -1;
unless ( $minus_strand_reads_file eq "" ) {
  open(MINUS_FILE,"<$minus_strand_reads_file");
  while (<MINUS_FILE>) {
    my @line = split(/\t/,$_);
    next if ( $line[0] == $last_inserted );
    push(@minus_strand_starts, $line[0]);
    $last_inserted = $line[0];
  }
  close MINUS_FILE;
}


# getting unique plus strand start positions:

open(PLUS_FILE,"<$plus_strand_reads_file");
$last_inserted = -1;
while (<PLUS_FILE>) {
  my @line = split(/\t/,$_);
  next if ( $line[0] == $last_inserted );
  push(@plus_strand_starts, $line[0]);

  if ( $minus_strand_reads_file eq "" ) {
    my $num_line_elems = @line;
    die "ERROR - when minus strand reads file not given then plus strand reads expected to contain end positions as well\n" if ( $num_line_elems < 2 );
    push(@minus_strand_starts, $line[1]);
  }

  $last_inserted = $line[0];
}
close PLUS_FILE;


# mapping minus strand start pos to first relevant plus strat pos:

my $curr_plus_strand_index = 0;
my $num_plus = @plus_strand_starts;
foreach my $minus_strand_start (@minus_strand_starts) {
  while ( $curr_plus_strand_index < $num_plus and $plus_strand_starts[$curr_plus_strand_index] <= $minus_strand_start ) {
    $curr_plus_strand_index++;
  }
  last unless ( $curr_plus_strand_index < $num_plus );
  push (@minus_start_index_2_plus_start_index, $curr_plus_strand_index);
}

#print "@minus_strand_starts \n";
#print "@plus_strand_starts \n";
#print "@minus_start_index_2_plus_start_index \n";


# generating the histogram:

my $num_minus_to_include = @minus_start_index_2_plus_start_index;
for ( my $minus_index = 0 ; $minus_index < $num_minus_to_include ; $minus_index++ ) {
  my $curr_minus_start_pos = $minus_strand_starts[$minus_index];
  my $plus_index = $minus_start_index_2_plus_start_index[$minus_index];

  my $curr_linker_length = $plus_strand_starts[$plus_index] - $curr_minus_start_pos - 1;

  # assertion:
  die "ERROR - negative linker length. 'minus_start_index_2_plus_start_index' array probably not ok\n" if ( $curr_linker_length < 0 );

  while ( $curr_linker_length <= $window ) {
    $histogram[$curr_linker_length]++;
    $plus_index++;
    last if ( $plus_index == $num_plus );
    $curr_linker_length = $plus_strand_starts[$plus_index] - $curr_minus_start_pos - 1;
  }
}


# output histogram to file:

open(HIST, ">$histogram_output_file");
for ( my $i=0 ; $i <= $window ; $i++ ) {
  print HIST "$i\t$histogram[$i]\n";
}
close HIST;


########## The End #################

__DATA__

linker_histogram.pl

Usage:

linker_histogram.pl -p <plus strand nucleosome reads file> [-m <minus strand nucleosome reads file>] [other options]

