#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $ref_file =  get_arg("ref_file", "", \%args);
my $outlier_file = get_arg("outlier_file", "", \%args);

if (length($ref_file) < 1 )
{
    print "No reference file given\n";
}
if (length($outlier_file) < 1 )
{
    print "No outlier file given\n";
}

# read ref strains
open(REF, $ref_file) or die ("Could not open file '$ref_file'. \n");
my $first_line= <REF>;
my $second_line= <REF>;
my @ref_values = split(/\t/,$second_line);
my @ref_strains= split(/,/,$ref_values[0]);
close(REF);
print "ref_strains:\n";
print "@ref_strains\n";

# read outlier strain
open(OUT,$outlier_file) or die  ("Could not open file '$outlier_file'. \n");
my $changed=0;


while (my $strain= <OUT>)
{
	chomp($strain);
	my $loc=0;
	foreach my $ref_strain (@ref_strains)
	{
	    #print "outlier: $strain , ref: $ref_strain\n";
		if ($ref_strain eq $strain)
		{
		    print "found bad ref $strain \n";
			splice(@ref_strains,$loc,1); 
			$loc = $loc-1;
			$changed=1;
		}
		$loc= $loc+1;
	}
}
close(OUT);

# print new reference file if needed  
if ($changed)
{
	open (REF,">$ref_file") or die ("Could not open file '$ref_file'. \n"); 
	print REF $first_line;
	
	if (length(@ref_strains) ==1)
	{
	    print REF @ref_strains;
	}
	else
	{
	    print REF join(",",@ref_strains);
	}
	print REF ("\t");
	print REF ($ref_values[1]);
	close (REF);
}

__DATA__

remove_outliers_from_ref_file.pl

   Removes outlier strains from a reference file.

    -ref_file <file>:  		The reference file.
    -outlier_file <file>:       The outlier file.
