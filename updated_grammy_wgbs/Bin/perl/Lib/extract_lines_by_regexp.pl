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
if (length($file) < 1 or $file =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  open(FIN, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FIN;
}

my %args = load_args(\@ARGV);

my $regexp_from = get_arg("from", "", \%args);
print "Regular expression 'from' not given.\n" if ( $regexp_from eq "" );

my $regexp_to = get_arg("to", "", \%args);
print "Regular expression 'to' not given.\n" if ( $regexp_to eq "" );

my $from_inclusive = get_arg("from_inclusive", "true", \%args);
if ( $from_inclusive eq "true" ) { $from_inclusive = 1; }
else { $from_inclusive = 0; }

my $to_inclusive = get_arg("to_inclusive", "true", \%args);
if ( $to_inclusive eq "true" ) { $to_inclusive = 1; }
else { $to_inclusive = 0; }

my $reached_from = 0;
if ( $regexp_from eq "" ) {
  $reached_from = 1;
}

my $remove = get_arg("remove", 0, \%args);

my $out_file_name = get_arg("out_file", "", \%args);
my $out_file_ref;
if ( $out_file_name eq "" ) {
  $out_file_ref = \*STDOUT;
}
else {
  open(FOUT, ">$out_file_name") or die("Could not open output file '$out_file_name'.\n");
  $out_file_ref = \*FOUT;
}

if ( $remove ) {
  ExtractAllFileLinesNotBetweenRegexps($file_ref, $out_file_ref, $regexp_from, $regexp_to, $from_inclusive, $to_inclusive);
}
else {
  ExtractFileLinesBetweenRegexps($file_ref, $out_file_ref, $regexp_from, $regexp_to, $from_inclusive, $to_inclusive);
}

close FIN;
close FOUT;


__DATA__

extract_lines_by_regexp.pl <file>

  Extracts lines from a file between two given regexps, or extract all lines not between them.

  -from <str>:                   regexp from which to extract.
  -to <str>:                     regexp until which to extract
  -from_inclusive <true/false>:  true - line where 'from' is found will also be extracted. (default: true)
  -to_inclusive <true/false>:    true - line where 'to' is found will also be extracted. (default: true)
  -remove:                       if set, extract all lines NOT between regexps.
  -out_file <str>:               name of output file. if given, output will be printed into output file
                                 (else to standard output).

