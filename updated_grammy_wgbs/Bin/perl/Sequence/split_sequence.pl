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

my $pos = get_arg("pos", 0, \%args);
my $merge = get_arg("merge", 0, \%args);

my @fragments = split (";", $pos);

while(<$file_ref>)
{
	chomp;
	my ($name, $sequence, $remainder) = split /\t/, $_, 3;
	
	print "$name\t$sequence";
	
	my $firstseq = 1;	
	foreach my $fragment (@fragments)
	{
		my ($start, $end) = split /-/, $fragment;
		
		if ($end eq "")
		{
			if (index($fragment, '-') == -1)
			{
				$end = $start;
			}
			else
			{
				$end = length ($sequence);
			}
		}
		
		if ((!$merge || $firstseq))
		{
			print "\t";
		}
		
		$firstseq = 0;
		print substr ($sequence, $start-1, ($end-$start+1));
	}
	
	if ($remainder ne "") { print "\t$remainder" };
	
	print "\n";
}

exit(0);

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------

__DATA__

split_sequence.pl <file_name> 

     Split a sequence into various (possibliy overlapping) parts and place those extracted
     parts in separate columns following the full-lenght sequence.
     
     -pos <fragments>   Semicolumn separated list of fragments. E.g. "1-10;15-30;12-20;22;26-"
                        Coordinates are 1-based
                        
     -merge             Merge all fragments into one sequence.
     

