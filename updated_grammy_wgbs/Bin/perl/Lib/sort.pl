#!/usr/bin/perl

#use strict;
use File::Copy;
use locale;

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

my %args_sort = load_args(\@ARGV);

my @data;

my $collect_mode = get_arg("collect", 0, \%args_sort);
my $skip_num = get_arg("skip", 0, \%args_sort);
my $reverse_sorting = get_arg("r", 0, \%args_sort);
my $verbose = ! get_arg("q", 0, \%args_sort);
my $reference_line_num = get_arg("ref", 1, \%args_sort);

my @sort_columns;
my @sort_counter;
my @numeric_counter;
my @operator_counter;
my @ref_counter;
my $done = 0;
my $counter = 0;
my $counter_ref = 0;

while ($done == 0)
{
  my $column_num = get_arg("c$counter", "", \%args_sort);
  if (length($column_num) > 0)
  {
    $numeric_counter[$counter] = get_arg("n$counter", 0, \%args_sort);
    $operator_counter[$counter] = get_arg("op$counter", 0, \%args_sort);
    $ref_counter[$counter] = $counter_ref;

    if (length($column_num) == 1)
    {
      $sort_counter[$counter] = 1;
      push(@sort_columns, $column_num);
      $counter_ref++;
      $verbose and print STDERR "Sorting $counter on column $column_num numeric=$numeric_counter[$counter]\n";
    }
    else
    {
      my @column_nums = &ParseRanges($column_num);
      $sort_counter[$counter] = @column_nums;
      while (@column_nums > 0)
      {
	my $tmp_column_num = shift(@column_nums);
	push(@sort_columns, $tmp_column_num);
	$counter_ref++;
      }
      $verbose and print STDERR "Sorting $counter with operator $operator_counter[$counter] on columns $column_num numeric=$numeric_counter[$counter]\n";
    }
    $counter++;
  }
  else
  {
    $done = 1;
  }
}

$verbose and print STDERR "\n";
my @reference_line;

if (! $collect_mode)
{
  #---------------------------------------------------------------------------------------#
  # The conventional sorting                                                              #
  #---------------------------------------------------------------------------------------#
  for (my $i = 0; $i < $skip_num; $i++) { my $line = <$file_ref>; print "$line"; }

  $counter = 1;

  while(<$file_ref>)
  {
    chomp;
    push(@data, $_);

    if ($counter == $reference_line_num)
    {
      @reference_line = split(/\t/,$_,-1);
    }

    $counter++;
    if ($verbose and ($counter % 100000 == 1)) { print STDERR "."; }
  }

  $verbose and print STDERR "Done loading. Now sorting...\n";

  @data = sort { &Comparator($a,$b) } @data;

  for my $line (@data)
  {
    print "$line\n";
  }
  $verbose and print STDERR "\nDone.\n";
}
else
{
  #---------------------------------------------------------------------------------------#
  # For huge files, we use parallel_create to break the file into small files and sort    #
  # each of them seperatly. Then, we use this mode (sort.pl -collect) to merge the files  #
  # back to a single file                                                                 #
  #---------------------------------------------------------------------------------------#
  my $file_name;

  my $i = 1;

  while (-d $i)
  {
    opendir(DIR, "$i/Output") or die "Can't open directory $i/Output";
    my @files = readdir(DIR);
    for my $file (@files)
    {
      $file eq '.'  and next;
      $file eq '..' and next;
      open("FILE"."$i" , "$i/Output/$file") or die("Could not open file '$file'.\n");
      print STDERR "Open $i/Output/$file for merging...\n";

      if ($i == 1) 
      {
	system ("rm -f ../Output/$file");
	$file_name = $file;
      }
    }
    closedir(DIR);
    $i++;
  }

  my $num_of_files = $i - 1;

  if ($num_of_files > 0)
  {
    open(MERGED, ">../Output/$file_name");
    print STDERR "\nMerge files into: ../Output/$file_name...";

    my @data = ();
    my @active_file_list = ();

    for (my $j = 1; $j <= $num_of_files; $j++)
    {
      my $fh = "FILE".$j;
      if (my $line = <$fh>)
      {
	chomp($line);
	push(@data, $line);
	push(@active_file_list, $j);
      }
    }

    while (@data > 0)
    {
      my $next_item_index = 0;
      my $next_item = $data[$next_item_index];

      
      my $best_field;
      if (@sort_counter == 1 && $operator_counter[0] == 0)
      {
	 $best_field = (split (/\t/, $data[$next_item_index],-1))[$sort_columns[0]];
      }

      for (my $k = 0; $k < @data; $k++)
      {
	 if (@sort_counter == 1 && $operator_counter[0] == 0) 
	 {
	    my $curr_field = (split (/\t/, $data[$k],-1))[$sort_columns[0]];
	    my $res = ($numeric_counter[0] == 1) ? ($curr_field <=> $best_field) : ($curr_field cmp $best_field);
	    $res = ($reverse_sorting == 1) ? -$res : $res;
	    if ($res == -1) 
	    {
	       $next_item_index = $k;
	       $best_field = $curr_field;
	       $next_item = $data[$next_item_index];
	    }
	 } 
	 else 
	 {
	    if (&Comparator($data[$k],$next_item) == -1) 
	    {
	       $next_item_index = $k;
	       $next_item = $data[$next_item_index];
	    }
	 }
      }

      print MERGED "$next_item\n";

      my $current_file_handle_num = $active_file_list[$next_item_index];
      my $fh = "FILE".$current_file_handle_num;
      if (my $new_line = <$fh>)
      {
	chomp($new_line);
	$data[$next_item_index] = $new_line;
      }
      else
      {
	splice(@data,$next_item_index,1);
	splice(@active_file_list,$next_item_index,1);
      }
    }

    print STDERR "\nDone.\n";
  }
}

