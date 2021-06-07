#!/usr/bin/perl

use strict;

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

my $n_table = get_arg("n", 1, \%args);

my $OPEN_TABLE_TAG  = "<table";
my $CLOSE_TABLE_TAG = "</table";
my $OPEN_ROW_TAG    = "<tr";
my $CLOSE_ROW_TAG   = "</tr";
my $OPEN_COL_TAG    = "<td";
my $CLOSE_COL_TAG   = "</td";
my $OPEN_COMMENT    = "<!--";
my $CLOSE_COMMENT   = "-->";

my $str = "";
while(<$file_ref>)
{
   chop;
   
   $str .= "$_";
}

my $start_table_index = -1 * length ($OPEN_TABLE_TAG);
for (my $i = 0; $i < $n_table && $start_table_index != -1; $i++)
{
   $start_table_index = &tag_index($str, $OPEN_TABLE_TAG, $start_table_index + length($OPEN_TABLE_TAG));
} 

my $end_table_index = &tag_index($str, $CLOSE_TABLE_TAG, $start_table_index + length($OPEN_TABLE_TAG));

if ($start_table_index == -1 || $end_table_index == -1)
{
   print STDERR "Error: Table number $n_table does not exist or not defined properly.\n";
   exit 1;
}

$str = substr($str, $start_table_index + length($OPEN_TABLE_TAG), $end_table_index - ($start_table_index + length($OPEN_TABLE_TAG)));

# Remove comments
$str =~ s/$OPEN_COMMENT.*?$CLOSE_COMMENT//g;

my $debug_counter = 0;

my $start_row_index = &tag_index($str, $OPEN_ROW_TAG, 0);
while ($start_row_index != -1)
{
   my $end_row_index =  &tag_index($str, $CLOSE_ROW_TAG, $start_row_index + length($OPEN_ROW_TAG));
   
   if ($end_row_index == -1)
   {
      $start_row_index = -1;
   }
   else
   {
      my $columns_str = substr($str, $start_row_index + length($OPEN_ROW_TAG), $end_row_index - ($start_row_index + length($OPEN_ROW_TAG)));
      
      my $start_column_index = &tag_index($columns_str, $OPEN_COL_TAG, 0);
      while ($start_column_index != -1)
      {
	 my $end_column_index = &tag_index($columns_str, $CLOSE_COL_TAG, $start_column_index + length($OPEN_ROW_TAG));
	 
	 if ($end_column_index == -1)
	 {
	    $start_column_index = -1;
	    print STDERR ("Error: did not find </td tag at row: ".$columns_str."\n");
	 }
	 else
	 {
	    my $column_str = substr($columns_str, $start_column_index + length($OPEN_ROW_TAG), $end_column_index - ($start_column_index + length($OPEN_ROW_TAG)));

	    my $real_end_column_index = 0;

	    $column_str =~ s/\<.*?\>//g;
	    my $real_start_column_index = index($column_str, ">", 0);

	    my $tmp_column_str = substr($column_str, $real_start_column_index + 1, length($column_str) - $real_start_column_index);
	    print "$tmp_column_str\t";

	    $start_column_index = &tag_index($columns_str, $OPEN_COL_TAG, $end_column_index + length($CLOSE_COL_TAG));
	 }
      }
      
      print "\n";
      
      $start_row_index = &tag_index($str, $OPEN_ROW_TAG, $end_row_index + 3);
   }
}

sub tag_index # string, tag, position
{
  my ($str, $tag, $position) = @_;

  my $uc_pos = index ($str, "\U$tag", $position);
  my $lc_pos = index ($str, "\L$tag", $position);

  if ($uc_pos != -1 && $lc_pos != -1)
  {
     return ($uc_pos < $lc_pos) ? $uc_pos : $lc_pos;
  }
  else
  {
     return ($uc_pos > $lc_pos) ? $uc_pos : $lc_pos;
  }
}

__DATA__

htmltable2list.pl <file>

   Takes in an html table and produces a tabbed list where each row in the html
   is a row in the output and each html column is a column

  -n: Parse table number n in the html file (one based, default: n = 1)

