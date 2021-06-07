#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

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

my $col_args = get_arg("f", "", \%args);
my $add_str  = get_arg("a", "", \%args);
my $add_file = get_arg("af", "", \%args);
my $fixed_block_size = -1;
my @add_strings;

if (length($col_args) == 0)
{
   print STDERR "Error: Mandatory parameter not specified (-f).\n";
}

if (length($add_file) > 0)
{
   open(STR_FILE, $add_file) or die("Could not open file '$add_file'.\n");
   $add_file_ref = \*STR_FILE;
   while (<$add_file_ref>)
   {
      chop;
      push (@add_strings, $_);
   }
}

my @col_ranges = split (/,/, $col_args);

if ($#col_ranges == 0)
{
   $fixed_block_size = $col_ranges[0];
}

my $max_num_columns = -1;
my @lines;
while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);
  push (@lines, $_);

  my $num = $#row + 1;

  if ($num > $max_num_columns)
  {
    $max_num_columns = $num;
  }
}

my $curr_block = 0;
for (my $curr_col = 0; $curr_col < $max_num_columns; $curr_block++)
{
   my $until_col;

   if ($fixed_block_size > 0)
   {
      $until_col = $curr_col + $fixed_block_size - 1;
   }
   else
   {
      $until_col = $curr_col + $col_ranges[$curr_block] - 1;
   }

   for (my $i = 0; $i <= $#lines; $i++)
   {
      my @curr_row = split(/\t/, $lines[$i]);

      for (my $j = $curr_col; $j <= $until_col; $j++)
      {
	 print $curr_row[$j];
	 if ($j != $until_col)
	 {
	    print ("\t");
	 }
      }
      
      if (length($add_str) > 0)
      {
	 print "\t".$add_str."_".$curr_block;
      }
      elsif (length($add_file) > 0)
      {
	 print "\t".$add_strings[$curr_block];
      }
      print "\n";
   }
   
   $curr_col += $fixed_block_size > 0 ? $fixed_block_size : $col_ranges[$curr_block];
}


__DATA__

reorder_columns_blocks.pl <source file>

   Prints columns of a table in a columns-block after columns-block order.

   -f RANGES:   If RANGES is a single number, it is the number of columns in each block
                (e.g. 3 means first print the first 3 columns, then the next 3 and so on).

                Otherwise, it should specify the number of columns in every block 
                (e.g. 4,2 means first print the first 4 columns, then the next 2).
                This Parameter is mandatory and one-based.

   -a STR: Add a column to make each block unique (STR_n will be added to block number n), see -af to add strings from a file.
   -af FILE: Add line number n in FILE as a column to block number n.
