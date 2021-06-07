#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libfile.pl";

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

my $tmp_file="tmp_tab2arff.pl.".int(rand(10000000));
open (TMP,">$tmp_file");
while (<$file_ref>){
    print TMP $_;
}
close (TMP);

open (TMP,$tmp_file);
    
my %args = load_args(\@ARGV);
my $nominal_cols_str = get_arg("nom", "", \%args);
my $name = get_arg("name", "Data", \%args);
my %nominal_cols_hash;

my @nominal_cols=&parseRanges($nominal_cols_str);

if (scalar(@nominal_cols)){
    my $line=<TMP>;
    $line=~s/[ ,]/_/g;
    chomp $line;
    my @a=split/\t/,$line;
    while ($line=<TMP>){
	chomp $line;
	$line=~s/[ ,]/_/g;
	my @row=split /\t/,$line;
	for my $n (@nominal_cols){
	    $nominal_cols_hash{$a[$n]}{$row[$n]}=1;
	}
    }
    seek TMP,0,0;
}

print "\@RELATION $name\n\n";
my $line=<TMP>;
chomp $line;
my @head=split /\t/,$line;
for my $h (@head){
    $h=~s/[ ,]/_/g;
    chomp $h;
    print "\@ATTRIBUTE $h\t";
    if (exists $nominal_cols_hash{$h}){
	print "{",join(",",keys %{$nominal_cols_hash{$h}}),"}\n";
    }
    else{
	print "Real\n";
    }
}
print "\n\@DATA\n";
while ($line=<TMP>){
    $line=~s/[ ,]/_/g;
    chomp $line;
    my @row=split /\t/,$line;
    print join(",",@row),"\n";
}

close (TMP);
unlink ($tmp_file);

__DATA__


tab2arff.pl

Converts a tab file into an arff file (used by WEKA learning package). Rows
are instances, columns are features or labels. First row must be a header row.
All columns are asssumed to contain numerical (Real) data unless set otherwise
by -nom.

OPTIONS are:

    -nom <str>:    <str> is one or more columns that are nominal (accepts ranges)
    -name <str>:   WEKA name for the data
