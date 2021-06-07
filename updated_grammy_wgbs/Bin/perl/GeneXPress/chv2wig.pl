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
my $fixed_step = get_arg("fixed_step", 0, \%args);
my $name = get_arg("name", "", \%args);

print "track type=wiggle_0" . (length($name) > 0 ? " name=\"$name\"" : "") ."\n";

my $curr_chr = "";
my $curr_pos = -1;
my $last_offset = -1;
my $n_line = 0;

my $curr_sep_index = -1;
my $next_sep_index = 0;
my $vector_row_size = 0;
my $curr_value = 0;

while (<$file_ref>)
{
   chomp;
   $n_line++;
   
   (my $chr, my $id, my $start, my $end, my $type, my $width, my $offset, my $vals)=split /\t/;
   
   if (index($chr, " ") != -1)
   {
      die "Error: Chromosome name at line $n_line contains spaces: $chr\n";
   }

   if ($chr ne $curr_chr or $fixed_step == 1)
   {
      if ($fixed_step == 1)
      {
	 print "fixedStep chrom=$chr start=$start step=$offset span=$width\n";
      }
      else
      {
	 print "variableStep chrom=\"$chr\" span=$width\n";
      }
   }
   
   if ($n_line > 1 and $fixed_step == 1 and $offset != $last_offset)
   {
      die "Error: Step size at line $n_line ($offset) differs from the previous step size ($last_offset). Try not to use -fixed_step mode.\n";
   }
   $curr_chr = $chr;

   $last_offset = $offset;
   $curr_sep_index = -1;
   
   if ($start > $end)
   {
      die "Error: Supporting only positive starnd features (line $n_line).\n";
   }
   
   $vector_row_size = ($end - $start + 1) / $offset;

   for (my $i = 0; $i < $vector_row_size; $i++)
   {
      $next_sep_index = index ($vals, ";", ++$curr_sep_index);
      if ($next_sep_index==-1)
      {
	 $next_sep_index=length($vals);
      }
      $curr_value = substr ($vals, $curr_sep_index,  $next_sep_index - $curr_sep_index);
      $curr_sep_index = $next_sep_index;
      $curr_pos = $start + $i * $offset;
      if ($fixed_step != 1)
      {
	 print  "$curr_pos\t";
      }
      print "$curr_value\n";
   }
   
}

__DATA__

chv2wig.pl

  converts a chv file to wiggle format

  options:

    -name <str>:     Name of the output track (default: leave empty).
    -fixed_step:     Output wiggle in a fixed step mode (default: variable step). If chv has data in varying step the run will abort with an error.