#---------------------------------------------------------------------------------------#
# Comparator (can be used by the perl sort)                                             #
#---------------------------------------------------------------------------------------#
sub Comparator
{
  my @aa = split(/\t/, $_[0],-1);
  my @bb = split(/\t/, $_[1],-1);

  my $res = 0;
  for (my $i = 0; $i < @sort_counter; $i++)
  {
    my $sort_count = $sort_counter[$i];
    my $tmp_counter_ref = $ref_counter[$i];
    my $sort_column = $sort_columns[$tmp_counter_ref];
   
    my $aa_new;
    my $bb_new;
    my $aa_new_column;
    my $bb_new_column;

    if (($operator_counter[$i] eq "L1") or ($operator_counter[$i] eq "L2"))
    {
      if ($operator_counter[$i] eq "L1")
      {
	$aa_new = abs($aa[$sort_column] - $reference_line[$sort_column]);
	$bb_new = abs($bb[$sort_column] - $reference_line[$sort_column]);
      }
      else
      {
	$aa_new = ($aa[$sort_column] - $reference_line[$sort_column]) ** 2;
	$bb_new = ($bb[$sort_column] - $reference_line[$sort_column]) ** 2;
      }
    }
    else
    {
      $aa_new = $aa[$sort_column];
      $bb_new = $bb[$sort_column];
      $aa_new_column = $sort_column;
      $bb_new_column = $sort_column;
    }

    if (($operator_counter[$i] == 0) and ($sort_count == 1)) {}
    elsif (($operator_counter[$i] eq "L1") or ($operator_counter[$i] eq "L2"))
    {
      if ($numeric_counter[$i] == 1)
      {
	for (my $k = $tmp_counter_ref + 1; $k < $tmp_counter_ref + $sort_count; $k++)
	{
	  if ($operator_counter[$i] eq "L1")
	  {
	    $aa_new += abs($aa[$sort_column] - $reference_line[$sort_column]);
	    $bb_new += abs($bb[$sort_column] - $reference_line[$sort_column]);
	  }
	  else
	  {
	    $aa_new += ($aa[$sort_column] - $reference_line[$sort_column]) ** 2;
	    $bb_new += ($bb[$sort_column] - $reference_line[$sort_column]) ** 2;
	  }
	}
      }
      else { die("Sorting by L1/L2 distance to a reference line works only for numeric elements.\n"); }
    }
    elsif (($operator_counter[$i] eq "min") or ($operator_counter[$i] eq "minc"))
    {
      if ($numeric_counter[$i] == 1)
      {
	for (my $k = $tmp_counter_ref + 1; $k < $tmp_counter_ref + $sort_count; $k++)
	{
	  $aa_new_column = $aa_new < $aa[$sort_columns[$k]] ? $aa_new_column : $sort_columns[$k];
	  $bb_new_column = $bb_new < $bb[$sort_columns[$k]] ? $bb_new_column : $sort_columns[$k];
	  $aa_new = $aa_new < $aa[$sort_columns[$k]] ? $aa_new : $aa[$sort_columns[$k]];
	  $bb_new = $bb_new < $bb[$sort_columns[$k]] ? $bb_new : $bb[$sort_columns[$k]];
	}
      }
      else
      {
	for (my $k = $tmp_counter_ref + 1; $k < $tmp_counter_ref + $sort_count; $k++)
	{
	  $aa_new_column = $aa_new lt $aa[$sort_columns[$k]] ? $aa_new_column : $sort_columns[$k];
	  $bb_new_column = $bb_new lt $bb[$sort_columns[$k]] ? $bb_new_column : $sort_columns[$k];
	  $aa_new = $aa_new lt $aa[$sort_columns[$k]] ? $aa_new : $aa[$sort_columns[$k]];
	  $bb_new = $bb_new lt $bb[$sort_columns[$k]] ? $bb_new : $bb[$sort_columns[$k]];
	}
      }
    }
    elsif ($operator_counter[$i] eq "sum")
    {
      if ($numeric_counter[$i] == 1)
      {
	for (my $k = $tmp_counter_ref + 1; $k < $tmp_counter_ref + $sort_count; $k++)
	{
	  $aa_new += $aa[$sort_columns[$k]];
	  $bb_new += $bb[$sort_columns[$k]];
	}
      }
      else { die("Sorting by sum works only for numeric elements.\n"); }
    }
    elsif (($operator_counter[$i] eq "max") or ($operator_counter[$i] eq "maxc"))
    {
      if ($numeric_counter[$i] == 1)
      {
	for (my $k = $tmp_counter_ref + 1; $k < $tmp_counter_ref + $sort_count; $k++)
	{
	  $aa_new_column = $aa_new > $aa[$sort_columns[$k]] ? $aa_new_column : $sort_columns[$k];
	  $bb_new_column = $bb_new > $bb[$sort_columns[$k]] ? $bb_new_column : $sort_columns[$k];
	  $aa_new = $aa_new > $aa[$sort_columns[$k]] ? $aa_new : $aa[$sort_columns[$k]];
	  $bb_new = $bb_new > $bb[$sort_columns[$k]] ? $bb_new : $bb[$sort_columns[$k]];
	}
      }
      else
      {
	for (my $k = $tmp_counter_ref + 1; $k < $tmp_counter_ref + $sort_count; $k++)
	{
	  $aa_new_column = $aa_new gt $aa[$sort_columns[$k]] ? $aa_new_column : $sort_columns[$k];
	  $bb_new_column = $bb_new gt $bb[$sort_columns[$k]] ? $bb_new_column : $sort_columns[$k];
	  $aa_new = $aa_new gt $aa[$sort_columns[$k]] ? $aa_new : $aa[$sort_columns[$k]];
	  $bb_new = $bb_new gt $bb[$sort_columns[$k]] ? $bb_new : $bb[$sort_columns[$k]];
	}
      }
    }
    else { die("For multiple columns an operator must be defined (e.g. -op2 min).\n"); }

    $aa_new = (($operator_counter[$i] eq "minc") 
	       or 
	       ($operator_counter[$i] eq "maxc")) ? $aa_new_column : 
		 (($operator_counter[$i] eq "L2") ? sqrt($aa_new) : $aa_new);
    $bb_new = (($operator_counter[$i] eq "minc") 
	       or 
	       ($operator_counter[$i] eq "maxc")) ? $bb_new_column : 
		 (($operator_counter[$i] eq "L2") ? sqrt($bb_new) : $bb_new);

    $res = ($numeric_counter[$i] == 1) ? ($aa_new <=> $bb_new) : ($aa_new cmp $bb_new);
    if ($res != 0)
    {
      last;
    }
  }

  #$verbose and print STDERR "Comparing [$a] and [$b] res=$res\n";

  return $reverse_sorting == 1 ? -$res : $res;
}

