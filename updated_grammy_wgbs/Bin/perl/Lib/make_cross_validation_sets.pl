#! /usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";

#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
sub create_cross_validation_sets
{
  my ($records_infile, $records_outfile_prefix, $records_outfile_suffix, $fixed, $order, $num_cross_validation_groups) = @_;

  if ($fixed == 1 and $order == 1)
  {
     print STDERR "Error: can not use both -fixed and -order\n";
     exit 1;
  }

  my @test_records;

  open(INFILE, "<$records_infile") or die "could not open $records_infile\n";

  my $num_records = &GetNumLinesInFile($records_infile);
  
  my $chunk_size = $num_records / $num_cross_validation_groups;
  my $max_records_per_cv_group = $chunk_size;
  if ($num_records / $num_cross_validation_groups !=  int($num_records / $num_cross_validation_groups))
  {
     $max_records_per_cv_group = int($num_records / $num_cross_validation_groups) + 1;
  }
  my @records_per_cv_group;

  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
    $test_records[$i] = "";
    $records_per_cv_group[$i] = 0;
  }

  if ($fixed == 1)
  {
     srand(0);
  }

  my $counter = 0;
  while (<INFILE>) 
  {
     my $done = 0;

     while (!$done) 
     {
	my $r;
	if ($order == 1)
	{
	   $r = int($counter/ $chunk_size);
	}
	else
	{
	   $r = int rand $num_cross_validation_groups; # 0 .. num_cross_validation_groups
	}

	if ($records_per_cv_group[$r] < $chunk_size) {
	   $test_records[$r] .= $_  ;
	   $records_per_cv_group[$r]++  ;
	   $done = 1		# 		;
	}
     }

     $counter++;
  }

  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
      open(test_handle, ">" . $records_outfile_prefix . "_test_" . ($i + 1) . $records_outfile_suffix);

    print test_handle $test_records[$i];
  }

  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
      open(train_handle, ">" . $records_outfile_prefix . "_train_" . ($i + 1) . $records_outfile_suffix);


    for (my $j = 0; $j < $num_cross_validation_groups; $j++)
    {
      if ($i != $j)
      {
	print train_handle $test_records[$j];
      }
    }
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0 and $ARGV[0] ne "--help")
{
  my %args = load_args(\@ARGV);

  create_cross_validation_sets($ARGV[0],
			       get_arg("o", $ARGV[0], \%args),
			       get_arg("os", "", \%args),
			       get_arg("fixed", 0, \%args),
			       get_arg("order", 0, \%args),
			       get_arg("g", 5, \%args));
}
else
{
  print "Usage: make_cross_validation_sets.pl <input_file> \n\n";
  print "      -o  <output file prefix> : prefix of the output file (default is same as input file)\n";
  print "      -os <output file suffix> : suffix of the output file (default is the empty word)\n";
  print "      -fixed                   : Use a fixed seed in the randomization\n";
  print "      -order                   : Split file to chunks (like the shell split command)\n";
  print "      -g <cv number>           : number of cross validation groups to make (default 5)\n\n";
}
