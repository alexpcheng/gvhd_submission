#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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
my $loopseq = get_arg("l", "TTAT", \%args);
my $delim = get_arg("d", "", \%args);

while(<$file_ref>)
{
    chomp;

    my @row = split(/\t/);
	
	my $target_len = $row[3]-$row[2]+1;
	my $revseq = reverse (substr($row[1], $row[2]-1, $target_len));
    $revseq =~ tr/GCATgcat/CGTAcgta/;


	print $row[0] . "_E0\t" . substr($row[1], 0, $row[2]-1) . $delim . substr($row[1], $row[2]-1, $target_len) . $delim . substr($row[1], $row[3]) . "\n";
	print $row[0] . "_E1\t" . substr($row[1], 0, $row[2]-1) . $delim . substr($row[1], $row[2]-1, $target_len) . $delim . $loopseq . $delim . $revseq . $delim . substr($row[1], $row[3]) . "\n";

}

__DATA__


design_e0e1.pl <file>

	Takes a STAB file which also contains information about the location (start, end)
	of a miRNA target site, and designs the "E1" structure of those sequences.
	
	"E1" structures are structures where the miRNA target site is highly paired.
	
		-l <loop_sequence>	the sequence to use for the loop (default: TTAT).
		-d <delim>          delimiter to add between the target site and the
		                    flanking sequence (default: "")
		                    
		
		