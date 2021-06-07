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

my $search_directory = get_arg("d", ".", \%args);
my $search_files = get_arg("n", "", \%args);
my $num_columns = get_arg("c", 0, \%args);
my $print_file_extension = get_arg("e", 0, \%args);

my $files_str = `find $search_directory -name "$search_files"`;
my @files = split(/\n/, $files_str);
foreach my $file (@files)
{
    my $file_for_prefix = $file;
    if ($print_file_extension == 0 and $file_for_prefix =~ /[\/][^\/]+[\.][^\.]+$/)
    {
	$file_for_prefix =~ s/[\.][^\.]+$//;
    }

    print STDERR "$file $file_for_prefix\n";

    my @row = split(/\//, $file_for_prefix);
    my $file_prefix = "";
    for (my $i = 0; $i <= $num_columns; $i++)
    {
	if (length($file_prefix) > 0) { $file_prefix .= "\t"; }

	my $index = $i + @row - 1 - $num_columns;

	$file_prefix .= $row[$index];
    }

    open(FILE, "<$file");
    while(<FILE>)
    {
	chop;

	print "$file_prefix\t$_\n";
    }
}

__DATA__

cat_files.pl <file>

   Takes a directory and a wildcard search, and prints the contents of all the 
   files found, appended with their directory and file information

   -d <str>:   Directory to search for files (default: '.')
   -n <str>:   File name wildcard to search for 

   -c <num>:   Number of directories to print in each column (default: 0) 
               NOTE: 0 = only file name, 1 = file name + first immediate directory, ...

   -e:         Print the file extension (default: do not print)

