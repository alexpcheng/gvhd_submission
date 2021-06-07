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


### START

my $Chromosome = (split(/_/,  (split (/\./,@ARGV[0],2))[0] ,2))[1];
# Suffle
my $Ref_Organism_name = @ARGV[1];
my $mode = 'Normal';
if (@ARGV[2] eq "-s")
  {$mode = 'Shuffle';}

## Parameter
#my $Ref_Organism_name = "sacCer1";  # The name of the referance organism. write it exactly as appears in the *.mfa file (sacCer1, Human...)


### Stage 1: MERGE SUB_MSAs FROM UCSC FORMAT

my $InBlock = 0;
my $LineType;
my $BlockCounter;
my %Organisms;
my $OrganismID=1;
my @Genomes;
my @LastCoordinate;
my @Row;
my $Contig;
my $StartCoordinate;
my $SeqLength;
my $CurrentSequence;
my $CurrentOrganism;
my $StartSequencesSeperator="* "; # must end with [SPACE]
my $EndSequencesSeperator="*";
my $NewGenomeInBlockFlag = 0;
my @Record;
my $annotation = 9;
my $MSA_OK = 1;
my $ref_index;
my $start_ref;                    # First nucleotide of reference organism. given in the UCSC *.mfa file


#DEBUG
my $start = 0;
my $step=160; # Don't change, screen width


while(<$file_ref>)
{
    chop;
    $LineType = substr($_,0,1);
    if ($LineType eq "a")         # sub_MSA header: entering new MSA block
    {
	$InBlock=1;
	$BlockCounter = 0;
	$NewGenomeInBlockFlag = 0;
	# The Record array checks which genomes, known to the script, have appered in the sub MSA in order to fill gap for the absent ones.
	for (my $i=0; $i<$OrganismID; $i++)
	  {
	    @Record[$i]=0;
	  }
    }
    elsif ($LineType eq "s")      # genomic sequence
    {
	# Split genomic line into fields
	@Row = split (/\s+/,$_,7);
	$Contig = $Row[1];
	$CurrentOrganism = (split (/\./,$Contig,2))[0];
	$StartCoordinate = $Row[2];
	$SeqLength = $Row[3];
	$CurrentSequence = $Row[6];

	# Create Organism in hash if it does not exist
	if (!$Organisms{$CurrentOrganism})
	{
	    $Organisms{$CurrentOrganism} = $OrganismID;
	    @LastCoordinate[$Organisms{$CurrentOrganism}] = $StartCoordinate-1;
	    if ($OrganismID != 1 && $NewGenomeInBlockFlag == 0)
	    {
		@Genomes[$Organisms{$CurrentOrganism}] = @Genomes[0];
	    }
	
	    # Check if this is the reference organism
	    if ($CurrentOrganism eq $Ref_Organism_name)
	    {
	      $ref_index = $OrganismID;
	      $start_ref = $StartCoordinate;
	    }

	    $OrganismID++;
	    $NewGenomeInBlockFlag = 1;
	}
	@Record[$Organisms{$CurrentOrganism}]=1;

	#Concatenate genomic sequence
	if (!$NewGenomeInBlockFlag)
	{
	  @Genomes[$Organisms{$CurrentOrganism}] .=  $StartSequencesSeperator.($StartCoordinate-@LastCoordinate[$Organisms{$CurrentOrganism}]-1);
	  for (my $i=0; $i<$annotation-length($StartCoordinate-@LastCoordinate[$Organisms{$CurrentOrganism}]-1); $i++)
	  {
	    @Genomes[$Organisms{$CurrentOrganism}] .= " ";
	  }
	}
	else
	{
	  my $curr_org = $OrganismID-1;
	  @Genomes[$Organisms{$CurrentOrganism}] .=  $StartSequencesSeperator."Genome ".$curr_org;
	  for (my $i=0; $i<$annotation-length($curr_org)-7; $i++)
	  {
	    @Genomes[$Organisms{$CurrentOrganism}] .= " ";
	  }
	  $NewGenomeInBlockFlag = 0;
        }
	
	@Genomes[$Organisms{$CurrentOrganism}] .= $EndSequencesSeperator.$CurrentSequence;
	@LastCoordinate[$Organisms{$CurrentOrganism}] = $StartCoordinate + $SeqLength -1;
    }
    elsif ($LineType eq "")
    {
	$InBlock=0;
	for (my $i=0; $i<$OrganismID; $i++)
	{
	    # If known genome was not in last sub-MSA fill it with gaps so it will align latter with the others
	    if (!@Record[$i])
	    {
		@Genomes[$i] .=  $StartSequencesSeperator."no-seq ";  #Note: careful what you put here, it is parsed afterwards
		for (my $m=0, my $annotation=9; $m<$annotation-7; $m++)
		{
		    @Genomes[$i] .= " ";
		}
		@Genomes[$i] .= $EndSequencesSeperator;
		for (my $n=0; $n<length($CurrentSequence); $n++)
		{
		    @Genomes[$i] .= "\\";
		}
	    }
	}
    }
}

# Validate the MSA merge went ok
for (my $i=1; $i<$OrganismID ; $i++)
{
#DEBUG
  #print STDERR ("before flip\n");
  #print STDERR ("Genome $i - ",length(@Genomes[$i]),"\n");
  if (length(@Genomes[1]) != length(@Genomes[$i])) {$MSA_OK = 0;}
#DEBUG
  #print STDERR ("$i ",substr(@Genomes[$i],0,50),"\n");
}



