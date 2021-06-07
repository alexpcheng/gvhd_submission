#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $num_sequences = get_arg("n", 10, \%args);
my $sequence_length = get_arg("l", 500, \%args);
my $alphabet = get_arg("a", "ACGT", \%args);
my $distribution_str = get_arg("d", "", \%args);
my @distribution = split(/\,/, $distribution_str);
my $use_fasta_format = get_arg("f", "0", \%args);
#print STDERR "Distribution = (@distribution)\n";

my $alphabet_size = length($alphabet);

for (my $i = 1; $i <= $num_sequences; $i++)
{
    if ( $use_fasta_format )
    {
      print ">Seq$i\n";
    }
    else
    {
      print "Seq$i\t";
    }

    for (my $j = 0; $j < $sequence_length; $j++)
    {
	if (length($distribution_str) == 0)
	{
	  my $r = int(rand($alphabet_size));

	  print substr($alphabet, $r, 1);
	}
	else
	{
	  my $r = rand();

	  my $sum = 0;
	  for (my $k = 0; $k < $alphabet_size; $k++)
	  {
	    $sum += $distribution[$k];

	    if ($r <= $sum)
	    {
	      print substr($alphabet, $k, 1);
	      last;
	    }
	  }
	}
    }

    print "\n";
}

__DATA__

generate_random_sequences.pl <file>

   Generates random sequences

   -n <num>:     Number of sequences to generate (default: 10)
   -l <num>:     Length of each sequence (default: 500)

   -a <str>:     Alphabet (default: ACGT)

   -d <num>:     Probability distribution over the alphabet (default: uniform)
                 Format example on alphabet ACGT (-d 0.3,0.4,0.1,0.2)

   -f      :     Output in FASTA format.
