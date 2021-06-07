#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit(0);
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

my $delimiter1 = get_arg("d1", ":", \%args);
my $delimiter2 = get_arg("d2", "+", \%args);
my $verbose = ! get_arg("q", 0, \%args);
my %matrix_categories = ();
my @lines = <$file_ref>;

my $first_line = $lines[0];
chomp($first_line);
my @first_line_array = split(/\t/,$first_line);
my $first_line_1entry = shift(@first_line_array);
my $first_line_2entry;
{
  local $" = "$delimiter1";
  $first_line_2entry = "@first_line_array";
}

print STDOUT "$first_line_1entry\t$first_line_2entry\n";

my $num_of_columns = 0;

#----------------------------------------------------#
# Find all categories                                #
#----------------------------------------------------#
for (my $k=1; $k < @lines; $k++)
{
  my $l = @lines[$k];
  chomp($l);
  my @r = split(/\t/,$l);

  if ($k == 1) 
  {
    $num_of_columns = @r - 1;
  }

  for (my $i=1; $i < @r; $i++)
  {
    &AddCategory($i,$r[$i]);
  }
}

#----------------------------------------------------#
# Go go power rangers!! calc the superset            #
#----------------------------------------------------#
for (my $k=1; $k < @lines; $k++)
{
  my $l = @lines[$k];
  chomp($l);
  my @r = split(/\t/,$l);

  $verbose and print STDERR ".";

  my $res = &AllSupersets($l);

  my @res_lines = split(/\n/,$res);

  for (my $i=0; $i < @res_lines; $i++)
  {
    my $line2print = $res_lines[$i];
    chomp($line2print);
    print STDOUT "$line2print\n";
  }
}


#----------------------------------------------------#
# Subroutines                                        #
#----------------------------------------------------#

#----------------------------------------------------#
# $superset_c = &AllSupersetsSingleCategory($n,$c)   #
#----------------------------------------------------#
sub AllSupersetsSingleCategory
{
  my $set = $_[0]; #the set number
  my $category = $_[1]; #the category

  my @categories_list = ();
  my $index = 1;
  my $value = 1;

  while ($value == 1)
  {
    $value = exists $matrix_categories{"$set,$index"};
    if ($value)
    {
      my $tmp_val = $matrix_categories{"$set,$index"};
      unless ($tmp_val eq $category)
      {
	push(@categories_list,$tmp_val);
      }
    }
    $index++;
  }

  my $superset_reduced = &AllSupersetsSingleCategoryRecursive(@categories_list);

  my @superset_reduced_array = split(/\n/,$superset_reduced);
  my $result = "$category";

  for(my $t=0; $t < @superset_reduced_array; $t++)
  {
    my $new_set = "$category\t$superset_reduced_array[$t]";

    my @new_set_r = split(/\t/,$new_set);
    @new_set_r = sort @new_set_r;
    {
      local $" = $delimiter2;
      $new_set = "@new_set_r";
    }

    $result = "$result\n$new_set"; 
  }

  return $result;
}

#-------------------------------------------------------------------#
# $result = &AllSupersetsSingleCategoryRecursive(@categories_list)  #
#-------------------------------------------------------------------#
sub AllSupersetsSingleCategoryRecursive
{
  my @categories_list = @_; #the categories_list
  my $category;
  my $result;

  if (@categories_list == 0)
  {
    die("Shouldn't get here: the array categories_list is empty...\n");
  }
  elsif (@categories_list == 1)
  {
    $result = $categories_list[0];
  }
  else
  {
    $category = shift(@categories_list);

    my $tmp_superset = &AllSupersetsSingleCategoryRecursive(@categories_list);
    $result = "$category\n$tmp_superset";

    my @tmp_superset_array = split(/\n/,$tmp_superset);

    for(my $t=0; $t < @tmp_superset_array; $t++)
    {
      if (length($tmp_superset_array[$t]) > 0)
      {
	my $new_set = "$category\t$tmp_superset_array[$t]";
	$result = "$result\n$new_set"; 
      }
    }
  }
  return $result;
}
#----------------------------------------------------#
# $res = &AllSupersets($l)                           #
#----------------------------------------------------#
sub AllSupersets
{
  my $l = $_[0]; #l is the line we're working on
  split($l);
  my @r = split(/\t/,$l);
  my $object_id = shift(@r);
  my $n = 1;
  my $c = shift(@r);

  my $result;

  my $superset_c = &AllSupersetsSingleCategory($n,$c);
  my $all_crossprod_supersets_after_c = &AllSupersetsRecursive(($n + 1),@r);

  if (length($all_crossprod_supersets_after_c) > 0)
  {
    my @superset_c_array = split(/\n/,$superset_c);
    my @all_crossprod_supersets_after_c_array = split(/\n/,$all_crossprod_supersets_after_c);

    my @tmp_res=();

    for (my $i=0; $i < @superset_c_array; $i++)
    {
      for (my $j=0; $j < @all_crossprod_supersets_after_c_array; $j++)
      {
	my $new_guy = "$object_id\t$superset_c_array[$i]$delimiter1$all_crossprod_supersets_after_c_array[$j]";
	push(@tmp_res,$new_guy);
      }
    }
    {
      local $" = "\n";
      $result = "@tmp_res";
    }
  }
  else
  {
    $result = $superset_c;
  }

  return $result;
}

