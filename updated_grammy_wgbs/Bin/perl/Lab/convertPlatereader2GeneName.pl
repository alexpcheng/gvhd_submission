#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $file =  get_arg("file", "", \%args);
my $c = get_arg("c",0, \%args);

if (length($file) < 1 )
{
    print "No file given\n";
}

open(IN,$file) or die  ("Could not open file '$file'. \n");
while (my $line= <IN>)
{
        chomp($line);
	my @cols = split(/\t/,$line);
	if ($cols[$c] =~ m/__([A-Z|a-z|0-9|_|-]*)__/)
	{
	    my $gene= $1;
	    $cols[$c]= $gene;
	}
	print join("\t",@cols);
	print "\n";
}
close(IN);

__DATA__

convertPlatereader2GeneName.pl

   Gets a file with gene names in a platereader format and replaces them with gene names

    -file <file>:      The file to change.
    -c <number>:       The number of coloumn you want to convert (zero based, default 0).

