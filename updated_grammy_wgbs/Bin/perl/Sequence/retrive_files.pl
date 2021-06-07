#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

# =============================================================================
# Main part
# =============================================================================

# reading arguments
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
my $db = get_arg("db", "embl", \%args);
my $style = get_arg("style", "raw", \%args);

while (<$file_ref>) {
  my $acc = $_;
  chomp $acc;

  my $url = "http://www.ebi.ac.uk/cgi-bin/dbfetch?db=".$db."&id=".$acc."&style=".$style;
  system("wget \"$url\" -O $acc.$style");
}


# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

retrive_files.pl <file_name>

Take as input a list of accession numbers and retrive the relevant database entries.
The output is saved in a seperate file for each accession number.

OPTIONS:
  -db <database name>      The database to retrive from (Default = embl).
                           Possible databases:
                             - medline
                             - refseq
                             - interpro
                             - embl, emblcon, emblcds, emblsva
                             - uniprotkb, unisave, uniref100, uniref90, uniref50, uniparc
                             - ipi
                             - pdb
                             - hgvbase
                             - genomereviews
                             - epo_prt, jpo_prt, uspto_prt
  -style <name>            Output files style (Default = raw).
                           Possible output styles:
                             - html
                             - raw
