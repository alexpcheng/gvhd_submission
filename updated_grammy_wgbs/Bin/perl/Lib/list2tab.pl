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

my $header_str = get_arg("h", "Rows", \%args);
my $A_column = get_arg("A", 0, \%args);
my $B_column = get_arg("B", 1, \%args);
my $column_value = get_arg("V", "", \%args);
my $empty_fill_value = get_arg("e", 0, \%args);
my $empty_fill_value2 = get_arg("empty", 0, \%args);
my $skip_num = get_arg("skip_num", "", \%args);
my $count = get_arg("c", 0, \%args);
my $sort_row = get_arg("sort", 0, \%args);
my $sort_row_num = get_arg("sortn", 0, \%args);

my $fill_value = $empty_fill_value == 1 ? "" : $empty_fill_value2;

my %columns_hash;
my @columns;

my %rows_hash;
my @rows;

my %pairs;

for (my $i = 0; $i < $skip_num; $i++) { my $line = <$file_ref>; }

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  if ($count) { $pairs{$row[$A_column]}{$row[$B_column]}++; }
  elsif (length($column_value) == 0) { $pairs{$row[$A_column]}{$row[$B_column]} = "1"; }
  else { $pairs{$row[$A_column]}{$row[$B_column]} = $row[$column_value]; }

  if (length($columns_hash{$row[$A_column]}) == 0)
  {
    $columns_hash{$row[$A_column]} = "1";
    push(@columns, $row[$A_column]);
  }

  if (length($rows_hash{$row[$B_column]}) == 0)
  {
    $rows_hash{$row[$B_column]} = "1";
    push(@rows, $row[$B_column]);
  }
}

print "$header_str";
for (my $i = 0; $i < @columns; $i++)
{
    print "\t$columns[$i]";
}
print "\n";

if ($sort_row) { @rows = sort @rows; }
if ($sort_row_num) { @rows = sort { $a <=> $b } @rows; }

foreach my $row (@rows)
{
    print "$row";
    for (my $i = 0; $i < @columns; $i++)
    {
	my $column = $columns[$i];
	
	print "\t";
	
	if (length($pairs{$column}{$row}) == 0) { print "$fill_value"; }
	else { print "$pairs{$column}{$row}"; }
    }
    print "\n";
}

__DATA__

list2tab.pl <file>

   Takes in a list of pairs of <A><tab><B> and makes a tab delimited
   file out of that with the different A's at columns and B's on 
   the rows with a 1 for an <A,B> pair iff A appeared in the file with B

   Note that you can also specify <A><tab><B><tab><value> using the -V
   option and then the value at the value column will be written and not '1'

   -A <num>:     specifies the column for the A value of the pair (default: 0)
   -B <num>:     specifies the column for the B value of the pair (default: 1)

   -h <str>:     Header to place at the top-left corner (default: "Rows")
   -V <num>:     If specified, takes the value for the resulting entry from the <num> column
                 (default: just put '1')
   -c:           If specified, takes the value for the resulting entry to be the number of
                 times the pair A,B appeared together in the file.
   -e:           If specified, then the empty entries will be left empty (default: put 0)
   -empty <str>: If specified, then empty entries will be filled with str

   -skip <num>:  skip the first <num> lines in the file
   
   -sort:        Lexically sort the rows.
   -sortn:       Numerically sort the rows.
   
