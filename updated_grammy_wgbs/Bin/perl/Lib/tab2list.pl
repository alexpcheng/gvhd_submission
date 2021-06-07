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

my $search_string = get_arg("s", "", \%args);
my $min_value = get_arg("min", "", \%args);
my $max_value = get_arg("max", "", \%args);
my $abs_value = get_arg("abs", "", \%args);
my $delimiter = get_arg("d", "\t", \%args);
my $not_equal_string_value = get_arg("ne", "", \%args);
my $not_empty = get_arg("nonempty", 0, \%args);
my $empty = get_arg("empty", 0, \%args);
my $print_value = get_arg("p", "", \%args);
my $allowed_names_file = get_arg("a", "", \%args);

$min_value =~ s/\"//g;
$max_value =~ s/\"//g;

my %allowed_names;
if (length($allowed_names_file) > 0)
{
  open(ALLOWED_NAME, "<$allowed_names_file");
  while(<ALLOWED_NAME>)
  {
    chop;

    my @row = split(/\t/);

    $allowed_names{$row[0]} = "1";
  }
}

my $line = <$file_ref>;
chop $line;
my @columns = split(/$delimiter/, $line);

while(<$file_ref>)
{
  chop;

  my @row = split(/$delimiter/);

  for (my $i = 1; $i < @row; $i++)
  {
    if (length($allowed_names_file) == 0 or $allowed_names{$columns[$i]} eq "1")
    {
      if ((length($search_string) > 0 and $row[$i] eq $search_string) or
	  (length($not_equal_string_value) > 0 and $row[$i] ne $not_equal_string_value) or
          (length($min_value) > 0 and length($row[$i]) > 0 and $row[$i] >= $min_value) or
	  (length($max_value) > 0 and length($row[$i]) > 0 and $row[$i] <= $max_value) or
	  ($not_empty == 1 and length($row[$i]) > 0) or
	  ($empty == 1 and length($row[$i]) == 0) or
          (length($abs_value) > 0 and ($row[$i] > $abs_value or -$row[$i] > $abs_value)))
      {
	print "$columns[$i]\t$row[0]";
	if ($print_value == 1) { print "\t$row[$i]"; }
	print "\n";
      }
    }
  }
}

__DATA__

tab2list.pl <file>

   Takes in a tab delimited file and converts every entry of '1'
   into a pair of the column name followed by the row name

   -s <num>:   The string to search for in the entry (default: 1)
   -min <num>: If specified, values exceeding num will be printed  (write '"-1"' to pass negative numbers)
   -max <num>: If specified, values below num will be printed  (write '"-1"' to pass negative numbers)
   -abs <num>: If specified, values below num or above num will be printed
   -ne  <str>: If specified, values different than str will be printed
   -nonempty:  If specified, values that are non-empty will be printed
   -empty:     If specified, values that ARE empty will be printed

   -d <str>:   Delimiter in the file (default: '\t')

   -p:         If specified, values of the entries will be printed as well

   -a <name>:  If specified, only columns whose names appear in the file <name> will be printed

