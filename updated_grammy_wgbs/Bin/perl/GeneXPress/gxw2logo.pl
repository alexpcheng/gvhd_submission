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

my $output_prefix = get_arg("o", "", \%args);
my $alphabet_str = get_arg("a", "A,C,G,T", \%args);

my @alphabet = split(/\,/, $alphabet_str);
my $sequence_logo_bin = "$ENV{BIN_HOME}/SeqLogo/weblogo/seqlogo";

my $logo_max_bits = get_arg("B", 0, \%args);
my $logo_max_bits_flag = ($logo_max_bits == 0) ? "" : "-B $logo_max_bits";

my $r = int(rand(100000));
my $tolerance = 1000;

my $weight_matrix = "";
my @probabilities = ();
while(<$file_ref>)
{
    chop;

    if (/<WeightMatrix Name=[\"]([^\"]+)[\"]/)
    {
	$weight_matrix = $1;
	$weight_matrix =~ s/ /_/g;


    }
    elsif (/<[\/]WeightMatrix>/)
    {
	if (length($weight_matrix) > 0)
	{
	    &ProcessWeightMatrix();
	}
	$weight_matrix = "";
	@probabilities = ();
    }
    elsif (/<Position Weights=[\"]([^\"]+)[\"]/)
    {
	push(@probabilities, $1);
	#print STDERR "pushing $weight_matrix $1\n";
    }
}

sub ProcessWeightMatrix
{
    my @sequences;

    foreach my $probs (@probabilities)
    {
	my @row = split(/\;/, $probs);
	for (my $i = 1; $i < @row; $i++)
	{
	    $row[$i] += $row[$i - 1];
	}
	#print STDERR "R @row\n";

	my $current_char_index = 0;
	for (my $i = 0; $i < $tolerance; $i++)
	{
	    while ($i / $tolerance > $row[$current_char_index] and $current_char_index < @row - 1)
	    {
		$current_char_index++;
	    }

	    $sequences[$i] .= "$alphabet[$current_char_index]";
	}
    }

    open(OUTFILE, ">tmp.$r");
    for (my $i = 0; $i < $tolerance; $i++)
    {
	print OUTFILE ">S$i\n";
	print OUTFILE "$sequences[$i]\n";
    }

 

    print "$sequence_logo_bin -f tmp.$r -F png -o $output_prefix$weight_matrix -abcMnY $logo_max_bits_flag; rm tmp.$r\n";
    `$sequence_logo_bin -f tmp.$r -F png -o $output_prefix$weight_matrix -abcMnY $logo_max_bits_flag; rm tmp.$r`;
}

__DATA__

gxw2logo.pl 

    Creates logo images from a gxw file

    -o <name>: Prefix for the images (e.g., Output/matrix_)

    -a <str>:  Alphabet, comma-separated  (default: A,C,G,T)

    -B <num>:  Number of bits in bar (default: maximum bits, e.g. 2 for DNA sequence)

