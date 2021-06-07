#!/usr/bin/perl

use strict;

#------------------------------------------------------------------------------
# GetLocationsByChromosome
#------------------------------------------------------------------------------
sub GetLocationsByChromosome
{
    my ($file_ref) = @_;

    #print STDERR "Loading chromosome tab file ";

    my $in_gxt = 0;
    my $in_reference_data = 0;
    my $counter = 1;
    my %res;
    while(<$file_ref>)
    {
	chomp;

	if (/^<GeneXPressChromosomeTrack/)
	{
	    $in_gxt = 1;
	}
	elsif (/^<ChromosomeReferenceData/)
	{
	    $in_reference_data = 1;
	}
	elsif (/^<\/ChromosomeReferenceData/)
	{
	    $in_reference_data = 0;
	}
	elsif (/^<\/GeneXPressChromosomeTrack/)
	{
	    $in_gxt = 0;
	}
	elsif ($in_gxt == 1 and $in_reference_data == 0)
	{
	    my @row = split(/\t/, $_, 5);
	    
	    my $extension = length($row[4]) > 0 ? "\t$row[4]" : "";
	    $res{$row[0]} .= "$row[1]\t$row[0]\t$row[2]\t$row[3]$extension\n";

	    #print STDERR "res{$row[0]} = $row[1]\t$row[0]\t$row[2]\t$row[3]\n";
	}

	if ($counter % 10000 == 0) { print STDERR "."; }
	$counter++;
    }

    #print STDERR "Done\n";

    return %res;
}

#------------------------------------------------------------------------------
# GetLocationsByChromosomeFromTabFile
#------------------------------------------------------------------------------
sub GetLocationsByChromosomeFromTabFile
{
    my ($file_ref) = @_;

    #print STDERR "Loading chromosome tab file ";

    my $counter = 1;
    my %res;
    while(<$file_ref>)
    {
	chop;

	my @row = split(/\t/, $_, 5);
	
	my $extension = length($row[4]) > 0 ? "\t$row[4]" : "";
	$res{$row[0]} .= "$row[1]\t$row[0]\t$row[2]\t$row[3]$extension\n";

	if ($counter % 10000 == 0) { print STDERR "."; }
	$counter++;

	#print STDERR "res{$row[0]} = $row[1]\t$row[0]\t$row[2]\t$row[3]\n";
    }

    #print STDERR "Done\n";

    return %res;
}

#------------------------------------------------------------------------------
# GetLocationsByNameFromTabFile
#------------------------------------------------------------------------------
sub GetLocationsByNameFromTabFile
{
    my ($file_ref) = @_;

    #print STDERR "Loading chromosome tab file ";

    my $counter = 1;
    my %res;
    while(<$file_ref>)
    {
	chop;

	my @row = split(/\t/, $_, 5);
	
	my $extension = length($row[4]) > 0 ? "\t$row[4]" : "";
	$res{$row[1]} .= "$row[0]\t$row[1]\t$row[2]\t$row[3]$extension";

	if ($counter % 10000 == 0) { print STDERR "."; }
	$counter++;

	#print STDERR "res{$row[1]} = $row[0]\t$row[1]\t$row[2]\t$row[3]\n";
    }

    #print STDERR "Done\n";

    return %res;
}

#------------------------------------------------------------------------------
# SortLocations
#------------------------------------------------------------------------------
sub SortLocations
{
    my ($locations_str) = @_;

    my @locations = split(/\n/, $locations_str);

    @locations = sort
    {
	my @aa = split(/\t/, $a);
	my @bb = split(/\t/, $b);

	if ($aa[2] > $aa[3]) { my $tmp = $aa[2]; $aa[2] = $aa[3]; $aa[3] = $tmp; }
	if ($bb[2] > $bb[3]) { my $tmp = $bb[2]; $bb[2] = $bb[3]; $bb[3] = $tmp; }
	
	$aa[2] == $bb[2] ? ($aa[3] <=> $bb[3]) : ($aa[2] <=> $bb[2]);
    }
    @locations;

    return @locations;
}

#------------------------------------------------------------------------------
# SortLocationsByName
#------------------------------------------------------------------------------
sub SortLocationsByName
{
    my ($locations_str) = @_;

    my @locations = split(/\n/, $locations_str);

    @locations = sort
    {
	my @aa = split(/\t/, $a);
	my @bb = split(/\t/, $b);

	($aa[0] cmp $bb[0]);
    }
    @locations;

    return @locations;
}

#------------------------------------------------------------------------------
# GetSpacings
#------------------------------------------------------------------------------
sub GetSpacingsSize
{
    my ($locations_str, $global_start, $global_end) = @_;

    my @locations = @{$locations_str};

    my $res = 0;
    if (length($global_start) > 0)
    {
	my @row = split(/\t/, $locations[0]);
	$res += (($row[2] < $row[3]) ? ($row[2] - $global_start) : ($row[3] - $global_start)) - 1;
    }

    for (my $i = 1; $i < @locations; $i++)
    {
	my @row1 = split(/\t/, $locations[$i - 1]);
	my @row2 = split(/\t/, $locations[$i]);

	my $first_right = $row1[2] < $row1[3] ? $row1[3] : $row1[2];
	my $second_left = $row2[2] < $row2[3] ? $row2[2] : $row2[3];

	if ($second_left > $first_right)
	{
	  $res += $second_left - $first_right - 1;
	}
    }

    if (length($global_end) > 0)
    {
	my @row = split(/\t/, $locations[@locations - 1]);
	$res += (($row[2] < $row[3]) ? ($global_end - $row[3]) : ($global_end - $row[2])) - 1;
    }

    return $res;
}

1