#----------------------------------------------------------------#
# $res = &AllSupersetsRecursive($index_active_category,$array )  #
#----------------------------------------------------------------#
sub AllSupersetsRecursive
{
  my $n = shift(@_); #n is the index of the next category in the hash
  my @r = @_; #r is the array
  my $c = shift(@r);

  my $result = "";

  if ($n <= $num_of_columns)
  {
    my $superset_c = &AllSupersetsSingleCategory($n,$c);
    my $all_crossprod_supersets_after_c = &AllSupersetsRecursive(($n + 1),@r);

    if (length($all_crossprod_supersets_after_c) > 0)
    {
      my @superset_c_array = split(/\n/,$superset_c);
      my @all_crossprod_supersets_after_c_array = split(/\n/,$all_crossprod_supersets_after_c);

      my @tmp_res=();

      for (my $i=0; $i < @superset_c_array; $i++)
      {
	for (my $j=0; $j < @all_crossprod_supersets_after_c_array; $j++)
	{
	  my $new_guy = "$superset_c_array[$i]$delimiter1$all_crossprod_supersets_after_c_array[$j]";
	  push(@tmp_res,$new_guy);
	}
      }
      {
	local $" = "\n";
	$result = "@tmp_res";
      }
    }
    else
    {
      $result = $superset_c;
    }
  }

  return $result;
}

#----------------------------------------------------#
# &AddCategory($set,$category)                       #
#----------------------------------------------------#
sub AddCategory
{
  my $set = $_[0];
  my $category = $_[1];

  my $index = 1;
  my $category_is_saved = 0;
  my $value = 1;

  while (($value == 1) and (! $category_is_saved))
  {
    $value = exists $matrix_categories{"$set,$index"};

    if ($value)
    {
      if ($matrix_categories{"$set,$index"} eq $category)
      {
	$category_is_saved = 1;
      }
    }
    else
    {
      $matrix_categories{"$set,$index"} = $category;
    }
    $index++;
  }
}


__DATA__

sets2powersets.pl <file>

   Input: 

    Takes in a tab file of the form:
    
         set1 set2 ... setN
     g1  
     g2       c{ij}
     .        
     .
     .
     gM
 
    where the rows corespond to genes, the columns to sets (with both row&column headers)
    and c{ij} = the category for which gene i belongs to in set j.

   Ouput: 

    A tab file of similar form, where for each gene there are muliptle rows that correspond to all
    sets of the powerset defined on the original sets (e.g., assume 2 binary sets with vals={H,L},
    then "g1 L H" is replaced by "g1 L H" & "g1 L+H H" & "g1 L L+H" & "g1 L+H L+H", where "L+H" means
    that the category is either H or L. Can output the same data in slightly different formats, 
    where for each gene the categories at all columns are merged with some specified delimiter to form a 
    "string label" of the set. E.g., "g1 L L+H L" is replaced by "g1 L:L+H:L". Moreover, you can 
    specify the delimiter to combine a superset of categories within a single set.

   Flags:

    -d1 <str>      The delimiter <str> to combine categories of different sets (default: ":"). 
                   *** Do not use \t or \n for delimiters!!!! ***

    -d2 <str>      The delimiter <str> to combine a superset of categories within a single set (default: "+").
                   *** Do not use \t or \n for delimiters!!!! ***

