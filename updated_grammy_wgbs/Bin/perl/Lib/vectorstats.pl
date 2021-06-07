#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $matlabPath = "matlab";
my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}
my $fileName = $ARGV[0];
if (length($fileName) < 1 or $fileName =~ /^-/) 
{
  print STDERR "Must supply vector file name\n";
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $statType = get_arg("s", 0, \%args);

my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); vectorStats('$fileName', $statType)\" > /dev/null";

print STDERR "Calling Matlab with: $command\n";

system ($command) == 0 || die "Failed to run Matlab\n";

# Echo the result of matlab (should be placed in matlab.out)

my $outFile = 'matlab.out';
open(OUTFILE, $outFile) || die "Could not open 'matlab.out'\n";
my @lines = <OUTFILE>;
close(OUTFILE);
print @lines;

system ("rm matlab.out");


__DATA__

vectorstats.pl <file_name> -s <stat_type>

	Calculates the required statistics of the given vector. The vector is given
	in a file. Result value is printed to standard output.
	
	-s	statistics type.
		0 = threshold of the LOG values of the given vector.


