#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $files_str = get_arg("f", 0, \%args);
my $output_file = get_arg("o", "", \%args);
my $gxa_name = get_arg("n", "gxa", \%args);

if (length($output_file) > 0) { open(OUTFILE, ">$output_file"); }

my $r = int(rand(1000000));
`rm -f tmp_$r`;

my @files = split(/\,/, $files_str);
foreach my $file (@files)
{
  $file =~ /([^\s]+)/;
  $file = $1;

  print STDERR "Adding gxa file $file...\n";

  `gxa2tab.pl $file | tab2list.pl -s 1 >> tmp_$r`;
}

`list2tab.pl tmp_$r > tmp1_$r; tab2gxa.pl tmp1_$r -n $gxa_name -t 4 > $output_file;`;

`rm -f tmp_$r`;
`rm -f tmp1_$r`;

__DATA__

combine_gxas.pl

   Combine files into one file using the keys of the rows to match up rows

   -f <f1,f2>:    List of all files, separated by commas

   -o <file>:     Output file name (default: standard output)

   -n <name>:     Name of the gxa group that will be created (default: gxa)

