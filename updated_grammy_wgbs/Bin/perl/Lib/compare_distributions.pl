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

my $statistic = get_arg("s", "KS", \%args);
my $skip_rows = get_arg("skip", 0, \%args);

my $r = int(rand(100000));

for (my $i = 0; $i < $skip_rows; $i++) { my $line = <$file_ref>; }

my @rows;
while(<$file_ref>)
{
    chop;

    push(@rows, $_);
}

my $result = "";
for (my $i = 0; $i < @rows; $i++)
{
    my @row = split(/\t/, $rows[$i]);

    print STDERR "Comparing $row[0] against all...\n";

    open(OUTFILE_MATRIX, ">tmp_matrix_$r");
    print OUTFILE_MATRIX "Row\t$row[0]\n";
    for (my $j = 1; $j < @row; $j++)
    {
	print OUTFILE_MATRIX "1$j\t1\n";
    }
    close(OUTFILE_MATRIX);

    for (my $j = $i + 1; $j < @rows; $j++)
    {
	my @row1 = split(/\t/, $rows[$j]);

	open(OUTFILE_DATA, ">tmp_data_$r");
	print OUTFILE_DATA "Row\t$row1[0]\n";
	for (my $k = 1; $k < @row; $k++)
	{
	    print OUTFILE_DATA "1$k\t$row[$k]\n";
	}
	for (my $k = 1; $k < @row1; $k++)
	{
	    print OUTFILE_DATA "2$k\t$row1[$k]\n";
	}
	close(OUTFILE_DATA);

	if (length($result) == 0)
	{
	    $result = `compute_enrichment.pl -m tmp_matrix_$r -a tmp_data_$r -s KolmogorovSmirnov`;
	}
	else
	{
	    $result .= `compute_enrichment.pl -m tmp_matrix_$r -a tmp_data_$r -s KolmogorovSmirnov | body.pl 2 -1`;
	}
    }
}

print "$result";

system("rm -f tmp_matrix_$r tmp_data_$r");

__DATA__

compare_distributions.pl <file>

   Given a file where each row represents a distribution, compares them using 
   a T-test or a Kolmogorov Smirnov test. The file format is:
   <name><tab><data1><tab><data2><tab><data3><tab>...
   <name><tab><data1><tab><data2><tab>...

   NOTE 1: uses map_learn (invokes a call per each comparison, so may be slow)
   NOTE 2: each row can have a different number of items

   -s <str>:    Statistic to use (KS/TTest) (default: KS)

   -skip <num>: Number of rows to skip (default: 0)