__DATA__

sort.pl <file>

   Sort by multiple columns.

   -c<id> <num>        Sort by column <num>, as the <id> column to sort by.
                       For operation on multiple columns use the ","/"-" notation.
                       NOTE: zero-based, thus, -c0 2 will first sort on the third column
                       NOTE: currently can't use the <num>- notation to denote all columns gte <num>.

   -n<id>              The sorting on the <id>'th column is numeric

   -r                  Sort in the reverse order (default: ascending)

   -q                  Quiet mode (default is verbose)

   -skip <num>         Skip the first <num> lines in the file and just print them out

   -op<id> <operator>  Sort using multiple columns key with "operator" as the operator

                       OPERATORS: min/max/minc/maxc/L1/L2/sum
                       
                       L1/L2 with some reference line comapre by the L1/L2-distance to the reference
                       when the only the defined columns are considered.

                       minc/maxc find the max/min values and compare the column indices.

                       E.g., to sort an 8 columns file, with the 4th key being the minimum
                       of the numeric columns 2,3,4 and 6,7,8 use: -c3 1-3,5-7 -op3 min -n3 

   -ref <num>          Define the line of the reference element for operators that compare 
                       each element to a reference, such as L1/L2. (default: 1) 

-------------------------------------------------------------------------------------------------------------------------
   -collect            When run in the /Parallel directory, this script collectes all files in the
                       /Output directories into a single large file in the /Output directory that's
                       at the same level of /Parallel. It merges all files to a single sorted file 
                       so if the files were sorted within them by the same sorting, the resulted 
                       file is sorted. This should be used to sort large files.                       
	
	               For an example, in order to sort a file test.tab by -c0 0 -n0, by breaking it to 50 small files, do:

                       (1) Create an "Output" directory.

                       (2) Add in the current directory's Makefile a command like: 
                           my_sort:
                                cat test.tab | sort.pl -c0 0 -n0 > Output/test_sorted.tab; \

                       (3) Run: parallel_create.pl -n 50 -s test.tab -c "q.pl make my_sort".

                       (4) From the Parallel directory run: "make run".

                       (5) Once all processes are done, your directory will include:
	
                           /Parallel
	       	                    /1/Output/test_sorted.tab
		                    /2/Output/test_sorted.tab
                                    ...
		                    /50/Output/test_sorted.tab

                       (6) From the Parallel directory run: sort.pl -c0 0 -n0 -collect
                           and sort.pl will MERGE (unlike parallel_collect.pl) all the 50 files into:

         	           /Output/test_sorted.tab
-------------------------------------------------------------------------------------------------------------------------
