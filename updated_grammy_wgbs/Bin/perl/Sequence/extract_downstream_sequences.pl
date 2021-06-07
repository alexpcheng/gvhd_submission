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

my $stab_file =               get_arg("f", "", \%args);
my $chromosome_column =       get_arg("c", 0, \%args);
my $key_column =              get_arg("k", 1, \%args);
my $start_column =            get_arg("s", 2, \%args);
my $end_column =              get_arg("e", 3, \%args);
my $length =                  get_arg("l", -1, \%args);
my $upstream_length =         get_arg("u", 0, \%args);
my $max_sequence_length =     get_arg("max", -1, \%args);
my $do_not_extract_sequence = get_arg("no_seq", 0, \%args);


#my @all_start_locations;

my @start_locations;
my @end_locations;
my @id_locations;
my @chr_locations;


while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    #push(@all_start_locations, "$row[$key_column]\t$row[$start_column]\t$row[$end_column]\t$row[$chromosome_column]");
	
	push(@start_locations, $row[$start_column]);
    push(@end_locations, $row[$end_column]);
	push(@id_locations, $row[$key_column]);
	push(@chr_locations, $row[$chromosome_column]);

}

my %saw;
undef %saw;
my %saw;
my @unique_chr;
@saw{@chr_locations} = ();
@unique_chr = sort keys %saw;  
undef %saw;

#print STDERR "DEBUG: chrs: @unique_chr\n";



