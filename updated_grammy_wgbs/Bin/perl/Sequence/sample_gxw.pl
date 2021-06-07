#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $matrices_file_ref;
my $matrices_file = $ARGV[0];

open(MAT_FILE, $matrices_file) or die("Could not open file '$matrices_file'.\n");
$matrices_file_ref = \*MAT_FILE;

my %args = load_args(\@ARGV);
my $alphabet_str = get_arg("a", "A;C;G;T", \%args);
my $binding_site_num = get_arg("n", 1, \%args);

die("Binding site number smaller than one.\n") unless ($binding_site_num >= 1);

my @alphabet = split(/\;/, $alphabet_str);

my %matrix2distribution; 

my $matrix_name;

my $position_num;

#$sequence_char = $alphabet[$i];
while(<$matrices_file_ref>)
{
  chop;

  if (/<WeightMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
      $matrix_name = $1;
   
      $position_num = 0;
      
      $matrix2distribution{$matrix_name} = [];
  }
  elsif (/<Position.*Weights=[\"]([^\"]+)[\"]/)
  {
      my @row = split(/\;/, $1);

      #my $sequence_char = "";
      #my $max_probability = 0;
      
      ${$matrix2distribution{$matrix_name}}[$position_num]= [];
      for (my $j = 0; $j < @row; $j++)
      {
	  ${${$matrix2distribution{$matrix_name}}[$position_num]}[$j] = $row[$j];
      }
#      ${$matrix2distribution{$matrix_name}}[$position_num] = @row;

      $position_num++;
  }
  elsif (/<[\/]WeightMatrix/)
  {
      #print STDERR "$matrix_name\t$position_num\n";
      for (my $i = 0; $i < $position_num; $i++)
      {
	  my @tmp = @{${$matrix2distribution{$matrix_name}}[$i]};
	  #print STDERR "position $i distribution @tmp\n"
      }
      #print STDERR "\n";
  }
}

my @matrices = keys(%matrix2distribution);
#print STDERR "@matrices\n";
 
foreach my $name (@matrices)
{
    my $matrix_length =  scalar(@{$matrix2distribution{$name}});
    for (my $k = 0; $k < $binding_site_num; $k++)
    {
	#sample site
	my $site = "";
	my $sequence_char = "";
	for (my $m = 0; $m < $matrix_length; $m++)
	{
	    my $random_num = rand;
	    #print STDERR " rand $random_num\n";
	    my $cum_sum = 0;
	    $sequence_char = "";
	    for (my $index = 0; $index < scalar(@alphabet); $index++)
	    {
		if ($index == (scalar(@alphabet) - 1))
		{
		    $cum_sum = 1;
		}
		else
		{
		    $cum_sum +=  ${${$matrix2distribution{$name}}[$m]}[$index];
		}
		#print STDERR "cum sum $cum_sum rand num $random_num latest addition  ${${$matrix2distribution{$name}}[$m]}[$index]\n";
		
		if ($random_num <= $cum_sum)
		{
		    $sequence_char = $alphabet[$index];
		    $site .= $sequence_char;
		    last; 
		}
	    }
	}
	#plant site
	print "$name\t$k\t$site\n";
    }
}



__DATA__

sample_gxw.pl <gxw file> <output_file>

   Samples binding sites. Binding sites are randomly generated from the given PSSMs

   -a <str>:   Alphabet (default: 'A;C;G;T')

   -n <num>:   Number of binding sites for each matrix  (default: 1)

