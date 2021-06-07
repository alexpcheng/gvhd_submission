#!/usr/bin/perl

use strict;
use Scalar::Util qw(looks_like_number);

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";


# reading arguments:

if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file_name = $ARGV[0];
if (length($file_name) < 1 or $file_name =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  shift(@ARGV);
  open(FILE, $file_name) or die("Could not open file '$file_name'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $pval_column = get_arg("c", 0, \%args);
my $alpha = get_arg("alpha", 0.05, \%args);
my $type = get_arg("t", "Bonferroni", \%args);
die "ERROR - Unsupported correction type '$type'\n" unless ( $type eq "Bonferroni" or $type eq "FDR" );

my $num_rows_to_skip = get_arg("skip", 0, \%args);
my $precision = get_arg("p", 4, \%args);

my $apply_filter = get_arg("apply_filter", "", \%args);

# done reading arguments

my @pvalues = ();
my @inputs = ();

while ( <$file_ref> ) {
  if ( $num_rows_to_skip > 0 ) {
    $num_rows_to_skip--;
    next;
  }

  my $curr_line = $_;
  chomp($curr_line);

  if ($apply_filter) { 
      push(@inputs, $curr_line); 
  }
  my @line = split(/\t/,$curr_line);

  die "ERROR - p-value not numeric (check p-value column index and remember to skip headers)\n" unless ( looks_like_number($line[$pval_column]) );

  push(@pvalues, $line[$pval_column]);
}

my $num_pvalues = @pvalues;
my $corrected_pvalue = $alpha;

if ( $type eq "Bonferroni" ) { $corrected_pvalue = Bonferroni($alpha,$num_pvalues); }
elsif ( $type eq "FDR" ) { $corrected_pvalue = Fdr($alpha,$num_pvalues,\@pvalues); }


if ($apply_filter) { # filter all the rows and print only the ones with p-values under the threshold
    foreach my $curr_line (@inputs) {
	my @line = split(/\t/,$curr_line);
	if ($line[$pval_column] <= $corrected_pvalue) {
	    print $curr_line."\n";
	}
    }
}
else { # just print the corrected p-value threshold
    print format_number($corrected_pvalue, $precision) . "\n";
}


__DATA__

  compute_multiple_hypotheses_corrected_pvalue.pl <file name> [options]

  Given a column of test p-values, within a tab delimited file, performs multiple hypotheses correction on it,
  and returns the corrected p-value. Currently supports only correction for independent tests.

  -c <int>:          P-values column index (0-based) in the input file (default: 0)
  -t <str>:          Type of correction (Bonferroni/FDR) (default: Bonferroni)
  -alpha <double>:   P-value threshold before correcting (default: 0.05)

  -skip <int>:       Skip given number of rows (default: 0)
  -p <int>:          Output precision (default: 4)

  -apply_filter:     Instead of outputting the corrected p-value, applies this as a filter to every input row and 
                     outputs rows only if their p-value is less than or equal to the corrected p-value
