#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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
my $step_size = get_arg("s", 1, \%args);
my $window_size = get_arg("w", -1, \%args);
my $unique_id = get_arg("uniq_id", 0, \%args);

if ( $window_size == -1 ) {
  $window_size = $step_size;
}

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/, $_, 5);

    if ( $row[2] <= $row[3] ) { # feature is on the plus strand
      for (my $i = $row[2], my $uid = 1; $i <= $row[3] - $window_size + 1; $i+= $step_size, $uid+=1)
	{
	  my $uid_str = $unique_id ? "_$uid" : "";

	  print "$row[0]\t$row[1]$uid_str\t";
	  print ($i);
	  print "\t";
	  print ($i + $window_size - 1);

	  if ( @row > 4 ) {
	    print "\t$row[4]\n";
	  }
	  else {
	    print "\n";
	  }
	}
    }
    else { # feature is on the minus strand
      for (my $i = $row[2], my $uid = 1; $i >= $row[3] + $window_size - 1; $i-= $step_size, $uid+=1)
	{
	  my $uid_str = $unique_id ? "_$uid" : "";

	  print "$row[0]\t$row[1]$uid_str\t";
	  print ($i);
	  print "\t";
	  print ($i - $window_size + 1);

	  if ( @row > 4 ) {
	    print "\t$row[4]\n";
	  }
	  else {
	    print "\n";
	  }
	}
    }
}

__DATA__

expand_locations.pl <file>

   Given a tab-delimited location file in the format <chr><tab><name><tab><start><tab><end><tab>,
   expands the locations so that each location which spans start,stop has jumps every step
   (e.g., 10-12 would be repeated 10-11 and 11-12)

   -s <num>: Step size (default: 1)
   -w <num>: Window size (default: equal to the step size, such that the windows do not overlap)
   -uniq_id: If set, will give a uniq id to each feature (a concatenation of the old id and a uniq integer)

