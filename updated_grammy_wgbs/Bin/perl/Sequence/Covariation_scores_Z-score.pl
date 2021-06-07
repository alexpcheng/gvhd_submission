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

#Parameters

my $Chromosome = (split(/_chr/,  (split (/\./,@ARGV[0],2))[0] ,2))[1];
my $window = $ARGV[1];
my $Ref_Organism ;              # The index of the referance organism (SacCer, Human...)
my $Start_ref ;                 # First nucleotide of reference organism. given in the UCSC *.mfa file

my %args = load_args(\@ARGV);


### START

my $LineType;
my @header;
my $OrganismID=1;
my @Genomes;


# Getting The genomic MSAs
while(<$file_ref>)
{
    chop;
    $LineType = substr($_,0,1);
    if ($LineType eq ">")         # Header line
    {
      @header = split (/,/,substr($_,11));
      $Ref_Organism=substr($_,index($_,"Reference_organism=[")+39,index($_,"],Starting_from=[")-index($_,"Reference_organism=[")-39);
      $Start_ref=substr($_,(index($_,"],Starting_from=")+17),length(substr($_,(index($_,"],Starting_from=")+17)))-1);
#DEBUG
      #print STDERR "Ref organism=$Ref_Organism , Start at=$Start_ref\n";
    }
    else
    {
      @Genomes[$OrganismID]=$_;

#DEBUG
      #print STDERR ("orgMAX=$OrganismID ",substr(@Genomes[$OrganismID],0,50),"\n");

      $OrganismID++;
    }
}


### Stage 2 : SCORE COVARIATION (COMMPLEMENTRY CORRELATED MUTATIONS)

my @target_counter;
my $annotation_message;
my $target;
my $source;
my $next_space;
my $gap_leap = 0;
my $ScoreCoordinate = 0;
my $AnnotationFlag = 0;
my $annotation = 9;
my $genomic_counter;
my %Coordinate2RefNuc;
my %RefNuc2Coordinate;
my $MSAthickness;
my @thickness;

my $DNA_Bsn_maximal;
my $RNA_GU_Bsn_maximal;
my $RNA_AC_Bsn_maximal;
my $DNA_Bst_maximal;
my $RNA_GU_Bst_maximal;
my $RNA_AC_Bst_maximal;

my $sn_Fid_maximal;
my $sn_Div_maximal;
my $sn_flag_maximal;

my $st_Fid_maximal;
my $st_Div_maximal;
my $st_flag_maximal;

my $sn_optimal_Fid_position;
my $sn_optimal_Div_position;

my $st_optimal_Fid_position;
my $st_optimal_Div_position;

my $N = $OrganismID-1; #Number of organisms in MSA

my $AT;
my $TA;
my $CG;
my $GC;
my $GU;
my $UG;
my $AC;
my $CA;

my $DNA_legal_pairs;
my $RNA_GU_legal_pairs;
my $RNA_AC_legal_pairs;

my $C_DNA;
my $C_RNA_GU;
my $C_RNA_AC;

my @Window_B_DNA;    #Array of size 2*$window+1
my @Window_B_RNA_GU; #Array of size 2*$window+1
my @Window_B_RNA_AC; #Array of size 2*$window+1

my @Window_Fidelity; #Array of size 2*$window+1
my @Window_Diversity;#Array of size 2*$window+1
my @Window_flag; #Array of size 2*$window+1

my @ZeroArray;

my @B_DNA;           #Array of arrys. Size 3
my @B_RNA_GU;        #Array of arrys. Size 3
my @B_RNA_AC;        #Array of arrys. Size 3

my @Fidelity;        #Array of arrys. Size 3
my @Diversity;       #Array of arrys. Size 3
my @RNA_flag;        #Array of arrys. Size 3

# Final scores
my @Bsn_DNA;
my @Bsn_RNA_GU;
my @Bsn_RNA_AC;

my @Bst_DNA;
my @Bst_RNA_GU;
my @Bst_RNA_AC;

my @SRE;

# Temporary stacking arrays

my @sn_Fid;
my @sn_Div;
my @sn_flag;

my @st_Fid;
my @st_Div;
my @st_flag;

# Final Potential-only scores: four best pair in each window, three scores each
my @sn_maxFid;
my @sn_Div_maxFid;
my @sn_flag_maxFid;

my @sn_maxDiv;
my @sn_Fid_maxDiv;
my @sn_flag_maxDiv;

my @st_maxFid;
my @st_Div_maxFid;
my @st_flag_maxFid;

my @st_maxDiv;
my @st_Fid_maxDiv;
my @st_flag_maxDiv;

my @strand;
my @structure;

# For debuging
my $spacer = "  ";
my $start = 6885; # start of debug prompt
my $step=int(160/(length($spacer)+1)); # Don't change, right for screen width
my $StartTime = time();
my $prompt_step = 1000; # Prompt progress report to STDERR after $prompt_step nucleotides
my $default = -10; # It shouldn't matter what value is entered here as all default values shold be eliminated by actual data. the remains of a default may imply on an error


