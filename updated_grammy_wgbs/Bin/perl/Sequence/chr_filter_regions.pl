#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/GeneXPress/gxt_helpers.pl";

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
my $is_chv = get_arg("chv", 0, \%args);
my $min = get_arg("min", "", \%args);
my $max = get_arg("max", "", \%args);
my $mins = get_arg("mins", "", \%args);
my $maxs = get_arg("maxs", "", \%args);
my $filter_file = get_arg ("f", "", \%args);
my $chv_output = get_arg ("v", "", \%args);

my %allowed_regions;
if ($filter_file ne ""){
  open (IN,"$filter_file") or die ("cant find $filter_file ! \n");
  while(<IN>){
    chomp;
    my @line=split/\t/;
    my %location;
    $location{left}=$line[2]<$line[3]?$line[2]:$line[3];
    $location{right}=$line[2]>$line[3]?$line[2]:$line[3];
    push @{$allowed_regions{$line[0]}},\%location;
  }
  close (IN);
}


if ($is_chv != 1)
{
   print STDERR "Error: Supporting only chv input of single basepair features.\n";
   exit 1;
}


my $vector_row_size;
my $vector_row_current_index;
my $vector_row_current_substr_index;
my $direction = 0;

my $vector_single_length;
my $vector_single_jump;

my $match_start;
my $n_match;
my $in_match_region = 0;
my $curr_matches = 0;

my $start;
my $end;

my $curr_value;
my $curr_sep_index = -1;
my $next_sep_index = 0;

my @row;

my $counter = 0;
while(<$file_ref>)
{
   chomp;
   
   #   print STDERR "Read $_\n";

   if ($counter++ % 10000 == 0) 
   { 
      print STDERR "."; 
   }
   
   @row = split(/\t/,$_,-1);


   if ($is_chv == 1)
   {
     my @feature_values ;
      $n_match = 0;
      $in_match_region = 0;
      $curr_sep_index = -1;
      $next_sep_index = 0;

      $vector_single_length = $row[5];
      $vector_single_jump = $row[6];

      if ($vector_single_length != 1 or $vector_single_jump != 1)
      {
	 print STDERR "Error: Currently supporting only values per basepair (value width and length are both 1)!!!!";
	 exit 3;
      }

      $direction = $row[2] < $row[3];

      $vector_row_size = $direction ? ($row[3] - $row[2] + 1) : ($row[2] - $row[3] + 1);

      for (my $i = 0; $i < $vector_row_size; $i++)
      {
	 $curr_matches = 0;

	 $next_sep_index = index ($row[7], ";", ++$curr_sep_index);
	 if ($next_sep_index==-1){
	   $next_sep_index=length($row[7]);
	 }
	 $curr_value = substr ($row[7], $curr_sep_index,  $next_sep_index - $curr_sep_index);
	 $curr_sep_index = $next_sep_index;

	 my $bp_in_allowed_region=0;
	 for my $r (@{$allowed_regions{$row[0]}}){
	   if ($row[2]+$i>=$$r{left} and $row[2]+$i<=$$r{right}) { $bp_in_allowed_region=1 }
	 }
	 #	 print STDERR "Val $curr_value\n";
	 if ( (length($min) == 0 or $curr_value >= $min) and
	      (length($max) == 0 or $curr_value <= $max) and
	      (length($mins) == 0 or $curr_value > $mins) and
	      (length($maxs) == 0 or $curr_value < $maxs) and
	      ($filter_file eq "" or $bp_in_allowed_region)
	    )
	 {
	    $curr_matches = 1;
	    if($chv_output ne ""){
	      push @feature_values,$curr_value;
	    }
#	    print "$row[0]\t".($i+1). "\t1\t$curr_value\n";
	 }

	 if ($in_match_region == 1)
	 {
	    if ($curr_matches == 0)
	    {
	       #	       print STDERR "Region ends\n";

	       $start = $direction ? $row[2] + $match_start : $row[3] + $i - 1;
	       $end   = $direction ? $row[2] + $i - 1 : $row[3] + $match_start;
	       print "$row[0]\t$row[1]_$n_match\t$start\t$end";
	       if ($chv_output ne ""){
		 print "\t1\t1\t1\t",join(";",@feature_values);
	       }
	       print "\n";
	       @feature_values=();
	       $in_match_region = 0;
	    }
	 }
	 else
	 {
	    if ($curr_matches == 1)
	    {
#	       print STDERR "Region starts\n";
	       $in_match_region = 1;
	       $match_start = $i;
	       $n_match++;
	    }
	 }
      }
      if ($in_match_region)
      {
	 $start = $direction ? $row[2] + $match_start : $row[2];
	 $end   = $direction ? $row[3] : $row[3] + $match_start;
	 print "$row[0]\t$row[1]_$n_match\t$start\t$end";
	 if ($chv_output ne ""){
	   print "\t1\t1\t1\t",join(";",@feature_values);
	 }
	 print "\n";
	 @feature_values=();
      }
   }
}

__DATA__

chr_filter_regions.pl <location file>

   Takes a stats location file (chr with values or chv) and outputs the regions that match a given critera (e.g. all features below a certain threshold). Merges consecutive 
   locations to a single region.

   **** IMPORTANT **** Currently supports only .chv format with start<=end and values per basepair (value width and length are both 1)!!!!
   
   -chv:       Input file is a vector chr file (.chv)
   -v:         chv output
   
   Filter criteria: (specify at least one)

   -min <num>:  Filter passes if the value is above or equal to <num>
   -max <num>:  Filter passes if the value is below or equal to <num>
   -mins <num>:  Filter passes if the value is above to <num>
   -maxs <num>:  Filter passes if the value is below to <num>
   -f <str>:    Filter passes if the value is in the supplied chr file

