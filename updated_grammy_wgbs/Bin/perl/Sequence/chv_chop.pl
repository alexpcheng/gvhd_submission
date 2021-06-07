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
my $max_elements = get_arg("m", 1000000, \%args);
my $id_handle = get_arg("id", 0, \%args);

($id_handle == 0 or $id_handle == 1 or $id_handle == 2) or die("Error: the '-id' flag expects one of the following numbers: 0,1,2\n");

my $id_counter = 1;

while(my $row_str = <$file_ref>)
{
   chomp($row_str);

   my @row = split(/\t/,$row_str);

   my $chr = $row[0];
   my $id = $row[1];
   my $start = $row[2];
   my $end = $row[3];
   my $type = $row[4];
   my $vector_single_length = $row[5];
   my $vector_single_jump = $row[6];
   my $vector_vals = $row[7];
   my $deliminer = ';';

   my $id_new = $id;

   if ((abs($start-$end)/$vector_single_jump)+1 <= $max_elements)
   {
      if ($id_handle == 1)
      {
	 $id_new = $id_counter;
	 $id_counter = $id_counter + 1;
      }
      print  STDOUT "$chr\t$id_new\t$start\t$end\t$type\t$vector_single_length\t$vector_single_jump\t$vector_vals\n";
   }
   else
   {
      if ($start < $end)
      {
	 my $c = 0;
	 my $c_total = 0;
	 my $c_start = 0;
	 my $c_start_tmp = $c_start;
	 my $c_end = 0;
	 my $c2 = 1;

	 my $start_new = $start;
	 my $end_new = $end;

	 my $not_done = 1;

	 while($not_done == 1)
	 {
	    while($c < $max_elements and $c_total < (abs($start-$end)/$vector_single_jump)+1)
	    {
	       $c_end = index($vector_vals, $deliminer, $c_start_tmp);
	       $c++;
	       $c_total++;
	       $c_start_tmp = $c_end+1;
	    }
	    my $vector_vals_new = ($c_end > -1) ? substr($vector_vals, $c_start, ($c_end-$c_start)) : substr($vector_vals, $c_start);
	    if ($id_handle == 1)
	    {
	       $id_new = $id_counter;
	       $id_counter = $id_counter + 1;
	    }
	    elsif ($id_handle == 0)
	    {
	       $id_new = $id . "_$c2";
	    }
	    $c = 0;
	    $c_start = $c_end+1;
	    $c_end = $c_start;
	    $c2++;
	    $end_new = $start + ($c_total-1)*$vector_single_jump;
	    print STDOUT "$chr\t$id_new\t$start_new\t$end_new\t$type\t$vector_single_length\t$vector_single_jump\t$vector_vals_new\n";
	    $start_new = $end_new + $vector_single_jump;
	    $not_done = $c_total < (abs($start-$end)/$vector_single_jump)+1 ? 1 : 0;
	 }
      }
      else
      {
	 my $c = 0;
	 my $c_total = 0;
	 my $c_start = length($vector_vals)-1;
	 my $c_start_tmp = $c_start;
	 my $c_end = 0;
	 my $c2 = 1;

	 my $start_new = $start;
	 my $end_new = $end;

	 my $not_done = 1;

	 while($not_done == 1)
	 {
	    while($c < $max_elements and $c_total < (abs($start-$end)/$vector_single_jump)+1)
	    {
	       $c_end = rindex($vector_vals, $deliminer, $c_start_tmp);
	       $c++;
	       $c_total++;
	       $c_start_tmp =  ($c_end > -1) ? $c_end-1 : $c_start_tmp;
	    }
	    my $vector_vals_new = ($c_end > -1) ? substr($vector_vals, ($c_end+1), ($c_start-$c_end)) : substr($vector_vals, 0, $c_start_tmp+1);
	    if ($id_handle == 1)
	    {
	       $id_new = $id_counter;
	       $id_counter = $id_counter + 1;
	    }
	    elsif ($id_handle == 0)
	    {
	       $id_new = $id . "_$c2";
	    }
	    $c = 0;
	    $c_start = $c_end-1;
	    $c_end = $c_start;
	    $c2++;
	    $start_new = $end + ($c_total-1)*$vector_single_jump;
	    print STDOUT "$chr\t$id_new\t$start_new\t$end_new\t$type\t$vector_single_length\t$vector_single_jump\t$vector_vals_new\n";
	    $end_new = $start_new + $vector_single_jump;
	    $not_done = $c_total < (abs($start-$end)/$vector_single_jump)+1 ? 1 : 0;
	 }
      }
   }

}

__DATA__

chv_chop.pl <file.chv>

   Takes in a chv file and break all rows with more than some number of elements (in column 8).

   -m <int>        Max number of elements in a row (default: 1000000)

   -id <0,1,2>     How to handle the id field of a broken row.
                   0  =>  upend the original id with '_i' for each new row i (default).
                   1  =>  set new ids: 1,2,3,4...
                   2  =>  keep the original id unmodified (multiple new rows would have the same original id)