# DEBUG - Progress report
print STDERR "Starting run for chromosome=$Chromosome window=$window Ref_organism=$Ref_Organism Start_ref=$Start_ref\n";



# SET unstaced B-Score arrays to zero values
for (my $i=0; $i<$window*2+1; $i++)
{
  push (@ZeroArray,0);
}
for (my $i=0; $i<3; $i++)
{
  $B_DNA[$i] = [@ZeroArray];
  $B_RNA_GU[$i] = [@ZeroArray];
  $B_RNA_AC[$i] = [@ZeroArray];
  $Fidelity[$i] = [@ZeroArray];
  $Diversity[$i] = [@ZeroArray];
  $RNA_flag[$i] = [@ZeroArray];
}
my @oldthickness=@ZeroArray;

#DEBUG
#for (my $coordinate=0, $genomic_counter=$Start_ref; $coordinate<3000000; $coordinate++)

#Slide on MSA
for (my $coordinate=0, $genomic_counter=$Start_ref; $coordinate<length(@Genomes[$Ref_Organism]); $coordinate++)
{
#DEBUG
#print STDERR "\ncoor $coordinate (genomic=$genomic_counter)\n";
#DEBUG
  #if ($coordinate>10000) {$coordinate=length(@Genomes[$Ref_Organism])}
#DEBUG
  #print STDERR "- coor-$coordinate Time elapsed (sec): ",time()-$StartTime," \n";

# DEBUG - Progress report
  if (floor($coordinate/$prompt_step) != floor(($coordinate-1)/$prompt_step))
  {
    print STDERR "C-SCORE computed for ",floor($coordinate/$prompt_step)*$prompt_step," nucleotides. Time elapsed (sec): ",time()-$StartTime," \n";
  }

#DEBUG
  #print ("\ndebug1: entering coordinate walk. coordinate=$coordinate source=",substr(@Genomes[$Ref_Organism],$coordinate,1),"\n");

  if (substr(@Genomes[$Ref_Organism],$coordinate,1) eq "*")
  {
    $next_space=index(substr(@Genomes[$Ref_Organism], $coordinate+2,$annotation)," ");
    #print ("sub=",substr(@Genomes[$Ref_Organism], $coordinate+2,$annotation)," next=$next_space\n");
    $annotation_message=substr(@Genomes[$Ref_Organism], $coordinate+2, $next_space);

    # If the annotation is a gap size. Update this condition if new text annotations are added
    if ($annotation_message ne "no-seq" && $annotation_message ne "Genome")
    {
      #print ("next=$next_space annotation=$annotation_message,coor=$coordinate source=$source genomic counter set from $genomic_counter to ",$genomic_counter+$annotation_message,"\n");
      $genomic_counter+=$annotation_message;
    }

    # Insert a blank (@ZeroArray) B-Score array of arrays for the Bs(n/t)-Scores
    push (@B_DNA,[@ZeroArray]);
    @B_DNA = @B_DNA[1..3];
    push (@B_RNA_GU,[@ZeroArray]);
    @B_RNA_GU = @B_RNA_GU[1..3];
    push (@B_RNA_AC,[@ZeroArray]);
    @B_RNA_AC = @B_RNA_AC[1..3];
    push (@Fidelity,[@ZeroArray]);
    @Fidelity = @Fidelity[1..3];
    push (@Diversity,[@ZeroArray]);
    @Diversity = @Diversity[1..3];
    push (@RNA_flag,[@ZeroArray]);
    @RNA_flag = @RNA_flag[1..3];

#    ###
#    if (!$AnnotationFlag)
#      {$AnnotationFlag = 1;}
#    else
#      {$ScoreCoordinate=$coordinate-1;}
#    ###

    $AnnotationFlag = 1;
    $coordinate+=$annotation+2;
    ##print (" debug7: source out of MSA - leaping to next MSA. coordinate=$coordinate new source=",substr(@Genomes[$Ref_Organism],$coordinate+1,1),"\n");
    next;
  }

  # $Coordinate is in MSA region

  # The $%Coordinate2RefNuc hash converts coordinates to nucleotide position in reference organism. as long as there is no gap the two counters add together
  if (substr(@Genomes[$Ref_Organism],$coordinate,1) ne "-")
  {
    $Coordinate2RefNuc{$coordinate}=$genomic_counter;
    $RefNuc2Coordinate{$genomic_counter}=$coordinate;
    $genomic_counter++;
  }

  # Reseting array
  for (my $org=1; $org<$OrganismID; $org++)
  {
    @target_counter[$org]=0;
  }


  #B-Score for a coordinate over itself is set to the minimum -1
  @Window_Fidelity[$window] = 0;
  @Window_Diversity[$window] = 0;
  @Window_flag[$window] = 0;
  @Window_B_DNA[$window] = $default;
  @Window_B_RNA_GU[$window] = $default;
  @Window_B_RNA_AC[$window] = $default;

  @thickness[$window] = $default;



  # Start of right walk, from the source coordinate downstream
  # Search within pre-defined neighborhood window
  for (my $window_position=1, my $window_done=0; $window_done == 0; $window_position+=1+$gap_leap)
  {
#DEBUG
  #print STDERR "-- coor-$coordinate window-pos-$window_position time-",time()-$StartTime,"\n";


    #print (" right -new target- coordinate=$coordinate window_pos=$window_position\n");
    #print (" right debug2: entering window walk. window position=$window_position\n");
#DEBUG
    #print STDERR "\n";
    $gap_leap = 0;

    $AT=0;
    $TA=0;
    $CG=0;
    $GC=0;
    $GU=0;
    $UG=0;
    $AC=0;
    $CA=0;

#Z-score
    $MSAthickness=0;

    # Look at each row (organism) in MSA
    for (my $org=1; $org<$OrganismID; $org++)
    {
#DEBUG
      #print STDERR "--- orgMAX-$OrganismID org $org counter-@target_counter[$org] time",time()-$StartTime,"\n";

      # Is the window finished for the current organism?
      if (@target_counter[$org]>=$window) {next;}

      $target=substr(@Genomes[$org],$coordinate+$window_position,1);
      $source=substr(@Genomes[$org],$coordinate,1);

      #print ("  debug3 right: entering org scroll. source=$source, coordinate=$coordinate window_position=$window_position org=$org target=$target, counter[$org]=",@target_counter[$org],"\n");

      # When $target in MSA advance organism target_counter by 1 and compute C score
      if ($target eq "A" || $target eq "T" || $target eq "C" || $target eq "G" || $target eq "-" || $target eq "\\")
      {	
	
      #Z-score
	if ($target ne "-" && $target ne "\\" && $source ne "-" && $source ne "\\")
	  {$MSAthickness++;}

	#print ("source=$source target=$target coor=$coordinate pos=$window_position org=$org ");

	if ($source eq "A" && $target eq "T")
	{
	  #print "AT in $coordinate pos $window_position\n";
	  $AT++;
	}

	if ($source eq "T" && $target eq "A")
	{
	  #print "TA in $coordinate pos $window_position \n";
	  $TA++;
	}

	if ($source eq "C" && $target eq "G")
        {
	  #print "CG in $coordinate pos $window_position \n";
	  $CG++;
	}

	if ($source eq "G" && $target eq "C")
	{
	  #print "GC in $coordinate pos $window_position \n";
	  $GC++;
	}

	if ($source eq "G" && $target eq "T")
	{
	  #print "GU in $coordinate pos $window_position \n";
	  $GU++;
	}

	if ($source eq "T" && $target eq "G")
	{
	  #print "UG in $coordinate pos $window_position \n";
	  $UG++;
	}

	if ($source eq "A" && $target eq "C")
	{
	  #print "AC in $coordinate pos $window_position \n";
	  $AC++;
	}

	if ($source eq "C" && $target eq "A")
        {
	  #print "CA in $coordinate pos $window_position \n";
	  $CA++;
	}

	@target_counter[$org]++;
      }
      # annotation block
      elsif ($target eq "*")
      {
	$next_space=index(substr(@Genomes[$org], $coordinate+$window_position+2,$annotation)," ");
	$annotation_message=substr(@Genomes[$org], $coordinate+$window_position+2, $next_space);
	#print ("   right debug4: annotation_message=$annotation_message, target_counter[$org]=",@target_counter[$org]," next-space=$next_space \n");
	
	# Unpassable gap (missing next sequence, new genomic sequence, overlapping sequences)
	if ($annotation_message eq "no-seq" || $annotation_message eq "Genome" || $annotation_message < 0)
	{
	  @target_counter[$org]=$window;
	  #print ("     right debug5: unpassable gap. target_counter[$org]=",@target_counter[$org],"\n");
	}
	else
	{
	  @target_counter[$org]+=$annotation_message;
	  ##print ("      debug6: passable gap of $annotation_message bp. target_counter[$org]=",@target_counter[$org],"\n");
	}
	$gap_leap = $annotation+2;
      }

      #checking if all organisms had $window number of step
      for (my $org=1, $window_done=1; $org<$OrganismID; $org++)
      {
	#if ($org == $Ref_Organism) {next;}
	if (@target_counter[$org]<$window && $coordinate+$window_position<length(@Genomes[$Ref_Organism])) {$window_done=0;}
      }
    }



      ##print ("      debug8: done=$window_done \n");
      ##print ("debug9: source coordinate $coordinate, source=",substr(@Genomes[$Ref_Organism],$coordinate,1)," compared at org $org, position $window_position, to $target. ",@target_counter[$org]<$window," \n");

    #print (" debug right. coordinate=$coordinate ($source) window_step=$window_position ($target) = compute C\n");

  $DNA_legal_pairs   =$AT+$TA+$CG+$GC;
  $RNA_GU_legal_pairs=$AT+$TA+$CG+$GC+$GU+$UG;
  $RNA_AC_legal_pairs=$AT+$TA+$CG+$GC+$AC+$CA;


  @Window_Fidelity[$window+$window_position] = $DNA_legal_pairs;
  @Window_Diversity[$window+$window_position] = !($AT eq 0) + !($TA eq 0) + !($CG eq 0) + !($GC eq 0);
  @Window_flag[$window+$window_position] = !($GU eq 0) || !($UG eq 0) || !($AC eq 0) || !($CA eq 0);
  if (@Window_flag[$window+$window_position]!= 1) {@Window_flag[$window+$window_position]=0;}

#Z-score
  @thickness[$window+$window_position] = $MSAthickness;

#DEBUG
  #print ("coor=$coordinate pos=$window+$window_position RefNuc=$Coordinate2RefNuc{$coordinate} AT=$AT TA=$TA CG=$CG GC=$GC GU=$GU UG=$UG AC=$AC CA=$CA Fid=@Window_Fidelity[$window+$window_position] Div=@Window_Diversity[$window+$window_position] flag=@Window_flag[$window+$window_position] \n");

  #if ($DNA_legal_pairs>0) {print STDERR "$DNA_legal_pairs pairs in $coordinate AT=$AT TA=$TA CG=$CG GC=$GC\n";}
	
  #Compute DNA C-Score
  $C_DNA=0;
  for (my $temp_AT=$AT, my $temp_TA=$TA, my $temp_CG=$CG, my $temp_GC=$GC, my $temp_DNA_legal_pairs=$DNA_legal_pairs;
     $temp_DNA_legal_pairs;
        $temp_DNA_legal_pairs=$temp_AT+$temp_TA+$temp_CG+$temp_GC)
	{
	  for (; $temp_AT ; $temp_AT--)
	  {
	    $C_DNA+=0*($temp_AT-1) + 1*(0) + 2*($temp_TA+$temp_CG+$temp_GC);
	  }
	  for (; $temp_TA ; $temp_TA--)
	  {
	    $C_DNA+=0*($temp_TA-1) + 1*(0) + 2*($temp_CG+$temp_GC);
	  }
	  for (; $temp_CG ; $temp_CG--)
	  {
	    $C_DNA+=0*($temp_CG-1) + 1*(0) + 2*($temp_GC);
	  }
	  for (; $temp_GC ; $temp_GC--)
	  {
	    $C_DNA+=0*($temp_GC-1) + 1*(0) + 2*(0);
	  }

	}
    #print ("debug5 right  coor=$coordinate pos=$window_position C-SCORE=$C_DNA\n ");

    # q penelty for illegal pairs


    @Window_B_DNA[$window+$window_position] = $C_DNA-($N-$DNA_legal_pairs)/($N);
    #print (" debug right coor=$coordinate C-score=$C_DNA illegal pairs=",$N-$DNA_legal_pairs," B-SCORE=@Window_B_DNA[$window+$window_position]\n");

  #Compute RNA_GU C-Score
  $C_RNA_GU=0;
  for (my $temp_AT=$AT, my $temp_TA=$TA, my $temp_CG=$CG, my $temp_GC=$GC, my $temp_GU=$GU, my $temp_UG=$UG, my $temp_RNA_GU_legal_pairs=$RNA_GU_legal_pairs;
     $temp_RNA_GU_legal_pairs;
        $temp_RNA_GU_legal_pairs=$temp_AT+$temp_TA+$temp_CG+$temp_GC+$temp_GU+$temp_UG)
	{
	  for (; $temp_AT ; $temp_AT--)
	  {
	    $C_RNA_GU+=0*($temp_AT-1) + 1*($temp_GU) + 2*($temp_TA+$temp_CG+$temp_GC+$temp_UG);
	  }
	  for (; $temp_TA ; $temp_TA--)
	  {
	    $C_RNA_GU+=0*($temp_TA-1) + 1*($temp_UG) + 2*($temp_CG+$temp_GC+$temp_GU);
	  }
	  for (; $temp_CG ; $temp_CG--)
	  {
	    $C_RNA_GU+=0*($temp_CG-1) + 1*($temp_UG) + 2*($temp_GC+$temp_GU);
	  }
	  for (; $temp_GC ; $temp_GC--)
	  {
	    $C_RNA_GU+=0*($temp_GC-1) + 1*($temp_GU) + 2*($temp_UG);
	  }
	  for (; $temp_GU ; $temp_GU--)
	  {
	    $C_RNA_GU+=0*($temp_GU-1) + 1*(0) + 2*($temp_UG);
	  }
	  # Meaningless for score, just for easing the understanding of the score
	  for (; $temp_UG ; $temp_UG--)
	  {
	    $C_RNA_GU+=0*($temp_UG-1) + 1*(0) + 2*(0);
	  }

	}

    #print ("debug5 right  coor=$coordinate pos=$window_position C-SCORE=$C_RNA_GU\n ");

    # q penelty for illegal pairs

    @Window_B_RNA_GU[$window+$window_position] = $C_RNA_GU-($N-$RNA_GU_legal_pairs)/($N);

  #print STDERR "$coordinate ";
  #if ($RNA_AC_legal_pairs>0) {print STDERR "$RNA_AC_legal_pairs pairs in $coordinate AT=$AT TA=$TA CG=$CG GC=$GC AC=$AC CA=$CA\n";}
	
  #Compute RNA_AC C-Score
  $C_RNA_AC=0;
  for (my $temp_AT=$AT, my $temp_TA=$TA, my $temp_CG=$CG, my $temp_GC=$GC, my $temp_AC=$AC, my $temp_CA=$CA, my $temp_RNA_AC_legal_pairs=$RNA_AC_legal_pairs;
     $temp_RNA_AC_legal_pairs;
        $temp_RNA_AC_legal_pairs=$temp_AT+$temp_TA+$temp_CG+$temp_GC+$temp_AC+$temp_CA)
	{
	  for (; $temp_AT ; $temp_AT--)
	  {
	    $C_RNA_AC+=0*($temp_AT-1) + 1*($temp_AC) + 2*($temp_TA+$temp_CG+$temp_GC+$temp_CA);
	  }
	  for (; $temp_TA ; $temp_TA--)
	  {
	    $C_RNA_AC+=0*($temp_TA-1) + 1*($temp_CA) + 2*($temp_CG+$temp_GC+$temp_AC);
	  }
	  for (; $temp_CG ; $temp_CG--)
	  {
	    $C_RNA_AC+=0*($temp_CG-1) + 1*($temp_CA) + 2*($temp_GC+$temp_AC);
	  }
	  for (; $temp_GC ; $temp_GC--)
	  {
	    $C_RNA_AC+=0*($temp_GC-1) + 1*($temp_AC) + 2*($temp_CA);
	  }
	  for (; $temp_AC ; $temp_AC--)
	  {
	    $C_RNA_AC+=0*($temp_AC-1) + 1*(0) + 2*($temp_CA);
	  }
	  # Meaningless for score, just for easing the understanding of the score
	  for (; $temp_CA ; $temp_CA--)
	  {
	    $C_RNA_AC+=0*($temp_CA-1) + 1*(0) + 2*(0);
	  }

	}
    #print ("debug5 right  coor=$coordinate pos=$window_position C-SCORE=$C_RNA_AC\n ");

    # q penelty for illegal pairs

    @Window_B_RNA_AC[$window+$window_position] = $C_RNA_AC-($N-$RNA_AC_legal_pairs)/($N);
    #print (" debug right coor=$coordinate C-score=$C_RNA_AC illegal pairs=",$N-$RNA_AC_legal_pairs," B-SCORE=@Window_B_RNA_AC[$window+$window_position]\n");

  }

# end of right walk






# B-scores (unstacked) arrays have 3 cells.
# Push to the end of each B-score array the current window's B-scores and pop out the first cell.
# Cell [0]:$coordinate-2 scores, Cell [1]:$coordinate-1 scores, Cell [2]:$coordinate scores.


push (@B_DNA,[@Window_B_DNA]);
@B_DNA = @B_DNA[1..3];

push (@B_RNA_GU,[@Window_B_RNA_GU]);
@B_RNA_GU = @B_RNA_GU[1..3];

push (@B_RNA_AC,[@Window_B_RNA_AC]);
@B_RNA_AC = @B_RNA_AC[1..3];

push (@Fidelity,[@Window_Fidelity]);
@Fidelity = @Fidelity[1..3];

push (@Diversity,[@Window_Diversity]);
@Diversity = @Diversity[1..3];

push (@RNA_flag,[@Window_flag]);
@RNA_flag = @RNA_flag[1..3];

# Deals with Bs(n/t) scoring the last cordinate before an annotation block
if (!$AnnotationFlag)
  {$ScoreCoordinate = $coordinate-1;}
else
  {$ScoreCoordinate++}

#print STDERR "  Annotation flag=$AnnotationFlag. Seting scores for $ScoreCoordinate \n";

#DEBUG
  #if ($ScoreCoordinate==18)
  #{
  #  print ("");
  #}


# Compute Bs(n/t)-Scores
  for (my $j=$window+1;$j<$window*2+1;$j++)
  {
#DEBUG
  #if ($j==17)
  #{
  #  print ("");
  #}
#DEBUG
    #print ("debug Bsn-Scores: coor=",$ScoreCoordinate," position=$j (",$j-$window,") RefNuc=$Coordinate2RefNuc{$ScoreCoordinate}\n");
    #print ("      DNA-B-Score=",$B_DNA[1][$j]," RNA-GU_B-Score=",$B_RNA_GU[1][$j]," RNA-AC_B-Score=",$B_RNA_AC[1][$j]);
    #print (" Fidelity=",$Fidelity[1][$j]," Diversity=",$Diversity[1][$j]," flag=",$RNA_flag[1][$j],"\n");

    if ($j!=$window)
    {
      # Compute Bsn-Scores:
      $Bsn_DNA[$ScoreCoordinate][$j]=2*$B_DNA[1][$j];
      $Bsn_RNA_GU[$ScoreCoordinate][$j]=2*$B_RNA_GU[1][$j];
      $Bsn_RNA_AC[$ScoreCoordinate][$j]=2*$B_RNA_AC[1][$j];
      $sn_Fid[$ScoreCoordinate][$j]=2*$Fidelity[1][$j];
      $sn_Div[$ScoreCoordinate][$j]=2*$Diversity[1][$j];
      $sn_flag[$ScoreCoordinate][$j]=2*$RNA_flag[1][$j];

      # In case target is not at the end of the window and the two are not adjacent: take into account the "outer" neighbors
      if (($j-$window)!=$window && ($j-$window)!=$window-1 && ($j-$window)!=-1 && ($j-$window)!=-2)
	{
	  $Bsn_DNA[$ScoreCoordinate][$j]+=$B_DNA[0][$j+2];
	  $Bsn_RNA_GU[$ScoreCoordinate][$j]+=$B_RNA_GU[0][$j+2];
	  $Bsn_RNA_AC[$ScoreCoordinate][$j]+=$B_RNA_AC[0][$j+2];
	  $sn_Fid[$ScoreCoordinate][$j]+=$Fidelity[0][$j+2];
	  $sn_Div[$ScoreCoordinate][$j]+=$Diversity[0][$j+2];
	  $sn_flag[$ScoreCoordinate][$j]+=$RNA_flag[0][$j+2];
	  #print ("j+1=",$j+1-$window," \n");
        }

      # In case target is not at the begining of the window and the two are not adjacent: take into account the "inner" neighbors
      if ($j!=0 && $j!=1 && ($j-$window)!=1 && ($j-$window)!=2)
	{
	  $Bsn_DNA[$ScoreCoordinate][$j]+=$B_DNA[2][$j-2];
	  $Bsn_RNA_GU[$ScoreCoordinate][$j]+=$B_RNA_GU[2][$j-2];
	  $Bsn_RNA_AC[$ScoreCoordinate][$j]+=$B_RNA_AC[2][$j-2];
	  $sn_Fid[$ScoreCoordinate][$j]+=$Fidelity[2][$j+2];
	  $sn_Div_maxFid[$ScoreCoordinate][$j]+=$Diversity[2][$j+2];
	  $sn_flag[$ScoreCoordinate][$j]+=$RNA_flag[2][$j+2];
	  #print ("j-1=",$j-1-$window," \n");
        }
      $Bsn_DNA[$ScoreCoordinate][$j]=sprintf ("%.0f",$Bsn_DNA[$ScoreCoordinate][$j]/4);
      $Bsn_RNA_GU[$ScoreCoordinate][$j]=sprintf ("%.0f",$Bsn_RNA_GU[$ScoreCoordinate][$j]/4);
      $Bsn_RNA_AC[$ScoreCoordinate][$j]=sprintf ("%.0f",$Bsn_RNA_AC[$ScoreCoordinate][$j]/4);
      $sn_Fid[$ScoreCoordinate][$j]=sprintf ("%.1f",$sn_Fid[$ScoreCoordinate][$j]/4);
      $sn_Div[$ScoreCoordinate][$j]=sprintf ("%.1f",$sn_Div[$ScoreCoordinate][$j]/4);
      $sn_flag[$ScoreCoordinate][$j]=sprintf ("%.1f",$sn_flag[$ScoreCoordinate][$j]/4);

      #print STDERR "    debug Bsn done. coor=",$ScoreCoordinate," position=$j (",$j-$window,") \n";
      #print STDERR            DNA-B-Score=",$B_DNA[1][$j]," final DNA-Bsn-score=$Bsn_DNA[$ScoreCoordinate][$j]\n";


      # Compute Bst-Scores:
      $Bst_DNA[$ScoreCoordinate][$j]=2*$B_DNA[1][$j];
      $Bst_RNA_GU[$ScoreCoordinate][$j]=2*$B_RNA_GU[1][$j];
      $Bst_RNA_AC[$ScoreCoordinate][$j]=2*$B_RNA_AC[1][$j];
      $st_Fid[$ScoreCoordinate][$j]=2*$Fidelity[1][$j];
      $st_Div[$ScoreCoordinate][$j]=2*$Diversity[1][$j];
      $st_flag[$ScoreCoordinate][$j]=2*$RNA_flag[1][$j];

      # In case sorce and target are not adjacent
      if (($j-$window)!=-1 && ($j-$window)!=1)
	{
	  $Bst_DNA[$ScoreCoordinate][$j]+=$B_DNA[0][$j]+$B_DNA[2][$j];
	  $Bst_RNA_GU[$ScoreCoordinate][$j]+=$B_RNA_GU[0][$j]+$B_RNA_GU[2][$j];
	  $Bst_RNA_AC[$ScoreCoordinate][$j]+=$B_RNA_AC[0][$j]+$B_RNA_AC[2][$j];
	  $st_Fid[$ScoreCoordinate][$j]+=$Fidelity[0][$j]+$Fidelity[2][$j];
	  $st_Div[$ScoreCoordinate][$j]+=$Diversity[0][$j]+$Diversity[2][$j];
	  $st_flag[$ScoreCoordinate][$j]+=$RNA_flag[0][$j]+$RNA_flag[2][$j];

	  #print ("j+1=",$j+1-$window," \n");
        }
      $Bst_DNA[$ScoreCoordinate][$j]=sprintf ("%.0f",$Bst_DNA[$ScoreCoordinate][$j]/4);
      $Bst_RNA_GU[$ScoreCoordinate][$j]=sprintf ("%.0f",$Bst_RNA_GU[$ScoreCoordinate][$j]/4);
      $Bst_RNA_AC[$ScoreCoordinate][$j]=sprintf ("%.0f",$Bst_RNA_AC[$ScoreCoordinate][$j]/4);
      $st_Fid[$ScoreCoordinate][$j]=sprintf ("%.1f",$st_Fid[$ScoreCoordinate][$j]/4);
      $st_Div[$ScoreCoordinate][$j]=sprintf ("%.1f",$st_Div[$ScoreCoordinate][$j]/4);
      $st_flag[$ScoreCoordinate][$j]=sprintf ("%.1f",$st_flag[$ScoreCoordinate][$j]/4);


      #print STDERR "    debug Bst done. coor=",$ScoreCoordinate," position=$j (",$j-$window,") \n";
      #print STDERR            DNA-B-Score=",$B_DNA[1][$j]," final DNA-Bst-score=$Bst_DNA[$ScoreCoordinate][$j]\n";
    }

#DEBUG
      #print STDERR "---- outputing for coor-$coordinate time-",time()-$StartTime,"\n";

    #Z-score
    print ("coor\t$ScoreCoordinate\tstep\t",$j-$window,"\tthickness\t@oldthickness[$j]\tDNA-Bsn\t$Bsn_DNA[$ScoreCoordinate][$j]\n");
    print ("coor\t$ScoreCoordinate\tstep\t",$j-$window,"\tthickness\t@oldthickness[$j]\tDNA-Bst\t$Bst_DNA[$ScoreCoordinate][$j]\n");
    print ("coor\t$ScoreCoordinate\tstep\t",$j-$window,"\tthickness\t@oldthickness[$j]\tRNA_GU-Bsn\t$Bst_RNA_GU[$ScoreCoordinate][$j]\n");
    print ("coor\t$ScoreCoordinate\tstep\t",$j-$window,"\tthickness\t@oldthickness[$j]\tRNA_GU-Bst\t$Bst_RNA_GU[$ScoreCoordinate][$j]\n");
    print ("coor\t$ScoreCoordinate\tstep\t",$j-$window,"\tthickness\t@oldthickness[$j]\tRNA_AC-Bsn\t$Bst_RNA_AC[$ScoreCoordinate][$j]\n");
    print ("coor\t$ScoreCoordinate\tstep\t",$j-$window,"\tthickness\t@oldthickness[$j]\tRNA_AC-Bst\t$Bst_RNA_AC[$ScoreCoordinate][$j]\n");
  }
  @oldthickness=@thickness;


# strand: -1=GU 1=AC 0=DNA/NA
  if (@Bsn_RNA_GU[$ScoreCoordinate]>@Bsn_RNA_AC[$ScoreCoordinate] || @Bst_RNA_GU[$ScoreCoordinate]>@Bst_RNA_AC[$ScoreCoordinate])
    {@strand[$ScoreCoordinate]=-1;}
  elsif (@Bsn_RNA_AC[$ScoreCoordinate]>@Bsn_RNA_GU[$ScoreCoordinate] || @Bst_RNA_AC[$ScoreCoordinate]>@Bst_RNA_GU[$ScoreCoordinate])
    {@strand[$ScoreCoordinate]=1;}
  else
    {@strand[$ScoreCoordinate]=0;}

# structure: -1=Stem&Loop 1=Pseudoknot 0=NA
  if (@Bsn_RNA_GU[$ScoreCoordinate]>@Bst_RNA_GU[$ScoreCoordinate] || @Bsn_RNA_AC[$ScoreCoordinate]>@Bst_RNA_AC[$ScoreCoordinate])
    {@structure[$ScoreCoordinate]=-1;}
  elsif (@Bst_RNA_GU[$ScoreCoordinate]>@Bsn_RNA_GU[$ScoreCoordinate] || @Bst_RNA_AC[$ScoreCoordinate]>@Bsn_RNA_AC[$ScoreCoordinate])
    {@structure[$ScoreCoordinate]=1;}
  else
    {@structure[$ScoreCoordinate]=0;}

  if (!@Bsn_DNA[$ScoreCoordinate])
    {@Bsn_DNA[$ScoreCoordinate]=0;}
  if (!@Bsn_RNA_GU[$ScoreCoordinate])
    {@Bsn_RNA_GU[$ScoreCoordinate]=0;}
  if (!@Bsn_RNA_AC[$ScoreCoordinate])
    {@Bst_RNA_AC[$ScoreCoordinate]=0;}
  if (!@Bst_DNA[$ScoreCoordinate])
    {@Bst_DNA[$ScoreCoordinate]=0;}
  if (!@Bst_RNA_GU[$ScoreCoordinate])
    {@Bst_RNA_GU[$ScoreCoordinate]=0;}
  if (!@Bst_RNA_AC[$ScoreCoordinate])
    {@Bst_RNA_AC[$ScoreCoordinate]=0;}

  #print (" coor=",$ScoreCoordinate,"\n");
  #print ("  Final: Bsn_DNA=@Bsn_DNA[$ScoreCoordinate] Bsn_RNA_GU=@Bsn_RNA_GU[$ScoreCoordinate] Bsn_RNA_AC=@Bsn_RNA_AC[$ScoreCoordinate]\n");
  #print ("         Bst_DNA=@Bst_DNA[$ScoreCoordinate] Bst_RNA_GU=@Bst_RNA_GU[$ScoreCoordinate] Bst_RNA_AC=@Bst_RNA_AC[$ScoreCoordinate]\n\n");



# Get Putative SRE tracts
  if (@Bsn_DNA[$ScoreCoordinate]==@Bsn_RNA_GU[$ScoreCoordinate] && @Bsn_DNA[$ScoreCoordinate]==@Bsn_RNA_AC[$ScoreCoordinate])
    {@SRE[$ScoreCoordinate] = @Bsn_DNA[$ScoreCoordinate];}
  elsif (@Bst_DNA[$ScoreCoordinate]==@Bst_RNA_GU[$ScoreCoordinate] && @Bst_DNA[$ScoreCoordinate]==@Bst_RNA_AC[$ScoreCoordinate])
    {@SRE[$ScoreCoordinate] = @Bst_DNA[$ScoreCoordinate];}
  else
    {@SRE[$ScoreCoordinate] = 0;}

#Reseting arrays
  for (my $i=0; $i<$window*2+1; $i++)
  {
    @Window_B_DNA[$i]=0;
    @Window_B_RNA_GU[$i]=0;
    @Window_B_RNA_AC[$i]=0;
    @Window_Fidelity[$i]=0;
    @Window_Diversity[$i]=0;
    @Window_flag[$i]=0;

    @thickness[$i]=0;
  }


  $AnnotationFlag = 0;
  $ScoreCoordinate = $coordinate-1;
}


__DATA__


Covariation_scores.pl, written:  03.2007, last update: 03.2007

DNA and RNA covariation analysis of full genomic MSA *.gma files, made by MergeMSAs.pl script.
Output in *.chv format is designated as input for the Genomica package.
Made to assess the SRE hypothesis.

Command:
Covariation_scores.pl [GENOMIC MSA FILE] [WINDOW]

[GENOMIC MSA FILE] - Genomic Multiple Sequence Alignment input file (*.gma). Contains parameters regarding reference organism on header line.
[WINDOW] - Maximal distance between compared genomic positions. Bi-directional.

RNA allifold scores (secondary structure potential and mutual information):
 DNA-Bsn: DNA covariation score, stacking for Stem&Loop (nested)
 DNA-Bst: DNA covariation score, stacking for Pseudoknots (tandem)
 RNA_GU-Bsn: RNA covariation score (GU strand), stacking for Stem&Loop (nested)
 RNA_GU-Bst: RNA covariation score (GU strand), stacking for Pseudoknots (tandem)
 RNA_AC-Bsn: RNA covariation score (AC strand), stacking for Stem&Loop (nested)
 RNA_AC-Bst: RNA covariation score (AC strand), stacking for Pseudoknots (tandem)




