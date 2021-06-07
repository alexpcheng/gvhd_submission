#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $matlabPath = "matlab";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";

my $dinuc_input_file = get_arg("dinucf", "", \%args);
my $output_figure_header_name = get_arg("figh", "Matlab Figure", \%args);
my $output_figure_file_name = get_arg("fig", "matlab_figure", \%args);
my $output_figure_file_format = get_arg("figmat", "fig", \%args);

my $mfile = "nucleosome_model_dinucleotide_analysis";
my $params = "(\'$dinuc_input_file\',\'$output_figure_header_name\',\'$output_figure_file_name\',\'$output_figure_file_format\')";
my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";

print STDERR "Calling Matlab with: $command\n";

system ($command) == 0 || die "Failed to run Matlab\n";

# Echo the result of matlab (should be placed in matlab.out)

my $outFile = 'matlab.out';

if (open(OUTFILE, $outFile))
{
	my @lines = <OUTFILE>;
	close(OUTFILE);
	print @lines;
	system ("rm matlab.out");
}

__DATA__

nucleosome_model_dinucleotide_correlation_analysis.pl

    Run a correlation analysis on the frequency matrix of dinucleotides (for the nucleosome model).

    -dinucf <file>             The dinucleotide frequencies matrix
    -figh <str>                The figure's template header name
    -fig <file_name>           The figure's template file name
    -figmat <file_format>      The figure's file format (default: "fig")

