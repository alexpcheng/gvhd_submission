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

my $key_name = get_arg("k", "EXTRACT_ALL_KEYS", \%args);
my $start_location = get_arg("s", 1, \%args);
my $end_location = get_arg("e", -1, \%args);
my $locations_file = get_arg("f", "", \%args);
my $is_zero_based = get_arg("z", "0", \%args);
my $print_location_description = get_arg("d", 0, \%args);
my $print_location_name = get_arg("dn", 0, \%args);
my $downstream = get_arg ("ds", 0, \%args);
my $upstream = get_arg ("us", 0, \%args);
my $reversecomp = get_arg ("rev", 0, \%args);
my $length_location = get_arg ("l", 0, \%args);

my %key_starts;
my %key_ends;
my %key_output_names;
my %key_upstream;
my %key_downstream;

if (length($locations_file) > 0)
{
	print STDERR "Reading locations for sequence extraction... ";
	
    open(LOCATIONS, "<$locations_file");
    while(<LOCATIONS>)
    {
       chomp;
       my @row = split(/\t/);
       $key_starts{$row[0]} .= "$row[2]\t";
       $key_ends{$row[0]} .= "$row[3]\t";
       $key_output_names{$row[0]} .= "$row[1]\t";
       $key_upstream{$row[0]} .= (defined($row[4]) ? "$row[4]\t" : "$upstream\t");
       $key_downstream{$row[0]} .= (defined($row[5]) ? "$row[5]\t" : "$downstream\t");
    }
    print STDERR "Done.\n";
}
else
{
    $key_starts{$key_name} = $start_location;
    $key_ends{$key_name} = $end_location;
    $key_output_names{$key_name} = $key_name;
    $key_upstream{$key_name} = $upstream;
    $key_downstream{$key_name} = $downstream;
}

print STDERR "Extracting locations.";

while(<$file_ref>)
{
    chomp;

    my @row = split(/\t/);

    if ((length($locations_file) == 0 and $key_name eq "EXTRACT_ALL_KEYS") or length($key_starts{$row[0]}) > 0)
    {
		my $key = length($key_starts{$row[0]}) > 0 ? $row[0] : "EXTRACT_ALL_KEYS";
		my @starts = split(/\t/, $key_starts{$key});
		my @ends = split(/\t/, $key_ends{$key});
		my @output_names = split(/\t/, $key_output_names{$key});
		my @usarray = split(/\t/, $key_upstream{$key});
		my @dsarray = split(/\t/, $key_downstream{$key});
		
		for (my $i = 0; $i < @starts; $i++)
		{
			my $start_location = $starts[$i];
			my $end_location = $ends[$i];
			
			my $cur_us = $usarray[$i];
			my $cur_ds = $dsarray[$i];
			
			if ($print_location_description == 1)
			{
				my $output_name = length($output_names[$i]) > 0 ? "$output_names[$i] $row[0]" : $row[0];
				print "$output_name from $start_location to $end_location\t";
			}
			elsif ($print_location_name == 1)
			{
				my $output_name = length($output_names[$i]) > 0 ? $output_names[$i] : $row[0];
				print "$output_name\t";
			}
			else
			{
				print "$row[0]\t";
			}
	
			if ($start_location == 0) { $end_location = length($row[1]); }
			if ($end_location == -1) { $end_location = length($row[1]); }

			if ($length_location > 0)
			{
			   my $center = ($length_location % 2 == 0) ? floor(length($row[1])/2) : ceil(length($row[1])/2);
			   $start_location = ($length_location % 2 == 0) ? ($center + 1 - ($length_location/2)) : ($center - ($length_location - 1)/2);
			   $end_location = $start_location + $length_location - 1;
			}

			my $us_start;
			my $ds_end;
			my $actual_start;
			my $string;
			
			my $strand = ($start_location <= $end_location) ? 1 : 0;
			
			my $offset_correction = $is_zero_based ? 0 : 1 ;

			if ($strand)
			{
				$us_start = $start_location > $cur_us ? $start_location - $cur_us : 1;
				$ds_end	 = $end_location + $cur_ds < length($row[1]) ? $end_location + $cur_ds : length($row[1]);
				$actual_start = $start_location - $us_start + 1;
				
				$string = substr($row[1], $us_start - $offset_correction, ($ds_end - $us_start) + 1);
				if ($reversecomp) { $string = &ReverseComplement($string); }
				
				#print STDERR "Sequence: $row[0], Strand: $strand, ($us_start - $ds_end)\n";
			}
			else
			{
				$us_start = $start_location + $cur_us < length($row[1]) ? $start_location + $cur_us : length($row[1]);
				$ds_end	 = $end_location > $cur_ds ? $end_location - $cur_ds : 1;
				$actual_start = $us_start - $start_location + 1;
				
				$string = substr($row[1], $ds_end - $offset_correction, ($us_start - $ds_end) + 1);
				if (not $reversecomp) { $string = &ReverseComplement($string); }

				#print STDERR "Sequence: $row[0], Strand: $strand, ($us_start - $ds_end)\n";
			}
	
			my $actual_end = $actual_start + abs($end_location - $start_location);
			
			print "$actual_start\t$actual_end\t$string\n";
			
			print STDERR ".";
		}
	}
}

print STDERR " Done.\n";


__DATA__

extract_sequence_area.pl <file>

   Extracts a location from a given stab file, with the given upstream and
   downstream padding.
   
   The input is a tab delimited file of the format 
   <key> <start> <end> [<upstream> [<downstream>]]
   
   If <upstream> and <downstream> are given in the input file, then those values
   override the -us, -ds command line values.

   NOTE: Locations here are specified in 1-based coordinates.
   
   Result is key, actual start of sequence, end of sequence, sequence.

   -k <num>: Key to extract (default: extract from all keys)
   -s <num>: Start location (default: 1)
   -e <num>: End location (default: end of sequence)
   -l <num>: Extract the central <num>bp (default: 0 => location is defined by other means, e.g. '-s' and '-e' flags)

   -f <str>: File containing the locations to extract in the format:
             key<tab>name<tab>start<tab>end

   -z:       Input 'start' and 'end' are 0-based (else, assumed to be 1-based).

   -d:       Print the full description of the location of the extracted sequence
   -dn:      Print only the name of the extracted sequence
   
   -us:	     Upstream offset (number of bases to print upstream)
   -ds:	     Downstream offset (number of bases to print downstream)
   
   -rev:     Reverse complement (transcribe) all extracted sequences.

