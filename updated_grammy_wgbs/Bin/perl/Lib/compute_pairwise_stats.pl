#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/vector_ops.pl";
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

my $pairs_file = get_arg("p", "", \%args);
my $print_number = get_arg("n", 0, \%args);
my $print_empty = get_arg("e", 0, \%args);
my $empty_values = get_arg("ev", 0, \%args);
my $print_all_pairs = get_arg("all", 0, \%args);
my $vector_score = get_arg("s", "pearson", \%args);
my $partial_correlation_row = get_arg("partial_row", "", \%args);
my $kl_variable_dimension = get_arg("kl", 4, \%args);
my $offset_str = get_arg("offset", "0,0,1", \%args);
my $offset_name = get_arg("offset_name", "", \%args);
my $num_simulations = get_arg("sim", 0, \%args);
my $skip_lines = get_arg("skip", 0, \%args);
my $precision = get_arg("precision", 3, \%args);
my $two_sided = get_arg("two", 0, \%args);
my $one_against_all = get_arg("o", "", \%args);
my @offset = split(/\,/, $offset_str);
my $sectorsfile = get_arg("sf", "", \%args);
my $quiet = get_arg("q", 0, \%args);

my @sectors;
if ($sectorsfile ne ""){
  open (SFILE,$sectorsfile);
  while(<SFILE>){
    my %sec;
    ($sec{start},$sec{end})=split/\t/,$_,-1;
    push @sectors,\%sec;
  }
  close (SFILE);
}

my %rows;
my $num = 0;
my $lastrow;
for (my $i = 0; $i < $skip_lines; $i++) { my $line = <$file_ref>; }
while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/, $_, 2);

  if ($num % 1000 == 0 && $quiet == 0) { print STDERR "Loading row $num...\n"; }
  $num++;

  #print STDERR "rows{$row[0]} = $row[1]\n";
  $rows{$row[0]} = $row[1];
  $lastrow=$row[0];
}
if ($quiet == 0)
{
   print STDERR "Done loading.\n";
}

my $partial_correlation_row_data;
if ($vector_score eq "partial"){
  if ($partial_correlation_row eq ""){ $partial_correlation_row=$lastrow }
  if (!exists $rows{$partial_correlation_row}) {die "can't find partial correlation control row \"$partial_correlation_row\" !\n"}
  $partial_correlation_row_data=$rows{$partial_correlation_row};
  delete $rows{$partial_correlation_row} ;
}

if ($print_all_pairs == 1)
{
  foreach my $row1 (keys %rows)
  {
    foreach my $row2 (keys %rows)
    {
      if (($row1 cmp $row2) < 0)
      {
	&ComputePairwiseStats($row1, $row2);
      }
    }
  }
}
elsif ($one_against_all ne ""){
    foreach my $row (keys %rows){
	if ($row ne $one_against_all)
	{
	    &ComputePairwiseStats($one_against_all, $row);
	}
    }
}
else
{
  open(FILE2, "<$pairs_file");
  while(<FILE2>)
  {
    chop;

    my @row = split(/\t/,$_,-1);
    
    &ComputePairwiseStats($row[0], $row[1]);
  }
}


