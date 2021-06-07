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

my $number_mutations_per_sequence = get_arg("n", 1, \%args);
my $num_point_mutations = get_arg("p", 0, \%args);
my $deletion_mutations_str = get_arg("d", "0,5", \%args);

my @row = split(/\,/, $deletion_mutations_str);
my $num_deletion_mutations = $row[0];
my $deletion_mutation_size = $row[1];

my @id2char;
$id2char[0] = "A";
$id2char[1] = "C";
$id2char[2] = "G";
$id2char[3] = "T";

while(<$file_ref>)
{
  chop;

  @row = split(/\t/);

  my $sequence_length = length($row[1]);

  for (my $i = 0; $i < $number_mutations_per_sequence; $i++)
  {
      if ($num_point_mutations > 0)
      {
	  my @sequence;
	  for (my $j = 0; $j < $sequence_length; $j++)
	  {
	      $sequence[$j] = substr($row[1], $j, 1);
	  }
	  
	  my @mutate_positions;
	  for (my $j = 0; $j < $sequence_length; $j++)
	  {
	      $mutate_positions[$j] = $j;
	  }
	  for (my $j = 0; $j < $sequence_length; $j++)
	  {
	      my $p = int(rand($sequence_length));
	      my $tmp = $mutate_positions[$j];
	      $mutate_positions[$j] = $mutate_positions[$p];
	      $mutate_positions[$p] = $tmp;
	      #print STDERR "mutate_positions[$j] <-> mutate_positions[$p]\n";
	  }
	  
	  for (my $j = 0; $j < $num_point_mutations; $j++)
	  {
	      my $position = $mutate_positions[$j];
	      
	      my $new_char = $id2char[int(rand(4))];
	      while ($new_char eq $sequence[$position])
	      {
		  $new_char = $id2char[int(rand(4))];
	      }
	      
	      $sequence[$position] = $new_char;
	  }

	  print "$row[0]-N$i-P$num_point_mutations\t";
	  for (my $j = 0; $j < $sequence_length; $j++)
	  {
	      print "$sequence[$j]";
	  }
	  print "\n";
      }
  }

  for (my $i = 0; $i < $number_mutations_per_sequence; $i++)
  {
      if ($num_deletion_mutations > 0)
      {
	  my $str = $row[1];
	  for (my $j = 0; $j < $num_deletion_mutations; $j++)
	  {
	      my $p = int(rand(length($str) - $deletion_mutation_size + 1));
	      #print STDERR "Length=" . length($str) . " Position=$p Str=$str\n";

	      my $new_str = substr($str, 0, $p);
	      $new_str .= substr($str, $p + $deletion_mutation_size, length($str) - ($p + $deletion_mutation_size));
	      $str = $new_str;
	  } 
	  print "$row[0]-N$i-D$num_deletion_mutations-S$deletion_mutation_size\t$str\n";
      }
  }

  if ($num_point_mutations == 0 and $num_deletion_mutations == 0)
  {
      print "$_\n";
  }
}

__DATA__

mutate_sequences.pl <file>

   Given a stab file, mutate each sequence in a predefined way

   -n <num>:     Number of times to mutate each sequence (default: 1)

   -p <num>:     Number of point mutations to perform (default: 0)
   -d <num,len>: Number <num> of deletion mutations of length <len> to perform (default: 0,5)

