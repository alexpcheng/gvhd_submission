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

my $rna = get_arg("R", 0, \%args);

my $pivot_base = get_arg("b", "", \%args);
die "ERROR - please input only a single base using the -B option.\n" if ( length($pivot_base) > 1 );
if ( $pivot_base eq "U" ) { $pivot_base = "T"; }

my $suffix = get_arg("suffix", "", \%args);

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);   
    
    if ($rna) { $row[1] =~ tr/U/T/; }
    
    my $do_rev_comp = 1;

    if ( $pivot_base ne "") {
	my $pivot_base_fraction = &ComputeNucleotideSetFraction($row[1],$pivot_base,0);
	my $pivot_base_complement = &ReverseComplement($pivot_base);
	my $pivot_base_complement_fraction = &ComputeNucleotideSetFraction($row[1],$pivot_base_complement,0);
	$do_rev_comp = $pivot_base_fraction < $pivot_base_complement_fraction ;
    }

    my $revcomp = $do_rev_comp ? &ReverseComplement($row[1]) : $row[1];
    my $name = $do_rev_comp ? $row[0] . $suffix : $row[0];

    if ($rna) { $revcomp =~ tr/T/U/; }

    print "$name\t$revcomp\n";
}

__DATA__

stab2reverse_complement.pl <file>

   Takes in a stab sequence file and reverse complements each sequence
   
   Options:
   
    -R             Treat the sequence as RNA sequence (AGCU alphabet).

    -b <Base>      Base can be A/C/G/T/U. If given, then a sequence will be reverse complemented
                   only if its fraction of 'Base' is less than that of its complementing base.

    -suffix <str>  Add 'str' as suffix to the original sequence name in case it is reverse complemented.