foreach my $cur_chr (@unique_chr)
{
	my @sequence;
	my $found_seq = 0;
	my $cur_seq;
	
	#print STDERR "DEBUG: cur_chr: $cur_chr\n";
	
	if ($do_not_extract_sequence == 0)
	{
	    open(STAB_FILE, "<$stab_file") or die "Could not open stab file $stab_file\n";
		my $line;
		while($line = <STAB_FILE>)
		{
			chop $line;
			my @sequence = split(/\t/, $line);
			
			
			#print STDERR "DEBUG: sequence name : $sequence[0]\n";
			
			if ($sequence[0] eq $cur_chr)
			{
				$found_seq = 1;
				$cur_seq = $sequence[1];
				
				#print STDERR "DEBUG: found  cur_seq : $cur_seq\n";
				
				last;
			}
		}
		close(STAB_FILE);
		
		if ($found_seq == 0)
		{
			#print STDERR "DEBUG: found_seq: $found_seq\n";
			exit("didn't find seq:$cur_chr");
		}
	}
	
	
	
	#print STDERR "DEBUG: cur_seq: $cur_seq \n";
	
	my @all_locations;
	undef @all_locations;
	my @all_locations;
	
	my @cur_start_locations;
	my @cur_end_locations;
	my @cur_id_locations;
	undef @cur_start_locations;
	undef @cur_end_locations;
	undef @cur_id_locations;
	my @cur_start_locations;
	my @cur_end_locations;
	my @cur_id_locations;
	

	for (my $i = 0; $i < @id_locations; $i++)
	{
		#print STDERR "DEBUG: chr_locations[i] -  $chr_locations[$i] \n";
		
		if ($chr_locations[$i] eq $cur_chr)
		{
			#print STDERR "DEBUG: line of this chr : $start_locations[$i],$end_locations[$i],$id_locations[$i] \n";
			
			push(@cur_start_locations,$start_locations[$i]);
			push(@cur_end_locations,$end_locations[$i]);
			push(@cur_id_locations,$id_locations[$i]);
			
			push(@all_locations,$start_locations[$i]);
			push(@all_locations,$end_locations[$i]);
		}
	}
	
	push(@all_locations, 0);
	@all_locations = sort { $a <=> $b } @all_locations;
	
	if ($do_not_extract_sequence == 0)
	{
		push(@all_locations, length($cur_seq));
	}
	else
	{
		push(@all_locations, $all_locations[(scalar @all_locations)-1]+2);
	}
	
	my %saw;
	undef %saw;
	my %saw;
	@saw{@all_locations} = ();
	@all_locations = sort keys %saw;  
	undef %saw;
	@all_locations = sort { $a <=> $b } @all_locations;

	
	my %all_locations_hash;
	undef %all_locations_hash;
	my %all_locations_hash;
	for (my $i = 0; $i < @all_locations; $i++)
	{
	    $all_locations_hash{$all_locations[$i]} = $i;
	}
	
	for (my $i = 0; $i < @cur_id_locations; $i++)
	{
		my $start_location = $cur_start_locations[$i];
		my $end_location = $cur_end_locations[$i];
		my $id_location = $cur_id_locations[$i];
		
		
		
		if ($start_location > $end_location)
	    {
			my $start_downstream = ($upstream_length == 0) ? ($end_location-1) : ($end_location-1 + $upstream_length);
			my $end_downstream = ($length != -1) ? ($end_location - $length) : ($all_locations[$all_locations_hash{$end_location} - 1] + 1);
			#print STDERR "DEBUG: all_locations_hash{end_location} : $all_locations_hash{$end_location}\n";
			#print STDERR "DEBUG: end_downstream : $end_downstream\n";
			my $sequence_length = $start_downstream - $end_downstream + 1;

			if ($max_sequence_length != -1 and $sequence_length > $max_sequence_length)
			{
			    $end_downstream = $start_downstream - $max_sequence_length + 1;
			    $sequence_length = $max_sequence_length;
			}


			if ($do_not_extract_sequence == 0)
			{
				print ">$cur_chr#$id_location#$start_downstream#$end_downstream#$sequence_length#reverseComplement#\n";
			    my $string = substr($cur_seq, $end_downstream - 1, $start_downstream - $end_downstream + 1);
			    $string = &ReverseComplement($string);
			    print "$string\n";
			}
			else
			{
				print "$cur_chr\t$id_location\t$start_downstream\t$end_downstream\n";
			}
	    }
	    else
	    {
			my $start_downstream = ($upstream_length == 0) ? ($end_location + 1) : ($end_location + 1 - $upstream_length);
			my $end_downstream  = ($length != -1) ? ($end_location + $length) : ($all_locations[$all_locations_hash{$end_location} + 1] - 1);
			my $sequence_length = $end_downstream - $start_downstream + 1;

			if ($max_sequence_length != -1 and $sequence_length > $max_sequence_length)
			{
			    $end_downstream = $start_downstream + $max_sequence_length - 1;
			    $sequence_length = $max_sequence_length;
			}
			
			if ($do_not_extract_sequence == 0)
			{
				print ">$cur_chr#$id_location#$start_downstream#$end_downstream#$sequence_length#NotRevComp#\n";
			    my $string = substr($cur_seq, $start_downstream - 1, $end_downstream - $start_downstream + 1);
			    print "$string\n";
			}
			else
			{
				print "$cur_chr\t$id_location\t$start_downstream\t$end_downstream\n";
			}
			
	    }
	
	}
	
}




__DATA__

extract_downstream_sequences.pl <file>

   Given a file of locations with a key, start, end, extracts downstream
   sequences of a given length or maximal length up to the next sequence 
   location.

   NOTE: If <end> is greater than <start> then we assign it the intergenic
         region from the other side and extract its reverse complement

   -f <str>:   Stab file
   -c <num>:   Column for the Chromosome (default: 0)
   -k <num>:   Column for the key (default: 1)
   -s <num>:   Column for the start location (default: 2)
   -e <num>:   Column for the end location (default: 3)

   -l <num>:   Downstream length to extract (default: -1 for extracting to the next sequence)
   -u <num>:   Upstream length to extract (default: 0)

   -max <num>: Maximum sequence length to extract (default: -1, no max)
                 (appliable when extracting entire intergenic)

   -no_seq:    Do not extract the sequence, just the locations

