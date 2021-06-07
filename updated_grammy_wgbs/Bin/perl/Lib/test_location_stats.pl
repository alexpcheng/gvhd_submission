#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $locations_file = get_arg("locfile", "", \%args);
my $background_locations_file = get_arg("backfile", "", \%args);
my $stats_file = get_arg("statsfile", "", \%args);
my $add_begin = get_arg("b", 0, \%args);
my $add_end = get_arg("e", 0, \%args);
my $max_length = get_arg("l", 0, \%args);
my $locations_results_file = get_arg("outloc", "", \%args);
my $aligned_file = get_arg("outaln", "", \%args);
my $background_results_file = get_arg("outback", "", \%args);
my $signal_results_file = get_arg("outsig", "", \%args);
my $graph = get_arg("graph", "", \%args);
my $randomizations = get_arg("r", 0, \%args);
my $min_coverage = get_arg("cov", 0, \%args);
my $test_division = get_arg("div", 0, \%args);

my $id=int(rand(100000000));

if ($locations_file eq "") { die "locations input file required!\n" }
if ($stats_file eq "") { die "statistics input file required!\n" }
if ($randomizations and ($background_locations_file eq "")) { die "background locations input file required!\n" }

if ($locations_results_file eq "") { $locations_results_file="tmp_locations_results_file_$id" }
if ($randomizations and ($background_results_file eq "")) { $background_results_file="tmp_background_results_file_$id" }
if ($randomizations and ($signal_results_file eq "")) { $signal_results_file="tmp_signal_results_file_$id" }
if ($aligned_file eq ""){ $aligned_file="tmp_aligned_file_$id" }

my $stats="-m -std";

my $resize_string = "perl -e '".'while(<>){chomp;@row=split/\t/;if($row[2]<$row[3]){$row[2]-='.$add_begin.';$row[3]+='.$add_end.';$forward=1}else{$row[2]+='.$add_begin.';$row[3]-='.$add_end.';$forward=0}if('.$max_length.'>0){$length_overflow=(abs($row[2]-$row[3])+1)-'.$max_length.';if ($length_overflow>0 and $forward){$row[3]-=$length_overflow}if ($length_overflow>0 and $forward==0){$row[3]+=$length_overflow}}print join("\t",@row),"\n";}'."'";


sys("cut.pl -f 1,2,3,4 < $locations_file | $resize_string | sort.pl -c0 0 -c1 2,3 -n0 -n1 -op1 min | compute_location_stats.pl -f $stats_file -s Boolean -c | add_column.pl -u 2,3 | modify_column.pl -c 7 -ab | modify_column.pl -c 7 -a 1 | modify_column.pl -c 7 -m $min_coverage | filter.pl -c 6 -min -u 7 | cut.pl -f 1,2,3,4 | sort.pl -c0 0 -c1 2,3 -n0 -n1 -op1 min > tmp_relevant_locations_file_$id");


(my $num_locations)=(sys("wc -l tmp_relevant_locations_file_$id")=~/(\d+)/);

sys("compute_location_centered_sliding_window_stats.pl -f $stats_file -of tab -c 5 -numeric < tmp_relevant_locations_file_$id > $aligned_file");
sys("compute_column_stats.pl $stats < $aligned_file | sort.pl -c0 0 -skip 1 | transpose.pl | add_column.pl -b -n | cut.pl -f 2 -i | modify_column.pl -c 0 -set 'Stats' -estr 0 | modify_column.pl -c 0 -skip 1 -s ".($add_begin+1)." > $locations_results_file");
sys("rm tmp_relevant_locations_file_$id");
if ($aligned_file eq "tmp_aligned_file_$id"){ sys("rm tmp_aligned_file_$id"); }

if ($graph ne ""){
  sys("make_gnuplot_graph.pl $locations_results_file -png -ds linespoint -o tmp_graph1_$id -t 'statistics on $num_locations locations' -x1 1 -y1 2 -e1 3 -k1 'Std Dev' -x2 1 -y2 2 -k2 'Mean' -lw2 4");
}


