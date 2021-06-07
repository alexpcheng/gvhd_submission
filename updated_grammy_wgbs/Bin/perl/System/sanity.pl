#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";


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
my $params_fn = get_arg("f", "", \%args);

my %ncolumns;
my @r;

while (<$file_ref>)
{
	chomp;
	
	my @F = split ("\t", $_);
	
	$ncolumns{scalar @F}++;

}

print "Columns\tLines\n";
foreach my $key (keys %ncolumns)
{
	print "$key\t$ncolumns{$key}\n";
}



__DATA__

sanity.pl

	Check sanity of a tab-file.
	
	1. Print number of columns, number of lines.
	2. Print minimal and maximal values for each numeric column.
	3. Print minimal and maximal length of values for each string column.