## Shuffle Merged MSA (shuffle mode)
if ($mode eq 'Shuffle')
{
  my @GenomesArrays;
  my $found = 0;
  my $randpos;
  my $currentValue;

  # Shuffled MSA header
  print (">Shuffled-MSA(for_Z-score_calculation)>");


  # Turn Genome string to an array
  for (my $i=0; $i<$OrganismID ; $i++)
  {
    my @temp_arr = split(//,$Genomes[$i]);
    push (@GenomesArrays, [@temp_arr]);
  }

  # Slide on the Genome array
  for (my $i=0; $i<length($Genomes[0]); $i++)
  {
    # Leap if reached an annotation block
    if ($GenomesArrays[1][$i] eq "*")
    {
      $i+=$annotation+3;
      next;
    }

    # Don't shuffle missing-sequence blocks
    if ($GenomesArrays[1][$i] eq "\\")
    {
      next;
    }

    ## Randomly select a index
    $found = 0;
    while (!$found)
    {
#DEBUG
      #print STDERR ("Searching randpos ...\n");
      $randpos=int(rand length($Genomes[0]));
#DEBUG
      #print STDERR ("random $randpos \n");

        # Check that the random index is within a sequenceand not within an annotation 
        # nor a missing-sequence block in the last genome (to avoid over gapping of the shuffled MSA). 
        # The last genome is usually the least abundant of sequences and best suited for this.
	if (substr($Genomes[0],$randpos,1) eq "\\" and substr($Genomes[$OrganismID-1],$randpos,1) ne "\\")
	{
#DEBUG
	  #print STDERR ("Found: $randpos\n");
	  $found=1;
	}

    }

    # Flip nucleotides
    for (my $j=0; $j<$OrganismID ; $j++)
    {
      if ($GenomesArrays[$j][$i] ne "\\")
      {
	#print STDERR ("Before flip: $GenomesArrays[$j][$i]\t$GenomesArrays[$j][$randpos]\n");
	$currentValue=$GenomesArrays[$j][$i];
	$GenomesArrays[$j][$i]=$GenomesArrays[$j][$randpos];
	$GenomesArrays[$j][$randpos]=$currentValue;
#DEBUG
	#print STDERR ("After flip: $GenomesArrays[$j][$i]\t$GenomesArrays[$j][$randpos]\n");
      }
    }
  }

  # Convert array back to string
  for (my $i=1; $i<$OrganismID ; $i++)
  {
    $Genomes[$i]=join("", @{$GenomesArrays[$i]});
  }

}



# Validate the MSA merge went ok
for (my $i=1; $i<$OrganismID ; $i++)
{
#DEBUG
  #print STDERR ("\n\nafter flip\n");
  #print STDERR ("Genome $i - ",length(@Genomes[$i]),"\n");
  if (length(@Genomes[1]) != length(@Genomes[$i])) {$MSA_OK = 0;}
#DEBUG
  #print STDERR ("$i ",substr(@Genomes[$i],0,50),"\n");
}

if ($MSA_OK)
  {print STDERR "Sub-MSA merging step for $Chromosome... ok.\n",$OrganismID-1," Genomes in MSA length of ",length(@Genomes[1])," characters\n\n";}
else
  {print STDERR "Sub-MSA merging step for $Chromosome... Error!\n\n";}

# Create Output header
print (">Organisms:");
for (my $i=1; $i<$OrganismID ; $i++)
{
  for (my $j=0; $j<$OrganismID; $j++)
  {
    if ($Organisms{(keys %Organisms)[$j]} == $i)
    {
      print ($i,"=",(keys %Organisms)[$j]);
      if ($i+1 != $OrganismID)
	{print (",");}
      else
	{print (",>>Reference_organism=[$Ref_Organism_name],at_index=[$ref_index],Starting_from=[$start_ref]\n");}
    }
  }
}


# Output Merged MSAs
for (my $i=1; $i<$OrganismID ; $i++)
{
#DEBUG
#    print STDERR ("Genome NO. $i in position $start-",$start+$step," ",substr(@Genomes[$i],$start,$step),"\n");

    print ($Genomes[$i],"\n");
}

print STDERR "\n";



__DATA__

MergeMSAs.pl, written:  03.2007, last update: 03.2007

Sub-MSAs (Multiple Sequence Alignment) in UCSC *.mfa format are merged to full genomic MSA in *.gma format.

Command:
MergeMSAs.pl [CHROMOSOME] [REFERENCE ORGANISM] (Optional: -s)

[CHROMOSOME] - Chromosome of interest
[REFERENCE ORGANISM] - Selected organism in the MSA
(Optional: -s) - Shuffle output MSA

The sub-MSAs are connected by annotation blocks with "*" boundaries.
The annotation is either:
- [number] of bp in genomic gap
- "no seq" existing for this genome in next sub-MSA
- "Genome [number]" begins

Script validates that all merged MSAs are of the same length and prompts user accordingly if procedure was successful.
It also passes by the header line the names of the organisms and parameters regarding the reference organism for use of the Covariation_scores.pl script.

