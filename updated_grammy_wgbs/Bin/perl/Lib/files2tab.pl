#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $directory = get_arg("d", ".", \%args);
my $file_keyword = get_arg("f", "", \%args);
my $special_values_str = get_arg("v", "", \%args);
my $keep_dir_prefix = get_arg("dir", 0, \%args);
my $keep_file_extension = get_arg("keep_extension", 0, \%args);
my $keep_entire_row = get_arg("keep_entire_row", 0, \%args);
my $apply_prefix = get_arg("apply_prefix", "cat ", \%args);
my $apply_suffix = get_arg("apply_suffix", "", \%args);

print "$special_values_str\n";
my @special_values = split(/\;/, $special_values_str);
my %special_values_hash;
foreach my $special_value (@special_values)
{
  my @row = split(/\,/, $special_value);

  $special_values_hash{$row[0]} = $row[1];

  print "special_values_hash{$row[0]} = $row[1]\n";
}

print STDERR "Searching find $directory/. -name \"$file_keyword\"\n";

my $files_str = `find $directory/. -name "$file_keyword"`;
my @files = split(/\n/, $files_str);

foreach my $file (@files)
{
  if (-f $file)
  {
    #print STDERR "Processing $file\n";

    my $file_name = "";
    if ($file =~ /[\.][^\/]*$/)
    {
      $file =~ /(.*)[\/]([^\/]+)([\.][^\/]*)$/;
      if ($keep_dir_prefix == 1) { $file_name .= "$1/"; }
      $file_name .= $2;
      if ($keep_file_extension == 1) { $file_name .= "$3"; }
    }
    else
    {
      $file =~ /[\/]([^\/]+)$/;
      $file_name = $1;
    }

    my $file_str = `$apply_prefix $file $apply_suffix`;
    my @file_rows = split(/\n/, $file_str);
    foreach my $file_row (@file_rows)
    {
      #chop $file_row;

      my @row = split(/\t/, $file_row);

      if ($keep_entire_row == 1)
      {
	print "$file_name$special_values_hash{$row[1]}\t$file_row\n";
      }
      else
      {
	print "$file_name$special_values_hash{$row[1]}\t$row[0]\n";
      }
    }
  }
}

__DATA__

files2list.pl 

   Takes in a list of files to convert by taking in a directory
   from which to search, and a keyword for the search (i.e. will
   execute 'find <foo1> -name "foo2"' to get the list of files).
   Each file is then converted using its name to a list 

   -d <name>:       Directory from which to start the search (default: .)
   -f <name>:       Keyword for the files to search

   -v <val1,name1;val2,name2;...>: If specified, then when opening a file, will look at the 
                                   second column, and if it has the value val1, then the name
                                   of the file will be appended by the string name1.

   -dir:                If specified, files will be listed with their prefix directory (default: without)

   -keep_extension:     If specified, files will be listed with their extension (default: without)

   -keep_entire_row:    Keep the entire row in the output

   -apply_prefix <str>: Each file encountered, apply <str> as prefix (default: 'cat ')
   -apply_suffix <str>: Each file encountered, apply <str> as suffix (default: '')

