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
 
`matlabrun.pl -m parseInputFile -p $file`;


__DATA__

usage: analyze_facs_data.pl <input_file>

Take the input file and analyzes it.

Input File Format:

DATA DIR NAME: 'data dir name'
ANALYSIS DIR NAME: 'analysis dir name'
% we allow either range: 1-96 or 1,2,3 or 1,2,3, 5-73
WELLS FOR FILE:
WELLS FOR GRAPHS:
DRAW TIME GRAPH FOR GROUPS:
GROUP NUMBER:
WELLS IN GROUP:

Analysis is created under /home/genie/Genie/Runs/RibosomalProteins/FACS/ANALYSIS DIR NAME

Data from directory DATA DIR NAME is processed.

analysis results appears textually in the analysis directory under well_stats.tab and group_stats.tab

Graphs produced:

fsc_ssc_density
fsc_ssc_scatter
yfp_of_filtered_hist
