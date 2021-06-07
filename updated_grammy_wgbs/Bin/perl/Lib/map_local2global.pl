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

my $map_file = get_arg("m", "", \%args);
my $printOrig = get_arg("po", 0, \%args);

if (length($map_file) == 0) { die ("Must supply map file using the -m argument"); }

my %key2chrom;
my %key2start;
my %key2strand;

open(MAP_FILE, "<$map_file") or die "Could not open map file $map_file\n";

while (<MAP_FILE>)
{
	chop;
	my @row = split(/\t/);
	my $startloc;
	
	$key2chrom{$row[1]} = $row[0];
	$key2start{$row[1]} = $row[2];
	$key2strand{$row[1]} = $row[2] > $row[3] ? -1 : 1 ; 	
}

close (MAP_FILE);

print STDERR "Read " . keys (%key2chrom) . " mappings from $map_file.\n";

while (<$file_ref>)
{
	chomp;
	my @row = split(/\t/, $_, 5);

	if (exists $key2chrom{$row[1]})
	{
	
		my $origChr = $row[0];
		my $origStart = $row[2];
		my $origEnd = $row[3];
		
		$row[0] = $key2chrom{$row[1]};
		my $offset = $key2start{$row[1]};
		my $strand = $key2strand{$row[1]};

		$row[2] = $strand * $row[2] + $offset - $strand;
		$row[3] = $strand * $row[3] + $offset - $strand;
		
		print join ("\t", @row[0..3]) . "\t";
		
		if ($printOrig)
		{
			print "$origChr\t$origStart\t$origEnd\t";
		}
		print join ("\t", @row[4]) . "\n";	
	}
}


__DATA__

map_local2global.pl <source file>

	Maps the given chr file from local (1-based) to global (chromosome) coordinates
	given in the map file (-m argument).

    -m <file>:  map file to use. Format is <chr> <ID> <start> <end>
    -po:        print original coordinates after the mapped coordinates