sub ComputePairwiseStats
  {
    my ($key1, $key2) = @_;
    
    if (length($rows{$key1}) > 0 and length($rows{$key2}) > 0){
      my @row1 = split(/\t/, $rows{$key1},-1);
      my @row2 = split(/\t/, $rows{$key2},-1);
      
      if (scalar(@sectors)<1){
	$sectors[0]{start}=0;
	$sectors[0]{end}=$#row1>$#row2?$#row1:$#row2;
      }
      
      for (my $i = $offset[0]; $i <= $offset[1]; $i += $offset[2]){
	my @offset_row1 = ();
	my @offset_row2 = ();
	
	for my $sec_ref (@sectors){
	  my %sec=%{$sec_ref};
	  for (my $j=$sec{start};$j<=$sec{end};$j++){
	    if (
		($j+$i)>=$sec{start} and ($j+$i)<=$sec{end} and
		($j+$i)<scalar(@row1) and ($j+$i)<scalar(@row2) and
		$j>=$sec{start} and $j<=$sec{end} and
		$j<scalar(@row1) and $j<scalar(@row2)
	       ){
	      push @offset_row1, $row1[$j];
	      push @offset_row2, $row2[$j+$i];
	    }
	  }
	}

	(my $stats,my $number_instances) = &ComputeStats(\@offset_row1, \@offset_row2);
	if (length($offset_name) > 0)
	  {
	    print "$key1\t$key2\t$stats\t$offset_name";
	  }
	else
	  {
	    print "$key1\t$key2\t$stats\t$i";
	  }

	  if ($num_simulations > 0)
	  {
	    my $worse_than_simulations = 0;	
	    my $greater_than_simulations = 0;
	    my $lesser_than_simulations = 0;
	    my $simulations_sum = 0;
	    for (my $i = 0; $i < $num_simulations; $i++)
	    {
	      my @permuted_row1 = &vec_permute(\@offset_row1);
	      my @permuted_row2 = &vec_permute(\@offset_row2);

	      (my $simulation_stats,my $dummy) = &ComputeStats(\@permuted_row1, \@permuted_row2);
	      $simulations_sum += $simulation_stats;
	      #print "\nSTATS=$simulation_stats\t$permuted_row1[1]\t$permuted_row1[2]\n";
	      if ($two_sided){
		  if ($simulation_stats <= $stats)
		  {
		      $greater_than_simulations++;
		  }
		  if ($simulation_stats >= $stats)
		  {
		      $lesser_than_simulations++;
		  }
		  
	      }
	      else{
		  if ($simulation_stats >= $stats)
		  {
		      $worse_than_simulations++;
		  }
	      }
	      
	    }
	    if ($two_sided){
		if ($greater_than_simulations>$lesser_than_simulations){
		    $worse_than_simulations=$lesser_than_simulations;
		    }
		else{
		    $worse_than_simulations=$greater_than_simulations;
		}
	    }
	    print "\t$worse_than_simulations\t$num_simulations\t";
	    print &format_number($worse_than_simulations / $num_simulations, $precision);
	    print "\t";
	    print &format_number($simulations_sum / $num_simulations, $precision);
	  }
	if ($print_number) {print "\t$number_instances"}
	print "\n";
	}
    }
    elsif ($print_empty == 1)
    {
	print "$key1\t$key2\t\n";
    }
}

