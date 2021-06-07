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
my $debug  = get_arg("debug", 0, \%args);

if (length($map_file) == 0) { die ("Must supply map file using the -m argument"); }

my %key2chrom;
my %key2start;
my %key2end;
my %key2length;
my %key2strand;

my $r=int(rand(10000));

print STDERR "Reading mapings from $map_file... ";
system ("cat $map_file | chr2minusplus.pl | chr_length.pl > tmp_$r" . "_len");

print STDERR "   OK.\nSorting... Positive strand-";
system ("cat tmp_$r" . "_len | filter.pl -q -c 5 -estr \"+\" | sort.pl -q -c0 2 -c1 3 -n1 > tmp_$r" . "_sorted");

print STDERR "OK.    Negative strand-";
system ("cat tmp_$r" . "_len | filter.pl -q -c 5 -estr \"-\" | sort.pl -q -c0 2 -c1 4 -n1 -r >> tmp_$r" . "_sorted");

print STDERR "   OK.\nReading sorted mapping... ";

open(MAP_FILE, "<tmp_$r" . "_sorted") or die "Could not open sorted map file tmp_$r" . "_sorted\n";

while (<MAP_FILE>)
{
	chop;
	my @row = split(/\t/);
	my $startloc;
	
	$key2chrom{$row[2]} = $row[1];
	$key2start{$row[2]} .= $row[3] . ",";
	$key2end{$row[2]} .= $row[4] . ",";
	$key2length{$row[2]} .= $row[0] . ",";
	$key2strand{$row[2]} = $row[5]; 	
}

close (MAP_FILE);

print STDERR "   OK. Read " . keys (%key2chrom) . " mappings.\n";

while (<$file_ref>)
{
	chomp;
	my @row = split(/\t/, $_, 5);

	if (exists $key2chrom{$row[0]})
	{
	
# 		print STDERR "Chrom: $key2chrom{$row[0]}\n";
# 		print STDERR "Start: $key2start{$row[0]}\n";
# 		print STDERR "End: $key2end{$row[0]}\n";
# 		print STDERR "Length: $key2length{$row[0]}\n";
# 		print STDERR "Strand: $key2strand{$row[0]}\n\n";

		my $newStart = convertCoordinate ($row[2], $key2start{$row[0]}, $key2end{$row[0]}, $key2length{$row[0]}, $key2strand{$row[0]});
		my $newEnd   = convertCoordinate ($row[3], $key2start{$row[0]}, $key2end{$row[0]}, $key2length{$row[0]}, $key2strand{$row[0]});

		if ( ($newStart == -1) || ($newEnd == -1) )
		{
			print STDERR "Could not map one of the coordinates on $row[0]: $row[2] to $row[3]\n";
		}
		else
		{
			print "$key2chrom{$row[0]}\t$row[0]\t$newStart\t$newEnd\t$row[1]\t$row[2]\t$row[3]\t$row[4]\n";
		}
	}
	else
	{
		print STDERR "Error: could not find mapping for $row[0].\n";
	}
}

if ($debug == 0)
{
	system ("rm tmp_$r" . "_*");
}

######
sub convertCoordinate {

	my ($coord, $exonStarts, $exonEnds, $exonLengths, $strand) = @_;
		
	my @exonS = split (",", $exonStarts);
	my @exonE = split (",", $exonEnds);
	my @exonL = split (",", $exonLengths);

	my $nExons = scalar @exonS;
	
	my $remains = $coord;
	
	for (my $i=0; $i<$nExons; $i++)
	{
		if ($remains <= $exonL[$i])
		{
			if ($strand eq "+")
			{
				return ($exonS[$i] + $remains - 1);
			}
			else
			{
				return ($exonE[$i] - $remains + 1);				
			}
		}
		
		$remains -= $exonL[$i];
	}

	return -1;
}


__DATA__

map_local2global_segments.pl <source file>

	Maps the given chr file from local (1-based) to global (chromosome) coordinates
	given in the map file (-m argument). The map file can contain multiple instances
	per ID, in which case those are treated as the exon coordinates.

    Output format is <chr> <ID> <start> <end> <original_ID> <original_start> <original_end> <...>
    
    where <...> is any remaining columns in the input chr file.

    -m <file>:  map file to use. Format is <chr> <ID> <start> <end>
