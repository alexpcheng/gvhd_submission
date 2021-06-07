#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
#require "/home/eran/Develop/perl/Sequence/extract_random_locations.pl";

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

my $num_random_sequences = get_arg("n", 100, \%args);
my $random_sequence_length = get_arg("l", 10, \%args);
my $file_has_lengths = get_arg("fl", "", \%args);
my $per_line = get_arg("pl", "", \%args);
my $random_orientation = get_arg ("o",0,\%args);
my $weighted = get_arg ("w",0,\%args);
my $uniform = get_arg ("u",0,\%args);

my @locations;
my $total_length = 0;

while(<$file_ref>)
{
    chop;

    if ($num_random_sequences == -1)
    {
		&ExtractRandomLocation($_);
    }
    else
    {
    	if ($weighted or $uniform)
    	{
    		my @row = split(/\t/, $_, 5);
    		$total_length += abs ($row[3] - $row[2]) + 1;
    	}
		push(@locations, $_);
    }
}

if ($num_random_sequences < 1)
{
	exit;
}

my $num_locations = @locations;

# Two-step selection (non-weighted)
if (!$weighted and !$uniform and !$per_line)
{

	for (my $i = 0; $i < $num_random_sequences; $i++)
	{
		my $location_index = int(rand($num_locations));
		&ExtractRandomLocation($locations[$location_index]);
	}
	exit;
}

if ($per_line ne "")
{
	for (my $i=0; $i < $num_locations; $i++)
	{
		my @loc_info = split (/\t/, $locations[$i]);
		
		for (my $j=0; $j < $loc_info[$per_line]; $j++)
		{
			&ExtractRandomLocation($locations[$i]);
		}		
	}
	exit;
}

print STDERR "Read $num_locations locations, with total length of $total_length\n";
$total_length -= $num_locations * ($random_sequence_length - 1);
#print STDERR "Length after correction for random sequence length: $total_length\n";

my @selected;
if ($uniform)
{
	$num_random_sequences = 0;
	for (my $i = 1; $i < $total_length; $i += $uniform)
	{
		push (@selected, $i);
		$num_random_sequences ++;
	}
}
else
{
	for (my $i = 0; $i < $num_random_sequences; $i++)
	{
		push (@selected, int(rand($total_length))+1);
	}
	
	@selected = sort { $a <=> $b } @selected;
}

my $location_index = 0;
my $current_start = 0;
my $valid_length;
my $start;
my $end;

my @row = split(/\t/, $locations[$location_index], 5);

$valid_length = abs ($row[2] - $row[3]) + 1 - ($random_sequence_length-1);

for (my $i = 0; $i < $num_random_sequences;)
{
	# print STDERR "selected: $selected[$i] current_start: $current_start valid_length: $valid_length\n";
	if (($selected[$i] - $current_start) <= $valid_length)
	{
		# We are within the right segment
		my $pos_strand = ($row[2] <= $row[3]);
		if ($pos_strand)
		{
			$start = $row[2] + ($selected[$i] - $current_start) - 1;
			$end   = $start + ($random_sequence_length-1);
		}
		else
		{
			$end   = $row[3] + ($selected[$i] - $current_start) - 1;
			$start = $end + ($random_sequence_length-1);
		}
		
		print "$row[0]\t$row[1]\t$start\t$end\t$row[4]\n";
		$i++;
	}
	else
	{
	  $location_index++;
	    @row = split(/\t/, $locations[$location_index], 5);
	    $current_start += $valid_length;
	    $valid_length = abs ($row[2] - $row[3]) + 1 - ($random_sequence_length-1);
	}	
}


###################################
sub ExtractRandomLocation
{
    my ($location) = @_;

    my @row = split(/\t/, $location,5);
    my @tmp1 = split(/\t/, $location);
    if ($file_has_lengths ne ""){ $random_sequence_length=$row[$file_has_lengths] }
    
    if ($row[2] < $row[3])
    {
	my $length = $row[3] - $row[2] + 1 - $random_sequence_length;

	my $start = $row[2] + int(rand($length));
	my $end = $start + $random_sequence_length - 1;

	if ($random_orientation and rand()>0.5){
	    my $tmp=$start;
	    $start=$end;
	    $end=$tmp;
	}

	print "$row[0]\t$row[1]\t$start\t$end\t$row[4]\n";
    }
    else
    {
	my $length = $row[2] - $row[3] + 1 - $random_sequence_length;

	my $start = $row[3] + int(rand($length));
	my $end = $start + $random_sequence_length - 1;

	if ($random_orientation and rand()>0.5){
	    my $tmp=$start;
	    $start=$end;
	    $end=$tmp;
	}

	print "$row[0]\t$row[1]\t$end\t$start\t$row[4]\n";
    }
}

__DATA__

extract_random_locations.pl <file>

   Extracts random locations from a <chr><tab><name><tab><start><tab><end> location file

   -n <num>:      Number of locations to extract (default: 100)
                  NOTE: if -1 is specified, then extract one random sequence from each location

   -l <num>:      Length of location to extract (default: 10)
   -fl <num>:     Specify a separate location length for each feature in the file. Requires an
                  additional column (<num>) specifying the lengths for each location. Currently
                  only works without -w and without -u (default: off)
   -pl <num>      Per-line mode. For each line in the input file, the number of locations extracted
                  is given in column <num>.
   -o:            Random orientation (default: off)
   -w:            Weighted random (based on the length of every segment)
   -u <num>:      Uniform distribution of locations every <num> basepairs
   
