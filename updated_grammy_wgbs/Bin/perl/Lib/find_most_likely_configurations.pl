#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

#-------------------------------------------------------------------------
# main()
#-------------------------------------------------------------------------

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = &load_args(\@ARGV);

my $input_file = get_arg("i", "", \%args);
die "ERROR - No input file given\n" if ( $input_file eq "" );
die "ERROR - input file '$input_file' not found\n" unless ( -f $input_file );

my $output_file = get_arg("o", "", \%args);
die "ERROR - No output file given\n" if ( $output_file eq "" );

my $regulator_length = get_arg("l", -666.66, \%args);
die "ERROR - regulator length not given\n" if ( $regulator_length == -666.66 );
die "ERROR - regulator length must be positive\n" if ( $regulator_length <= 0 );

my $window = get_arg("w", -666.66, \%args);
die "ERROR - window not given\n" if ( $window == -666.66 );
die "ERROR - window must be positive\n" if ( $window <= 0 );

my $num_regulators = get_arg("n", 2, \%args);
die "ERROR - num of regulators less than 2\n" if ( $num_regulators < 2 );
# FIXME:
die "FIXME - currently supports only 2 regulators in configuration\n" if ( $num_regulators > 2 );

my $func = get_arg("func", "Sum", \%args);
die "ERROR - unkown function type $func\n" unless ( $func eq "Sum" or $func eq "Average" or $func eq "MaxOfMono" or $func eq "MinOfMono" );

my $reg_overlap = get_arg("reg_overlap", 0, \%args);

my $min = get_arg("min", "-inf", \%args);


open(INPUT_FILE,"<$input_file");
open(OUTPUT_FILE,">$output_file");

while (<INPUT_FILE>) {

  my @line = split(/\t/,$_);
  chomp @line;
  my $num_cols = @line;
  die "input file expected to contain 7 columns\n" unless ( $num_cols == 7 );

  my $read_length = $line[3] - $line[2] + 1;

  my @stats_list = split(/;/,$line[6]);
  my $num_stats = @stats_list;
  die "read (with id $line[1]) is $read_length bp long, but num of stats per bp is $num_stats\n" unless ( $read_length == $num_stats );

  my @config_relative_start_positions = ();
  my @config_gaps = ();

  my @score = ();
  if ( $num_regulators == 2 ) {
    @score = FindBestConfigWithTwoRegulators($func, $read_length, $regulator_length, $window, $reg_overlap, \@stats_list, \@config_relative_start_positions, \@config_gaps);
  }
  elsif ( $num_regulators == 3 ) {
    die "FIXME - currently supports only 2 regulators in configuration\n";
  }

  my $num_regs_in_best_config = @config_relative_start_positions;
  die "FIXME - ERROR - best config contains $num_regs_in_best_config regulators instead of the required $num_regulators\n" unless ( $num_regs_in_best_config == $num_regulators );
  my $num_config_gaps = @config_gaps;
  my $expected_num_config_gaps = $num_regulators - 1;
  die "FIXME - ERROR - num_config_gaps ($num_config_gaps) should be $expected_num_config_gaps\n" unless ( $num_config_gaps == $expected_num_config_gaps );

  next if ( $min ne "-inf" and $score[0] < $min );

  print OUTPUT_FILE "$line[0]\t$line[1]\t$line[2]\t$line[3]\t$line[4]\t$line[5]\t";
  printf OUTPUT_FILE "%d",$config_relative_start_positions[0] + $line[2];
  for ( my $i=1 ; $i < $num_regulators ; $i++ ) {
    printf OUTPUT_FILE ";%d",$config_relative_start_positions[$i] + $line[2];
  }
  printf OUTPUT_FILE "\t%d",$config_gaps[0];
  for ( my $i=1 ; $i < $num_config_gaps ; $i++ ) {
    printf OUTPUT_FILE ";%d",$config_gaps[$i];
  }
  print OUTPUT_FILE "\n";

}

close INPUT_FILE;
close OUTPUT_FILE;


#
# End of main()
#



