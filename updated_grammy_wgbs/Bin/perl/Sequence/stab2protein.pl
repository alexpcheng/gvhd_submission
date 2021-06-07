#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


##################################
#
my %genetic_code = (
		    "TTT" => "F",
		    "TTC" => "F",
		    "TTA" => "L",
		    "TTG" => "L",
		    "TCT" => "S",
		    "TCC" => "S",
		    "TCA" => "S",
		    "TCG" => "S",
		    "TAT" => "Y",
		    "TAC" => "Y",
		    "TAA" => "x",
		    "TAG" => "x",
		    "TGT" => "C",
		    "TGC" => "C",
		    "TGA" => "x",
		    "TGG" => "W",
		    "CTT" => "L",
		    "CTC" => "L",
		    "CTA" => "L",
		    "CTG" => "L",
		    "CCT" => "P",
		    "CCC" => "P",
		    "CCA" => "P",
		    "CCG" => "P",
		    "CAT" => "H",
		    "CAC" => "H",
		    "CAA" => "Q",
		    "CAG" => "Q",
		    "CGT" => "R",
		    "CGC" => "R",
		    "CGA" => "R",
		    "CGG" => "R",
		    "ATT" => "I",
		    "ATC" => "I",
		    "ATA" => "I",
		    "ATG" => "M",
		    "ACT" => "T",
		    "ACC" => "T",
		    "ACA" => "T",
		    "ACG" => "T",
		    "AAT" => "N",
		    "AAC" => "N",
		    "AAA" => "K",
		    "AAG" => "K",
		    "AGT" => "S",
		    "AGC" => "S",
		    "AGA" => "R",
		    "AGG" => "R",
		    "GTT" => "V",
		    "GTC" => "V",
		    "GTA" => "V",
		    "GTG" => "V",
		    "GCT" => "A",
		    "GCC" => "A",
		    "GCA" => "A",
		    "GCG" => "A",
		    "GAT" => "D",
		    "GAC" => "D",
		    "GAA" => "E",
		    "GAG" => "E",
		    "GGT" => "G",
		    "GGC" => "G",
		    "GGA" => "G",
		    "GGG" => "G"
);
#
##################################



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
my $frame_shift = get_arg("fs", 0, \%args);
die "ERROR - frame shift can only be one of {0,1,2}\n" unless ( $frame_shift == 0 or $frame_shift == 1 or $frame_shift == 2 );
my $pfs = get_arg("pfs", 0, \%args);
my $no_assert_3 = get_arg("no_assert_3", 0, \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  die "ERROR - $row[0] orf sequence contains characters other than {A,C,G,T}\n" unless ( $row[1] =~ /^[A|C|G|T]+$/ );
  die "ERROR - $row[0] orf length does not divide by 3\n" if ( (!$no_assert_3) and $frame_shift == 0 and length($row[1]) % 3 != 0 );

  print "$row[0]\t";

  my $to_be_translated = $row[1];

  if ( $frame_shift > 0 ) {
    if ( $to_be_translated =~ /(.{$frame_shift})(.*)/ ) {
      $to_be_translated = $2;
    }
    print "." if ( $pfs and $frame_shift == 1 );
    print ".." if ( $pfs and $frame_shift == 2 );
  }

  while ( length($to_be_translated) >= 3 ) {
    if ( $to_be_translated =~ /(.{3})(.*)/ ) {
      my $next_codon = $1;
      $to_be_translated = $2;
      print $genetic_code{$next_codon};
    }
  }

  if ( length($to_be_translated) > 0 and $pfs ) {
    print "." if ( length($to_be_translated) == 1 );
    print ".." if ( length($to_be_translated) == 2 );
  }

  print "\n";
}

__DATA__

stab2protein.pl <file>

  Given a DNA ORFs stab, outputs the encoded protein sequences (also in stab format).
  Asserts that the given sequences alphabet is {A,C,G,T}.
  By default, will also assert that the sequences lengths divide by 3.
  The terminating codon is translated to the 'x' character.

  Other Options
  -------------

  -fs <i>:          Translate assuming a frame shift of 'i' (0, 1 or 2) bases (default: 0).
                    When 'i' is 1 or 2 the sequences lengths are allowed not to divide by 3, and each sequence
                    will be translated except the prefix of length 'i', and a suffix shorter than 3 bases.

  -pfs:             If this flag is set, then non-translated bases (due to frame shift) will be printed as the '.' character.

  -no_assert_3:     If this flag is set, then will not assert that the sequences lengths divide by 3, even if the
                    frame shift is 0.
