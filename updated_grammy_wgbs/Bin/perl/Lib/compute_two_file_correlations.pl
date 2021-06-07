#!/usr/bin/perl

use strict;


require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
    print STDOUT <DATA>;
    exit;
}

my $file_ref;
my $file = $ARGV[0];

open(FILE, $file) or die("Could not open file '$file'.\n");
$file_ref = \*FILE;

my %args = load_args(\@ARGV);
my $sec_file = get_arg("f", "", \%args);
my $output_file = get_arg("o", "", \%args);
my $key = get_arg("k", "0", \%args);
my $key_secfile = get_arg("kf", "0", \%args);

open(OUT, ">$output_file") or die ("Could not open file $output_file\n");

while (<FILE>)
{
    chomp($_);
    my @fields = split;
    my $k = $fields[$key];
    my $num_matches = `cat $sec_file | filter.pl -c $key_secfile -estr $k -h -0 | wc -l`;
    chomp($num_matches);
    print "$k @fields $num_matches\n";
    die ("Too many matches in $sec_file for $k\n")  if ($num_matches > 1);
    #die ("No matches in $sec_file for $k\n")  if ($num_matches == 0);
   
    if ($num_matches == 1)
    {
	`cat $file | filter.pl -c 0 -estr $k -skip 0 -skipc 0 > tmp1`;
	`cat $sec_file | filter.pl -c 0 -estr $k -skip 0 -skipc 0 > tmp2`;
	`cat tmp1 tmp2 | cut -f 2- | transpose.pl > tmp3`;
	my $corr_score = `cat tmp3 | compute_correlation.pl`; 
	chomp($corr_score);
	if ($corr_score eq "")
	{
	    $corr_score = "ERROR"; 
	}
	print OUT "$k\t$corr_score\n";
    }
}




__DATA__
    
    compute_two_file_correlations.pl
    
    Takes a tab file and correlate each row with the corresponding row (same key) from another file

    -f <string>: Name of second file
    -k <num>: Location of key in input file (default: column 0 - zero based)
    -kf <num>:  Location of key in the second file (default: column 0 - zero based)
    -o <string>: Name of output file
