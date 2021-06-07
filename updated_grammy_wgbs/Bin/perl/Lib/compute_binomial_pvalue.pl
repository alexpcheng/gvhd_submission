#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
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

my $pc = get_arg("pc", 0, \%args);
my $nc = get_arg("nc", 1, \%args);
my $rc = get_arg("rc", 2, \%args);
my $p = get_arg("p", "", \%args);
my $n = get_arg("n", "", \%args);
my $r = get_arg("r", "", \%args);
my $skip = get_arg("skip", 0, \%args);
my $two_sided = (length(get_arg ("2", "", \%args)) > 0);
my $ver2 = get_arg("ver2", "", \%args);

for (my $i=0; $i < $skip; $i++)
{
    my $l = <$file_ref>;
    chomp($l);
    print "$l\n";
}

while (my $line = <$file_ref>)
{
    chomp($line);
    my @row=split(/\t/,$line);

    if (length($p) > 0)
    {
	$row[$pc] = $p;
    }
    if (length($n) > 0)
    {
	$row[$nc] = $n;
    }
    if (length($r) > 0)
    {
	$row[$rc] = $r;
    }
    if ($two_sided and ($row[$rc] < ($row[$nc] - $row[$rc])))
    {
	$row[$rc] = ($row[$nc] - $row[$rc]);
    }
    my $pvalue;
    if ($ver2) {
	$pvalue = &ComputeBinomial($row[$pc],$row[$nc],$row[$rc]);
    }
    else {
	$pvalue = &ComputeBinomial2($row[$pc],$row[$nc],$row[$rc]);
    }

    if ($two_sided)
    {
       #corrected (Aug 05 2007, yair): add the line "$pvalue = ($pvalue < (1 - $pvalue)) ? $pvalue : (1 - $pvalue);"
       $pvalue = ($pvalue < (1 - $pvalue)) ? $pvalue : (1 - $pvalue);
       $pvalue = $pvalue*2;
       if ($pvalue > 1)
       {
	  $pvalue=1;
       }
    }
    print "$line\t$pvalue\n";
}


__DATA__


    compute_binomial_pvalue.pl

    calculates a binomial p-value for each row.

    -pc <num>:    Column that has probability of success on a single Bernoulli trial. (default: 0).
    -nc <num>:    Column that has total number of trials. (default: 1).
    -rc <num>:    Column that has number of successful trials. (default: 2).

    -p <num>:     Set probability of success on a single Bernoulli trial (instead of column). (default: off).
    -n <num>:     Set total number of trials. (default: off).
    -r <num>:     Set number of successful trials. (default: off).

    -2:           Two-sided test (default: one sided).
    -skip:        Number of header rows to skip (header rows will be printed).


