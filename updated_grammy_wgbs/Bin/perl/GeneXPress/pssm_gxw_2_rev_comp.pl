#!/usr/bin/perl

use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

# require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $name_suffix = get_arg("name_suffix", "", \%args);

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

my @pssm_lines = ();

while(<$file_ref>) {

  my $line = $_;

  if ( $line =~ /<Position/ ) {
    push(@pssm_lines, $line);
  }

  elsif ( $line =~ /<\/WeightMatrix>/ ) {
    my $num_pssm_lines = @pssm_lines;

    die "ERROR - failed to collect pssm \"Position\" lines\n" unless ( $num_pssm_lines > 0 );

    for ( my $i=$num_pssm_lines-1 ; $i >= 0 ; $i-- ) {
      my $curr_pssm_line = $pssm_lines[$i];
      my @weights = ();
      if ( $curr_pssm_line =~ /Weights="(.*)"/ ) {
	@weights = split(/;/,$1);
      }
      my $num_weights = @weights;
      my $rev_comp_weights = "";
      for ( my $j=$num_weights-1 ; $j > 0 ; $j-- ) {
	$rev_comp_weights = $rev_comp_weights . $weights[$j] . ";" ;
      }
      $rev_comp_weights = $rev_comp_weights . $weights[0] ;

      $curr_pssm_line =~ s/Weights=\".*\"/Weights=\"$rev_comp_weights\"/;
      print $curr_pssm_line;
    }

    print $line;

    @pssm_lines = ();
  }

  else {

    if ($name_suffix ne "" && $line =~ /\<WeightMatrix/)
      {

	 $line =~ s/\" Type=/$name_suffix\" Type=/;

       }
    print $line;
}
}

__DATA__

pssm_gxw_2_rev_comp.pl <pssm gxm file>

  Outputs a gxw with the pssm motif reverse complement.

  -name_suffix <str> adds asuffix to the PSSM name (for example: "_RC")
