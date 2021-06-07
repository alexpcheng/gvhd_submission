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

my $stab_file = get_arg("f", "", \%args);
my $chromosome_column = get_arg("c", 0, \%args);
my $key_column = get_arg("k", 1, \%args);
my $start_column = get_arg("s", 2, \%args);
my $end_column = get_arg("e", 3, \%args);
my $length = get_arg("l", -1, \%args);
my $downstream_length = get_arg("d", 0, \%args);
my $max_sequence_length = get_arg("max", -1, \%args);
my $do_not_extract_sequence = get_arg("no_seq", 0, \%args);

my @all_start_locations;
my @all_locations;

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    push(@all_start_locations, "$row[$key_column]\t$row[$start_column]\t$row[$end_column]\t$row[$chromosome_column]");

    push(@all_locations, $row[$start_column]);
    push(@all_locations, $row[$end_column]);
}

my @sequence;
if ($do_not_extract_sequence == 0)
{
    open(STAB_FILE, "<$stab_file") or die "Could not open stab file $stab_file\n";
    my $line = <STAB_FILE>;
    chop $line;
    @sequence = split(/\t/, $line);
}

push(@all_locations, 0);
push(@all_locations, length($sequence[1]));

@all_locations = sort { $a <=> $b } @all_locations;
my %all_locations_hash;
for (my $i = 0; $i < @all_locations; $i++)
{
    $all_locations_hash{$all_locations[$i]} = $i;
}

@all_start_locations = sort { my @aa = split(/\t/,$a); my @bb = split(/\t/,$b); $aa[1] <=> $bb[1]; } @all_start_locations;

foreach my $location (@all_start_locations)
{
    my @row = split(/\t/, $location);

    my $start_location = $row[1];
    my $end_location = $row[2];

    if ($start_location > $end_location)
    {
	my $start_upstream = $downstream_length == 0 ? ($start_location + 1) : ($start_location - $downstream_length);
	my $end_upstream = $length != -1 ? ($start_location + $length) : ($all_locations[$all_locations_hash{$start_location} + 1] - 1);
	my $sequence_length = $end_upstream - $start_upstream + 1;

	if ($max_sequence_length != -1 and $sequence_length > $max_sequence_length)
	{
	    $end_upstream = $start_upstream + $max_sequence_length - 1;
	    $sequence_length = $max_sequence_length;
	}

	print ">$row[0]\t$row[3]\t$end_upstream\t$start_upstream\t$sequence_length\treverse complement\n";

	if ($do_not_extract_sequence == 0)
	{
	    my $string = substr($sequence[1], $start_upstream - 1, $end_upstream - $start_upstream + 1);
	    $string = &ReverseComplement($string);
	    print "$string\n";
	}
    }
    else
    {
	my $start_upstream = $downstream_length == 0 ? ($start_location - 1) : ($start_location + $downstream_length);
	my $end_upstream = $length != -1 ? ($start_location - $length) : ($all_locations[$all_locations_hash{$start_location} - 1] + 1);
	my $sequence_length = $start_upstream - $end_upstream + 1;

	if ($max_sequence_length != -1 and $sequence_length > $max_sequence_length)
	{
	    $end_upstream = $start_upstream - $max_sequence_length + 1;
	    $sequence_length = $max_sequence_length;
	}

	print ">$row[0]\t$row[3]\t$end_upstream\t$start_upstream\t$sequence_length\tforward\n";

	if ($do_not_extract_sequence == 0)
	{
	    print substr($sequence[1], $end_upstream - 1, $start_upstream - $end_upstream + 1);
	    print "\n";
	}
    }
}

__DATA__

extract_upstream_sequences.pl <file>

   Given a file of locations with a key, start, end, extracts upstream
   sequences of a given length or maximal length up to the next sequence 
   location.

   NOTE: If <end> is greater than <start> then we assign it the intergenic
         region from the other side and extract its reverse complement

   -f <str>:   Stab file
   -c <num>:   Column for the Chromosome (default: 0)
   -k <num>:   Column for the key (default: 1)
   -s <num>:   Column for the start location (default: 2)
   -e <num>:   Column for the end location (default: 3)

   -l <num>:   Upstream length to extract (default: -1 for extracting to the next sequence)
   -d <num>:   Downstream length to extract (default: 0)

   -max <num>: Maximum sequence length to extract (default: -1, no max)
                 (appliable when extracting entire intergenic)

   -no_seq:    Do not extract the sequence, just the locations

