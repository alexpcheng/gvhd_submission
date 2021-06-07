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



my %genome;

my $global_counter = 0;
while(<$file_ref>)
{
  chop;
  $global_counter++;
  if ($global_counter % 10000 == 0) { print STDERR "."; }

  my @row = split(/\t/);
  my $chromosome_id = $row[0];
  my $start = $row[2] < $row[3] ? $row[2] : $row[3];
  my $end = $row[2] < $row[3] ? $row[3] : $row[2];

  # check if the new location ovelaps any previously chosen location
  my $overlap = 0;
  for (my $i = $start; ($i <= $end) and ($overlap == 0) ; $i++)
    {
      if(vec($genome{$chromosome_id},$i,1) == 1)
	{
	  $overlap = 1;
	}
    }
  
  # if the new location does not overlap any previous location - mark it in the %genome and print to the output file
  if($overlap == 0)
    {
       for (my $i = $start; $i <= $end ; $i++)
	 {
	   vec($genome{$chromosome_id},$i,1) = 1;
	 }
       print "$_\n";
     }
}

print STDERR "Done.\n";


__DATA__

find_unique_genomic_locations_quick.pl <file>

   Given a location file in the format <chr><tab><name><tab><start><tab><end><tab>...
   takes the first set of locations that have no overlap with any other locations.

   Note: Maintains in memory a (true) bit vector marking the positions that are taken.


