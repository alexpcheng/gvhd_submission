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
my $p_cleave = get_arg("p", 1, \%args);
my $p_wrong = get_arg("pw", 0, \%args);
my $type = get_arg("type", "I", \%args);
my $n_molecules = get_arg("n", 1, \%args);

while (<$file_ref>)
{
	chomp;
    my @row = split(/\t/, $_, 5);

	my $evidence1;
	
    if ($row[2] < $row[3])
    {
    	$evidence1 = $row[2] - 1;
    }
    else
    {
    	$evidence1 = $row[2] + 1;
    }

	my $evidence2 = $row[3];

	print "$row[0]\t$row[1]" . "_1\t$evidence1\t$evidence1\t$row[4]\n";
	print "$row[0]\t$row[1]" . "_2\t$evidence2\t$evidence2\t$row[4]\n";

}
__DATA__

collect_structure_evidence.pl

	Given a chr file of RNA sequences mapped to the genome, generates an output
	chr with a single-bp hit for:
	  - last base in RNA segment
	  - one base before the first base in RNA segment
		