sub ComputeStats (\@\@)
{
    my ($row1_str, $row2_str) = @_;

    my @row1 = @{$row1_str};
    my @row2 = @{$row2_str};
    my @controlrow;
    if ($vector_score eq "partial"){
      @controlrow=split/\t/,$partial_correlation_row_data,-1;
    }
    if($empty_values){
      my @tmp_row1;
      my @tmp_row2;
      my @tmp_controlrow;
      for my $i (0..$#row1){
	if ($vector_score eq "partial"){
	  if ($row1[$i] ne "" and $row2[$i] ne "" and $controlrow[$i] ne "") {
	    push @tmp_row1,$row1[$i];
	    push @tmp_row2,$row2[$i];
	    push @tmp_controlrow,$controlrow[$i];
	  }
	}
	else{
	  if ($row1[$i] ne "" and $row2[$i] ne "") {
	    push @tmp_row1,$row1[$i];
	    push @tmp_row2,$row2[$i];
	  }
	}

      }
      @row1=@tmp_row1;
      @row2=@tmp_row2;
      @controlrow=@tmp_controlrow;
    }

    my $res;
    if ($vector_score eq "pearson")
    {
      &vec_center_by_ref(\@row1);
      &vec_center_by_ref(\@row2);
      $res = &format_number(&vec_pearson(\@row1, \@row2), $precision);
    }
    elsif ($vector_score eq "spearman")
    {
      $res = &format_number(&vec_spearman(\@row1, \@row2), $precision);
    }
    elsif ($vector_score eq "partial")
    {
      &vec_center_by_ref(\@row1);
      &vec_center_by_ref(\@row2);
      &vec_center_by_ref(\@controlrow);
      my $corr12 = &vec_pearson(\@row1, \@row2);
      my $corr1c = &vec_pearson(\@row1, \@controlrow);
      my $corr2c = &vec_pearson(\@row2, \@controlrow);
      
      $res = &format_number(($corr12-($corr1c*$corr2c))/sqrt((1-$corr1c**2)*(1-$corr2c**2)), $precision);
    }
    elsif ($vector_score eq "bdot")
    {
	$res = &format_number(&vec_best_dot_product(\@row1, \@row2), $precision);
    }
    elsif ($vector_score eq "dot")
    {
	$res = &format_number(&vec_dot_product(\@row1, \@row2), $precision);
    }

    elsif ($vector_score eq "dotn")
    {
	$res = &format_number(&vec_dot_product_normedX(\@row1, \@row2), $precision);
    }
    elsif ($vector_score eq "mi")
    {
	$res = &format_number(&vec_mutual_information(\@row1, \@row2), $precision);
    }
    elsif ($vector_score eq "kl")
    {
	$res = &format_number(&vec_kl_distance(\@row1, \@row2, $kl_variable_dimension), $precision);
    }

    return ($res,scalar(@row1));
}


__DATA__

compute_pairwise_stats.pl <data file> 

   Compute all the statistics in the data file between
   the pairs given in the pairs file or between all 
   pairs of rows

   -p <file>:        Pairs file

   -n:               For each pair of rows, also print length of vectors (non-empty values compared)
   -e:               If specified, then also print pairs that do not exist in the data file
   -all:             If specified, then compute correlations between ALL pairs (no pairs file)
   -o <str>:         If specified, compares all rows with the row specified by <str> (no pairs file)

   -s <score>:       Score to compute between the two vectors (bdot/dot/dotn/pearson/mi/kl/partial) (default: pearson)
                       dot  = dot product
                       dotn = dot_product(X,Y)/weight(X), where weight(X)=sum_i{abs(x_i)} ** notice that this operation is not symmetric, but chould be used in the -o mode **

   -partial_row <str>: Key of row to use as control variables for partial correlation. (default: last row).
   -kl <num>:        If KL-distance is the score, then lists the number of probabilities per random 
                     variable (Since we assume that we can compare multiple random variables by adding
                     their KL distances) (default: 4)

   -offset <s,e,i>:  Offset the two vectors compared by offsetting the second by:
                     <s> entries, <s+i> entries,... <e> entries
                     For example, -offset "-10,10,1" will compute stats between the vectors at
                     offset -10 to offset +10 in increments of 1. currently does not work with partial correlation.
   -offset_name:     Force this number to be written at the offset column (good when offset is externally provided)

   -sim <num>:       Number of simulations to perform and get a p-value per computation

   -skip <num>:      Skip num lines in the input file (default: 0)

   -precision <num>: Precision for outputted correlations (default: 3)

   -two:             If specified, two-sided p-value is used with -sim

   -ev:              Indicates that the vectors may have empty values. If turned on, the script will remove
                     pairs of values that either one of them is empty, before the score calculation. If
                     "-offset" is used, different pairs will be removed according to the offset vectors.

   -sf <str>:        sectors file (rows of start\tend\n , zero based). sectors are subsequences within the
                     vectors that should not affect each other. this is relevant for offsetting: it prevents
                     data belonging to different sectors from overlapping. for example, if your vectors represents
                     data from two separate genomic locations, you wouldn't want the offsetting to cause
                     comparison of data between the two locations. currently does not work with partial
                     correlation.


