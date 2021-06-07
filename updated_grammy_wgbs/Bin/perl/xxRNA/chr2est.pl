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
my $no_overlap = get_arg("nol", 0, \%args);
my $half_open = get_arg("ho", 0, \%args);

my $curID = "";
my $curChr;
my $curStrand;
my $curStart;
my $curEnd;
my $curValue;
my $curnExons;
my @curExonS;
my @curExonE;
my @curValues;

while (<$file_ref>)
{
	chomp;

	my ($chrom, $id, $start, $end, $type, $value) = split("\t");
	
	$start--;
	$end--;
	
	if ($half_open)
	{
		if ($start > $end) { $start++; } else { $end++; }
	}
	
	if ($curID ne $id)
	{
		if ($curID ne "")
		{
			if ($curStrand eq "?") { $curStrand = '+'; }
			
			print "chr$curChr\t$curStrand\t$curID\t$curStart\t$curEnd\t$curnExons\t";
			print join ",", @curExonS;
			print "\t";
			print join ",", @curExonE;
			print "\t";
			print join ",", @curValues;
			print "\n";
		}
		
		$curID = $id;
		$curChr = $chrom;
		$curStrand = ($start < $end ? '+' : '-');
		if ($start == $end) { $curStrand = '?'; }
		$curStart = 100000000000;
		$curEnd = 0;
		$curValue = $value;
		$curnExons = 0;
		@curExonS = ();
		@curExonE = ();	
		@curValues = ();
		
		#print STDERR "\nProcessing $id... ";
	}
	
	if ($curStrand eq "?")
	{
		if ($start < $end) { $curStrand = '+'; }
		if ($start > $end) { $curStrand = '-'; }
	}
	
	if ($curStrand eq "+")
	{
		if ($start > $end)
		{
			print STDERR "chr2est warning: Strand mismatch for $curID at exon $start - $end. Assuming plus.\n";
			my $tmp = $end;
			$end = $start;
			$start = $tmp;
		}

		$curStart = ($start < $curStart ? $start : $curStart);
		$curEnd   = ($end > $curEnd ? $end : $curEnd);
		
		push @curExonS, $start;
		push @curExonE, $end;
		push @curValues, $value;
	}
	else
	{
		if (($start < $end) and ($curStrand eq "-"))
		{
			print STDERR "chr2est warning: Strand mismatch for $curID at exon $start - $end. Assuming minus.\n";
			my $tmp = $end;
			$end = $start;
			$start = $tmp;
		}

		$curStart = ($end < $curStart ? $end : $curStart);
		$curEnd   = ($start > $curEnd ? $start : $curEnd);
		
		unshift @curExonS, $end;
		unshift @curExonE, $start;
		unshift @curValues, $value;
	}
	
	$curnExons++;
}

# Dump last TU
if ($curStrand eq "?") { $curStrand = '+'; }

print "chr$curChr\t$curStrand\t$curID\t$curStart\t$curEnd\t$curnExons\t";
print join ",", @curExonS;
print "\t";
print join ",", @curExonE;
print "\t";
print join ",", @curValues;
print "\n";


__DATA__

chr2est.pl

    Convert a CHR file into an EST file. Lines in the CHR are merged into a
    line in the EST file based on their common ID. The input CHR has to be
    sorted by ID and start position.
    
    Flags:
    
    -ho:	Half-open. Creates an EST where the end coordinates are 1 base
    		larger (exclusive).

   
    
    
