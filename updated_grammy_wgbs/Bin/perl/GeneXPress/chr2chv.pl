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
my $trim_tail = get_arg("tt", "0", \%args);
my $verbose = get_arg("v", 0, \%args);
my $max_vals = get_arg("m", 0, \%args);
my $single_bp = get_arg("1", 0, \%args);

my $curChr = "";
my $curName  = "";
my $curType = "";
my $segLeft = -1;
my $segRight = -1;
my $lastLeft = 0;
my $lastRight = 0;
my $id = 0;
my $desiredSegLen = 0;
my $desiredSegWidth = 0;
my $desiredDirection = undef;
my $segLen;
my $segWidth;
my $direction = 0;
my $left = -1;
my $right = -1;
my $n_vals = 0;

my @values;

while(<$file_ref>)
{
	chop;
	
	# Read current line
	(my $chr, my $name, my $start, my $end, my $type, my $value) = split("\t");

	$direction = $start <= $end;
	$left = $direction ? $start : $end;
	$right = $direction ? $end : $start;

	$segLen = $left - $lastLeft;
	$segWidth = $right - $left + 1;

	if ($single_bp){
	  if ($segWidth>1) {
	    die ("All features must be of length 1 when using \"-1\" flag!\n");
	  }
	}

	$n_vals++;

	# If different from last line -- dump vector
	
	if ( ($chr ne $curChr) || 
	     ($type ne $curType) || 
	     ($desiredSegWidth ne $segWidth) ||
	     (($desiredSegLen ne 0) && ($desiredSegLen ne $segLen)) ||
	     ((defined($desiredDirection)) && ($desiredDirection != $direction)) ||
	     (($max_vals > 0) && ($n_vals > $max_vals))
	    )
	{		
		printvalues();
	
		# Reset "current" values
		$curChr = $chr;
		$curName = $name;
		$curType = $type;

		$segLeft = $left;
		$segRight = $right;
		$desiredSegLen = 0;
		$desiredSegWidth = $segWidth;
		$desiredDirection = $direction;
		
		$n_vals = 1;

		if ($verbose == 1) 
		{
		   print STDERR "Processing Chromosome $chr, ID=$name, Type=$type... ";
		}
	}
	else
	{
		$desiredSegLen = $segLen;
		$desiredSegWidth = $segWidth;
	}

	if ($single_bp){
	  $desiredSegLen=1;
	}


	# Keep collecting values
	$lastLeft = $left;
	$lastRight = $right;
	$segRight = $right;

	push (@values, $value);
}

# Dump any leftovers
printvalues();


sub printvalues
{
	# print current values
	# <chr> <id> <start> <end> <type> <N1> <N2> <Values>

	my $size = scalar @values;
	if (!$size) { return; }
	if ($verbose == 1) 
	{
	   print STDERR @values . " values found (offset $desiredSegLen, width $desiredSegWidth).";
	}

	if ($trim_tail)
	{
		my $trim_start = $size - $trim_tail;
		
		if ($trim_start < 1)
		{
			$trim_start = 0;
		}
		
		splice (@values, $trim_start);
		$size = scalar @values;
		$lastRight -= $trim_tail;
		
		if ($verbose == 1) 
		{
		   print STDERR " Trimmed $trim_tail values from end. New length is $size.";
		}
	}
	
	if ($verbose == 1) 
	{
	   print STDERR "\n";
	}

	if (!$size) { return; }

	my $contig = $desiredDirection ? "\t$segLeft\t$segRight\t" : "\t$segRight\t$segLeft\t";
	print "$curChr\t$curName" . ($id > 0 ? "_$id" : "") . $contig . "$curType\t$desiredSegWidth\t$desiredSegLen\t";
	print join (";", @values);
	print "\n";

	@values = ();
}		



__DATA__

chr2chv.pl <file> 

    Creates vector file from a chr file. The vector file has the format 
	
		<chr> <id> <start> <end> <feature_name> <single value width> <consec. values distance> <Values>

	which can easily be translated into a gxt vector. 
	
	
	-tt <num>     Trim <num> entries from tail of each vector.

        -v            Verbose mode (print log to stderr)

        -m <num>      Allow maximum num values in an entry.

        -1            Force 1 bp width and 1 bp distance in chv output (requires single bp input).

   NOTE: Assumes that the file is sorted by type Chromosome (lexicographic), Start (numeric), End (Numeric)

