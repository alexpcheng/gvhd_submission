#!/usr/bin/perl

use strict;

# require "$ENV{PERL_HOME}/Lib/load_args.pl";

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

# my %args = load_args(\@ARGV);

my $alphabet_size = 0;
my $motif_length = 0;

my @feature_lines = ();
my @feature_line_keys = ();

while(<$file_ref>) {

  my $line = $_;

  if ( $line =~ /<WeightMatrix/ ) {
    if ( $line =~ /EffectiveAlphabetSize=\"(\d+)\"/ ) {
      $alphabet_size = $1;
    }
    if ( $line =~ /PositionsNum=\"(\d+)\"/ ) {
      $motif_length = $1;
    }
    print $line;
  }

  elsif ( $line =~ /<LettersAtPosition/ ) {
    my $rev_comp_letter;
    my $rev_comp_pos;
    if ( $line =~ /Letters=\"(\d+)\"/ ) {
      $rev_comp_letter = $alphabet_size - $1 - 1;
    }
    if ( $line =~ /Position=\"(\d+)\"/ ) {
      $rev_comp_pos = $motif_length - $1 - 1;
    }
    $line =~ s/Letters=\"\d+\"/Letters=\"$rev_comp_letter\"/;
    $line =~ s/Position=\"\d+\"/Position=\"$rev_comp_pos\"/;

    push(@feature_lines, $line);
    push(@feature_line_keys, $rev_comp_pos);
  }

  elsif ( $line =~ /<\/SequenceFeature>/ ) {
    my $num_lines = @feature_line_keys;

    die "ERROR - failed to collect feature \"LettersAtPosition\" lines\n" unless ( $num_lines > 0 );

    my @sorted_feature_line_keys = sort { $a <=> $b } @feature_line_keys;
    for (my $i=0 ; $i < $num_lines ; $i++) {
      my $curr_key = $sorted_feature_line_keys[$i];
      for (my $j=0 ; $j < $num_lines ; $j++ ) {
	if ( $feature_line_keys[$j] == $curr_key ) {
	  print $feature_lines[$j];
	  last;
	}
      }
    }

    print $line;

    @feature_lines = ();
    @feature_line_keys = ();
  }

  else {
    print $line;
  }
}

__DATA__

fmm_gxw_2_rev_comp.pl <fmm gxm file>

  Outputs a gxw with the fmm motif reverse complement.