#-------------------------------------------------------------------------
# sub FindBestConfigWithTwoRegulators
#-------------------------------------------------------------------------
sub FindBestConfigWithTwoRegulators
{
  my ($func, $read_length, $regulator_length, $window, $reg_overlap, $stats_list_ref, $relative_start_positions_ref, $gaps_ref) = @_;

  my @best_config_score = ();
  my @best_config_start_positions = ();
  my $best_config_gap_between_regulators = -1;

  my $is_first = 1;

  # all positions are relative to the read
  for ( my $start_pos_of_first_reg=0 ; $start_pos_of_first_reg <= $window ; $start_pos_of_first_reg++ ) {
    my $last_start_pos_of_last_reg = $read_length - $regulator_length ;

    my $first_pos_after_first_reg = $start_pos_of_first_reg + $regulator_length ;
    last if ( (not $reg_overlap) and $first_pos_after_first_reg >= $last_start_pos_of_last_reg );

    my $first_allowed_start_pos_of_last_reg = $last_start_pos_of_last_reg - $window ;

    if ( (not $reg_overlap) and $first_pos_after_first_reg > $first_allowed_start_pos_of_last_reg ) {
      $first_allowed_start_pos_of_last_reg = $first_pos_after_first_reg;
    }

    for ( my $start_pos_of_last_reg=$first_allowed_start_pos_of_last_reg ; $start_pos_of_last_reg <= $last_start_pos_of_last_reg ; $start_pos_of_last_reg++ ) {
      my @curr_stats = ( $stats_list_ref->[$start_pos_of_first_reg], $stats_list_ref->[$start_pos_of_last_reg] );
      my @curr_score = CalcConfigurationScore(\@curr_stats, $func);

      my $curr_is_best = 0;

      if ( $is_first ) {
	$is_first = 0;
	$curr_is_best = 1;
      }
      else {
	my $num_score_elems = @curr_score;
	for ( my $i=0 ; $i < $num_score_elems ; $i++ ) {
	  last if ( $curr_score[$i] < $best_config_score[$i] );
	  next if ( $curr_score[$i] == $best_config_score[$i] );
	  $curr_is_best = 1;
	}
      }

      if ( $curr_is_best ) {
	@best_config_score = @curr_score;
	@best_config_start_positions = ($start_pos_of_first_reg, $start_pos_of_last_reg);
	$best_config_gap_between_regulators = $start_pos_of_last_reg - $first_pos_after_first_reg;
      }

    }
  }

  push(@$relative_start_positions_ref, $best_config_start_positions[0]);
  push(@$relative_start_positions_ref, $best_config_start_positions[1]);
  push(@$gaps_ref, $best_config_gap_between_regulators);

  return @best_config_score;
}


#-------------------------------------------------------------------------
# sub CalcConfigurationScore
#
# Note that a list is returned
#-------------------------------------------------------------------------
sub CalcConfigurationScore
{
  my ($stats_ref, $func) = @_;

  my @stats = @$stats_ref;
  my $num_stats = @stats;

  if ( $func eq "Sum" ) {
    my $sum = 0;
    for ( my $i=0 ; $i < $num_stats ; $i++ ) {
      $sum = $sum + $stats[$i];
    }
    return ($sum);
  }

  elsif ( $func eq "MaxOfMono" ) {
    return sort { $b <=> $a } @stats;
  }

  elsif ( $func eq "MinOfMono" ) {
    return sort { $a <=> $b } @stats;
  }
}


#
# End of all subroutines
#


__DATA__

find_most_likely_configuration.pl

  Usage: find_most_likely_configuration.pl -i <input_file> -o <output_file> -l <regulator_length> -w <window_length> [other options]

  Given as input a tab delimited file, consisting of 7 columns:
  Chromosome_Name  Read_Id  Read_Start  Read_End  Feature_Type  Feature_Stats  List_Of_Stats_Per_Read_Pos.

  Notice that the first 6 columns make a standard chr file. These chr columns describe the reads.
  (the Feature_Type is not realy important, and the Feature_Stats may, for instance, detail the number
  of times the read appear in the data).
  The last column contains a semi-colon (;) delimited list of doubles, that is expected to be of exact
  same length as the read. The i-th value in the list corresponds to a regulator (TF / nucleosome / etc.)
  statistic on that position (such as statistical weight if is to start at that position).

  The output file will be tab delimited, consisting of 8 columns.
  The first 6 will simply contain the input chr data, as detailed above.
  The 7-th column will contain a semi-colon (;) seperated ordered list of the chosen configuration's
  regulator starting positions (the absolut positions within the chromosome).
  The 8-th column will contain a semi-colon (;) seperated ordered list of the gaps between each two
  neighboring regulators in the chosen configuration.

  Parameters:
  -----------
  -i <str>:           input data file (described above).
  -o <str>:           output file name.
  -l <int>:           length of regulator for which the stats list is given.
  -w <int>:           length of window that determines the maximum allowed length for an uncovered read edge.
                      for instance, given a value of 2, and looking at the right read edge, the following three
                      cases are allowed ('x' stands for uncovered position, R stands for a covered position):
                      { ...xxxxxRRRR , ...xxxxRRRRx , ...xxxRRRRxx } , while ...xxRRRRxxx is not allowed.

  -n <int>:           num of regulators to be placed (2/3, default: 2).
  -func <str>:        type of function to be used in order to determine configuration score, given the scores for
                      the placed regulators under that configuration.
                      one of: Sum/MaxOfMono/MinOfMono (default: Sum).
  -reg_overlap:       allow configurations where regulators overlap.
  -min <double>:      minimal score threshold. if, for a given read, no configuration gets a score better than 'min',
                      then the read will be ignored, and no output will be printed for it.

