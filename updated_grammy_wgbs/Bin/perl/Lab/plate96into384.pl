#!/usr/bin/perl 
use warnings;
use strict;
use POSIX qw(ceil floor);

#Make four technical replicates from a 96well plate into a 384 well plate
#THIS SCRIPT IS NOT COMPLETE
#LBC 09/10


require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lab/library_helpers.pl";

if (! @ARGV || ($ARGV[0] eq "--help")){
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $source_plate = get_arg("source_plate", "", \%args);
my $new_plate_name = get_arg("new_plate_name", "", \%args);
my $pattern = get_arg("pattern", "[1,1,-1,-1]", \%args);

die ("Please supply  -source_plate parameter\n") unless ($source_plate);
die ("Please supply  -new_plate_name parameter\n") unless ($new_plate_name);

open (SOURCE_PLATE,"${source_plate}.tab")   or die "Cannot open ${source_plate}.tab\n";
open (NEW_PLATE, ">$new_plate_name".".tab") or die "Failed to create ${new_plate_name}.tab";
print NEW_PLATE "Well\tWellContentAlias\tRelatedStrainID\tActualStrainID\tMedium\tProduct\tSourcePlates\tSourceWell\tSuccess\tComments\tDateOfPreparation\n";


#Build Map
my @source_wells = interleave( ['A' .. 'H'] , [1 .. 12] );
my @dest_wells = interleave( ['A' .. 'P'] , [1 .. 24] );
my @RotSource_wells = reverse(@source_wells);

my %map;
for my $i (1 .. 96){
	print "$i: " , R0($i,12) , " " , R1(R0($i,12)) , " ",  "; ", newRowPos($i,12), ' ',  newPos($i,12) , ' ', newPosOffset1($i,12),"\n";
	print $source_wells[$i-1] ,'->',  $dest_wells[newPos($i,12)-1] , ',', $dest_wells[newPosOffset1($i,12)-1],"\n";
	print $RotSource_wells[$i-1] ,'->',  $dest_wells[newPos($i,12)-0] , ',', $dest_wells[newPosOffset1($i,12)-2],"\n";
	$map{$source_wells[$i-1]} = [ $dest_wells[newPos($i,12)-1] ,  $dest_wells[newPosOffset1($i,12)-1],  $dest_wells[newPos($i,12)-0] ,  $dest_wells[newPosOffset1($i,12)-2] ]

}

while (<SOURCE_PLATE>){
	chomp;
	@line = split(/\t/);
	my $swell = shift(@line);
	foreach my $dwell (@{$map{$swell}}){
		print NEW_PLATE "$dwell @line\n";
	}
}

close(NEW_PLATE);
close(SOURCE_PLATE);


sub interleave {
	 my @l;
    foreach my $i (@{$_[0]}){
    	foreach my $j (@{$_[1]}){
		 push (@l, "$i$j");
		}
	}
	return(@l);
}

sub R0 {
	my $pos = $_[0] ;
	my $rowLength = $_[1];
	my $old_row = ceil($pos/$rowLength);
	return $old_row;
}
sub R1 {
	my $oldRow = $_[0] ;
	my $new_row = $oldRow * 2 - 1;
	return $new_row;
}

sub newRowPos {
	my $pos = $_[0];
	my $OldRowLength = $_[1];
	return ( (($pos*2)-1)  - ($OldRowLength*2*(R0($pos,$OldRowLength)-1)) );
}
sub newPos {
	my $pos = $_[0];
	my $OldRowLength = $_[1];
	my $newRowPos = newRowPos($pos,$OldRowLength);
	my $newPos = $newRowPos + (2*$OldRowLength)*(R1(R0($pos,$OldRowLength))-1);
	return $newPos;
}

sub newPosOffset1 {
	my $pos = shift;
	my $OldRowLength = shift;
	my $newPos = newPos($pos,$OldRowLength);
	my $newPosOffset1 = $newPos + $OldRowLength * 2 + 1;
	return ($newPosOffset1);
}
	
	

__DATA__

 plate96into384.pl

   Generate a plate def file with four copies of a 96 well plate into a 384 well plate
   By default performs rotation. See diagram below

 Parameters:
 ==========
      -source_plates <str>:               Names of the source plate 
      -new_plate_name <str>:              Name of the new plate (plate file will be <str>.tab)

NOT YET IMPLEMENTED
      -pattern <str>:    Exmple for <str>: [1,1,-1,-1]
				comma separated list of four ones or negative ones, describing pattern of join

 Example matching the diagram below:
 ==================================
 plate96into384.pl  -source_plate 133 -new_plate_name 205 -pattern '[1,1,-1,-1]'
          1           2
     -----------  ----------
     |         |  |        |
     |         |  |        |
A    |   A1    |  |   H12  |
     |         |  |        |
     |         |  |        |
     -----------  ----------
     ----------   ---------- 
     |        |   |        |
     |        |   |        |
B    |   H12  |   |   A1   |
     |        |   |        |
     |        |   |        |
     ----------   ----------
