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

my %args = load_args(\@ARGV);
my $prop_str = get_arg("prop", "", \%args);
my @features = split /;/,$prop_str;
for my $f (@features){
    if ($f ne ""){
	$f=~/\s*(\S+)\s*\[\s*(\S+)\s*\]\s*/;
	print "[$1]\n";
	my @properties=split /,/,$2;
	for my $p (@properties){
	    if ($p ne "") {
		print "$p\n";
	    }
	}
	print "\n";
    }
}

my $reference="";
my %features_hash;
while(<$file_ref>){
    chomp;
    my @row=split /\t/;
    if ($row[0] ne $reference){
	print "\nreference = Chr$row[0]\n";
	$reference=$row[0];
    }
    print "$row[4]\t$row[1]\t$row[2]-$row[3]\t$row[5]\n";
    $features_hash{$row[4]}=1;
}


__DATA__


chr2gbrowse.pl

converts a file from chr format to gbrowse format. file should be sorted by chromosome number.

    -prop <str>:   Set gbrowse feature properties, where <str> is of the form:
                   'feature1[property1=x,property2=y,...];feature2[property1=z,...]'