if ($randomizations){

  #randomizations
  sys("cut.pl -f 1,2,3,4 < $background_locations_file | $resize_string | sort.pl -c0 0 -c1 2,3 -n0 -n1 -op1 min | compute_location_stats.pl -f $stats_file -s Boolean -c | add_column.pl -u 2,3 | modify_column.pl -c 7 -ab | modify_column.pl -c 7 -a 1 | modify_column.pl -c 7 -m $min_coverage | filter.pl -c 6 -min -u 7 | cut.pl -f 1,2,3,4 | sort.pl -c0 0 -c1 2,3 -n0 -n1 -op1 min > tmp_relevant_background_locations_file_$id");

  (my $num_background_locations)=(sys("wc -l tmp_relevant_background_locations_file_$id")=~/(\d+)/);
  my $r=$num_locations;
  if ($num_background_locations<$r){
    $r=$num_background_locations;
  }
  
  sys("rm $background_results_file");
  sys("touch $background_results_file");
  for (my $i=1;$i<=$randomizations;$i++){
    sys("rand_lines.pl -n $r < tmp_relevant_background_locations_file_$id | sort.pl -c0 0 -c1 2,3 -n0 -n1 -op1 min > tmp_background_locations_$id");
    
    sys("compute_location_centered_sliding_window_stats.pl -f $stats_file -of tab -c 5 -numeric < tmp_background_locations_$id | compute_column_stats.pl $stats | sort.pl -c0 0 -skip 1 | transpose.pl | add_column.pl -b -n | cut.pl -f 2 -i | modify_column.pl -c 0 -set 'Stats' -estr 0 | modify_column.pl -c 0 -skip 1 -s ".($add_begin+1)." | join.pl - $background_results_file -o > tmp_background_results_$id.2");
    sys("mv tmp_background_results_$id.2 $background_results_file");
    sys("rm tmp_background_locations_$id");
  }
  sys("rm tmp_relevant_background_locations_file_$id");
  sys("transpose.pl < $background_results_file | compute_column_stats.pl -m -types 0 |  cut.pl -f 1 -i | sort.pl -c0 0 -skip 1 | transpose.pl > tmp_background_stats_$id");

  if ($graph ne ""){
    sys("make_gnuplot_graph.pl tmp_background_stats_$id -png -ds linespoint -o tmp_graph2_$id -t 'mean of $randomizations random samplings of $r out of $num_background_locations background locations' -x1 1 -y1 2 -e1 3 -k1 'Mean std dev' -x2 1 -y2 2 -k2 'Mean mean' -lw2 4");
  }
  sys ("rm tmp_background_stats_$id");

  #signal calculation

  sys("tab2list.pl -nonempty -p < $locations_results_file | cut.pl -f 2,1,3,4 > tmp_locations_results_file_$id.lst");
  sys("transpose.pl < $background_results_file | compute_column_stats.pl -max -types 0 | cut.pl -f 1 -i | tab2list.pl -nonempty -p | join.pl - tmp_locations_results_file_$id.lst -1 1,2 -2 1,2 | modify_column.pl -c 3 -sc 2 | cut.pl -f 1,2,4 | modify_column.pl -c 2 -max 0 -set 0 > tmp_background_max_$id");
  sys("transpose.pl < $background_results_file | compute_column_stats.pl -min -types 0 | cut.pl -f 1 -i | tab2list.pl -nonempty -p | join.pl - tmp_locations_results_file_$id.lst -1 1,2 -2 1,2 | modify_column.pl -c 3 -sc 2 | cut.pl -f 1,2,4 | modify_column.pl -c 2 -min 0 -set 0 > tmp_background_min_$id");
  sys("join.pl tmp_background_min_$id tmp_background_max_$id -1 1,2 -2 1,2 | modify_column.pl -c 2 -ac 3 | cut.pl -f 1,2,3 | list2tab.pl -V 2 | sort.pl -c0 0 -skip 1 | transpose.pl > $signal_results_file");
  sys("rm tmp_background_max_$id tmp_background_min_$id tmp_locations_results_file_$id.lst");


  if ($graph ne ""){
    sys("make_gnuplot_graph.pl $signal_results_file -png -ds linespoint -o tmp_graph3_$id -ep '0*x' -t 'Signal' -x1 1 -y1 3 -k1 'signal(std dev)' -x2 1 -y2 2 -k2 'signal(mean)'");
  }
}

if ($graph ne ""){
  if ($randomizations){
    sys("pngtopnm tmp_graph1_$id > tmp_graph1_$id.pnm");
    sys("pngtopnm tmp_graph2_$id > tmp_graph2_$id.pnm");
    sys("pngtopnm tmp_graph3_$id > tmp_graph3_$id.pnm");
    sys("pnmcat tmp_graph1_$id.pnm tmp_graph2_$id.pnm tmp_graph3_$id.pnm -topbottom > tmp_graph_$id.pnm");
    sys("pnmtopng tmp_graph_$id.pnm > $graph");
    sys("rm tmp_graph1_$id tmp_graph2_$id tmp_graph3_$id tmp_graph1_$id.pnm tmp_graph2_$id.pnm tmp_graph3_$id.pnm tmp_graph_$id.pnm");
  }
  else{
    sys("mv tmp_graph1_$id $graph");
  }
}

if ($locations_results_file eq "tmp_locations_results_file_$id"){ sys("rm tmp_locations_results_file_$id"); }
if ($background_locations_file eq "tmp_background_locations_file_$id"){ sys("rm tmp_background_locations_file_$id"); }
if ($signal_results_file eq "tmp_signal_results_file_$id"){ sys("rm tmp_signal_results_file_$id"); }


sub sys{
    my $run=shift;
    print "Running: $run\n";
    return `$run`;
}


__DATA__


test_location_stats.pl

  calculates statistics on locations vs random samplings from background locations.
  produces text and graphical output.

  NOTE: assumes stats file is sorted (numerically by 1st column, and numerically by min of 3rd and 4th).

  parameters:

  -locfile <string>:     input file that has locations (chr format). required.
  -statsfile <string>:   input file that has statistics (chr format, sorted). required.
  -backfile <string>:    input file that has background locations (chr format).
  -r <num>:              number of random samplings to perform (default 0)
  -b <num>:              number of basepairs to add to the beginning of each location (default 0)
  -e <num>:              number of basepairs to add to the end of each location (default 0)
  -l <num>:              maximal length of location that is allowed. if location is longer (after adding
                         according to -b and -e), location is trimmed from the end.
  -graph <string>:       output graphical file (png format). outputs a graph for the calculations on the
                         locations, on the background locations, and of the signal (3 concatenated
                         graphs).
  -cov <num>:            minimal fraction of positions that have to be covered by a statistic in
                         order to have that position considered
  -outloc <string>:      name of output file that gives the calculations on the locations
  -outaln <string>:      name of output file that gives the aligned locations with their stats
                         (for clustering, etc)
  -outback <string>:     name of output file that gives the means of the calculations on the background
                         locations
  -outsig <string>:      name of output file that gives the signal.
                         define v as the calculated value in position i on the input locations;
                         define t as max(value in position i) on the random samplings;
                         define b as min(value in position i) on the random samplings; then:
                               {  v>t:         v-t
                         sig = {  v<b:         b-v
			       {  otherwise:   0


