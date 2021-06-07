#!/usr/bin/perl

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $new_motif_file = shift(@ARGV);
my $known_motif_file = shift(@ARGV);
my $confidence = shift(@ARGV);
my $boot_loop = 5;

my $CONFIDENCE_01 = 0;
my $CONFIDENCE_05 = 1;
my $CONFIDENCE_10 = 2;

my $gap_penalty = -1000; #no gaps allowed
#my $match_scr = 1;
#my $mismatch_scr = -1;

#global scratch space for the aligner functions
my @score_matrix;
my @back_point_x;
my @back_point_y;

# read in the gxm files
my @known_motif_weights;
my @known_motif_names;
my @known_motif_lens;
ReadInPssms($known_motif_file, \@known_motif_weights, \@known_motif_names, \@known_motif_lens);
#PrintPssmStructs(\@known_motif_weights, \@known_motif_names, \@known_motif_lens);
my $num_known_motifs = @known_motif_names;

my @new_motif_weights;
my @new_motif_names;
my @new_motif_lens;
ReadInPssms($new_motif_file, \@new_motif_weights, \@new_motif_names, \@new_motif_lens);
my $num_new_motifs = @new_motif_names;

#die "done for now";
my @cutoffs = EstimateCutoffs(\@known_motif_weights, \@known_motif_lens, \@new_motif_weights, \@new_motif_lens);

#roll through finding the best matches
for (my $new_motif_i = 0; $new_motif_i < $num_new_motifs; $new_motif_i++)
{
   my $new_mot_name = $new_motif_names[$new_motif_i];
   my $new_mot_len = $new_motif_lens[$new_motif_i];
   my @new_mot_pssm = $new_motif_weights[$new_motif_i];

   for (my $k_motif_i = 0; $k_motif_i < $num_known_motifs; $k_motif_i++)
   {
       my $k_mot_name = $known_motif_names[$k_motif_i];
       my $k_mot_len = $known_motif_lens[$k_motif_i];
       my @k_mot_pssm = $known_motif_weights[$k_motif_i];

       my $score = Align(@new_mot_pssm, $new_mot_len, @k_mot_pssm, $k_mot_len, "no");

       if (($score > $cutoffs[$CONFIDENCE_01]) && ($k_mot_name ne $new_mot_name))
       {
	   print "Match\t$new_mot_name\tTo\t$k_mot_name\tScore\t$score\tConfidence\t0.01\n";
       }
       if (($score > $cutoffs[$CONFIDENCE_05]) && ($k_mot_name ne $new_mot_name))
       {
	   print "Match\t$new_mot_name\tTo\t$k_mot_name\tScore\t$score\tConfidence\t0.05\n";
       }
       if (($score > $cutoffs[$CONFIDENCE_10]) && ($k_mot_name ne $new_mot_name))
       {
	   print "Match\t$new_mot_name\tTo\t$k_mot_name\tScore\t$score\tConfidence\t0.10\n";
       }
   }
}

sub Align {
   my @new_mot_pssm = shift(@_);
   my $len1 = shift(@_);
   my @k_mot_pssm = shift(@_);
   my $len2 = shift(@_);
   my $print_tok = shift(@_);

   my $x;
   my $y;

   #initialize first column and row to 0
   for ($x = 0; $x <= $len2; $x++) {
      $score_matrix[0][$x] = 0;
      $back_point_x[0][$x] = $x - 1;
      $back_point_y[0][$x] = 0;
   }
   for ($y = 0; $y <= $len1; $y++) {
      $score_matrix[$y][0] = 0;
      $back_point_y[$y][0] = $y - 1;
      $back_point_x[$y][0] = 0;
   }

   $back_point_x[0][0] = 0;
   $back_point_y[0][0] = 0;

   #now roll through and compute the best scores,
   #storing the back pointers
   for ($y = 1; $y <= $len1; $y++) {
      for ($x = 1; $x <= $len2; $x++) {
         my $u_score = $score_matrix[$y - 1][$x] + $gap_penalty;
         if ($x == $len2) {
            $u_score-=$gap_penalty;
         }
         my $l_score = $score_matrix[$y][$x - 1] + $gap_penalty;
         if ($y == $len1) {
            $l_score-=$gap_penalty;
         }
         my $lu_score = $score_matrix[$y - 1][$x - 1] +
               Match(@new_mot_pssm, $y - 1, @k_mot_pssm, $x - 1);
         RecordMax($u_score, $l_score, $lu_score, $y, $x);
      }
   }

   my $best_score = $score_matrix[$len1][$len2];

   if ($print_tok eq "yes") {
      #PrintAlignment($con1, $con2, $len1, $len2);
   }

   #PrintMatrices($len1, $len2);

   return $best_score;
}

sub PrintMatrices {
   my $len1 = shift(@_);
   my $len2 = shift(@_);

   for (my $y = 0; $y <= $len1; $y++) {
      print "\n";
      for (my $x = 0; $x <= $len2; $x++) {
         print "$score_matrix[$y][$x]\t($back_point_y[$y][$x], $back_point_x[$y][$x])| ";
      }
   }
   print "\n";
}


#sub PrintAlignment {
#   my $con1 = shift(@_);
#   my $con2 = shift(@_);
#   my $best_y = shift(@_);
#   my $best_x = shift(@_);

#   my $con1_gapped = "";
#   my $con2_gapped = "";

#   my $next_x;
#   my $next_y;

   #print "Entered print alignment for $con1 and $con2 with (besty,bestx) = ($best_y,$best_x)\n";
 #  my $y = $best_y;
 #  my $x = $best_x;

#   while ($y > 0 || $x > 0) {
#      $next_x = $back_point_x[$y][$x];
#      $next_y = $back_point_y[$y][$x];

      #print "At (y,x) = ($y,$x), (next_y,next_x) = ($next_y, $next_x)\n";
      #pointing up 
#      if ($next_x == $x) {
#         $next_y == $y - 1 ||
#            die "invalid next y";
#         my $n_char = substr($con1, $y - 1, 1);
#         $con1_gapped = $n_char.$con1_gapped;
#         $con2_gapped = "-".$con2_gapped;
#      } elsif ($next_y == $y) { #left
#         $next_x == $x - 1 ||
#            die "invalid next x";
#         my $n_char = substr($con2, $x - 1, 1);
#         $con2_gapped = $n_char.$con2_gapped;
#         $con1_gapped = "-".$con1_gapped;
#      } else { #left and up
#         $next_x == $x - 1 && $next_y == $y - 1 ||
#            die "invalid next x, y";
#         my $ny_char = substr($con1, $y - 1, 1);
#         my $nx_char = substr($con2, $x - 1, 1);
#         $con2_gapped = $nx_char.$con2_gapped;
#         $con1_gapped = $ny_char.$con1_gapped;
#      }
#
#      $y = $next_y;
#      $x = $next_x;
#   }
#
#   ($y == 0 && $x == 0) ||
#      die "print traceback failed\n";
#
#   print "\n$con1_gapped\n$con2_gapped\n";
#}

sub RecordMax {
   my $u_score = shift(@_);
   my $l_score = shift(@_);
   my $lu_score = shift(@_);
   my $y = shift(@_);
   my $x = shift(@_);

   $score_matrix[$y][$x] = $u_score;
   $back_point_x[$y][$x] = $x;
   $back_point_y[$y][$x] = $y - 1;
   my $curr_score = $u_score;

   if ($l_score >= $curr_score) {
       $score_matrix[$y][$x] = $l_score;
       $back_point_x[$y][$x] = $x - 1;
       $back_point_y[$y][$x] = $y;
       $curr_score = $l_score;
   }

   if ($lu_score >= $curr_score) {
       $score_matrix[$y][$x] = $lu_score;
       $back_point_x[$y][$x] = $x - 1;
       $back_point_y[$y][$x] = $y - 1;
       $curr_score = $lu_score;
   }
}

sub Match {
   my @new_mot_pssm = shift(@_);
   my $y = shift(@_);
   my @k_mot_pssm = shift(@_);
   my $x = shift(@_);

   my @new_pos = $new_mot_pssm[0][$y];
   my @k_pos =  $k_mot_pssm[0][$x];

   #compute pearson correlation between the distribution at the two positions

   my $a_avg = 0;
   my $b_avg = 0;
   for (my $i = 0; $i < 4; $i++) {
     $a_avg += $new_pos[0][$i];
     $b_avg += $k_pos[0][$i];
   }
   $a_avg /= 4;
   $b_avg /= 4;


   my $num = 0;
   my $denom_l = 0;
   my $denom_r = 0;
   for (my $i = 0; $i < 4; $i++) {
     my $ai = $new_pos[0][$i];
     my $bi = $k_pos[0][$i];

     $num += (($ai - $a_avg) * ($bi - $b_avg));
     $denom_l += (($ai - $a_avg) * ($ai - $a_avg));
     $denom_r += (($bi - $b_avg) * ($bi - $b_avg));
   }


   $denom_l += .000001;
   $denom_r += .000001;
   my $ans = $num / sqrt($denom_l * $denom_r);

   (($ans <= 1) && ($ans >= -1))
     || die "column match score baaaad: $ans";
   return $ans;
}



sub ReadInPssms
{
  my $motif_file = shift(@_);
  my $motif_weights_ref = shift(@_);
  my $motif_names_ref = shift(@_);
  my $motif_lens_ref = shift(@_);

  #my $xml_parser = new XML::DOM::Parser;
  #my $doc = $xml_parser->parsefile($motif_file);

  # <Motif Consensus="CCTAACGCGTCTTCC" Source="none" Name="RegAdd98" Description="none">
  #  <Weights ZeroWeight="-3.537910">
  #    <Position Num="0" Weights="-0.207627;0.366235;0.004448;-0.163056">
  #    </Position>
  #    <Position Num="1" Weights="-0.586377;0.237183;0.135046;0.214148">
  #    </Position>
  #    <Position Num="2" Weights="-0.380890;0.114692;0.070318;0.195881">

  my $motifs_str = `gxw2tab.pl $motif_file`;
  my @motifs = split(/\n/, $motifs_str);

  #my $motif_nodes = $doc->getElementsByTagName("Motif");
  #my $num_motifs = $motif_nodes->getLength;
  #print "Reading $num_motifs motifs\n";
  #for (my $mot_node_i = 0; $mot_node_i < $num_motifs; $mot_node_i++)
  for (my $i = 0; $i < @motifs; $i++)
  {
      my @row = split(/\t/, $motifs[$i]);
      #my $mot_node = $motif_nodes->item($mot_node_i);

      #my $mot_name = $mot_node->getAttribute("Name");
      my $mot_name = $row[0];
      $$motif_names_ref[$i] = $mot_name;
      #print "$mot_name\n";

      my $num_pos = (@row - 1) / 4;
      $$motif_lens_ref[$i] = $num_pos;

      for (my $p = 0; $p < $num_pos; $p++)
      {
	  $$motif_weights_ref[$i][$p][0] = $row[1 + $p * 4];
	  $$motif_weights_ref[$i][$p][1] = $row[1 + $p * 4 + 1];
	  $$motif_weights_ref[$i][$p][2] = $row[1 + $p * 4 + 2];
	  $$motif_weights_ref[$i][$p][3] = $row[1 + $p * 4 + 3];

	  #print "$$motif_weights_ref[$i][$p][0]\n";
      }
  }

}

sub PrintPssmStructs {
  my $motif_weights_ref = shift(@_);
  my $motif_names_ref = shift(@_);
  my $motif_lens_ref = shift(@_);

  my $num_motifs = @$motif_names_ref;
  for (my $mot_i = 0; $mot_i < $num_motifs; $mot_i++) {

    print "$$motif_names_ref[$mot_i]\n";

    for (my $p = 0; $p < $$motif_lens_ref[$mot_i]; $p++) {
      print "$p:";
      print " $$motif_weights_ref[$mot_i][$p][0]";
      print " $$motif_weights_ref[$mot_i][$p][1]";
      print " $$motif_weights_ref[$mot_i][$p][2]";
      print " $$motif_weights_ref[$mot_i][$p][3]\n";
    }
  }
}

#bootstrap!!!
sub EstimateCutoffs
{
  my $known_weights_ref = shift(@_);
  my $known_lens_ref = shift(@_);
  my $new_weights_ref = shift(@_);
  my $new_lens_ref = shift(@_);

  my @res;

  #first, we shuffle the positions in each of the target motifs,
  #to discover the null distribution of our statistical test
  #at a couple of confidence levels
  my @shuffled_knowns;
  my $num_k_motifs = @$known_lens_ref;

  my @all_matches; #all the results of matching our new motifs to the shuffled blocks

  for (my $l = 1; $l <= $boot_loop; $l++) {

    #shuffle-shuffle
    for (my $k = 0; $k < $num_k_motifs; $k++) {
      my $k_len = $$known_lens_ref[$k];
      for (my $p = 0; $p < $k_len; $p++) {
        my $from_p = int(rand($k_len)); #so what if we get a duplicate
        for (my $i = 0; $i < 4; $i++) {
	  $shuffled_knowns[$k][$p][$i] = $$known_weights_ref[$k][$from_p][$i];
        }
      }
    }

    print STDERR "Computing cutoffs loop $l out of $boot_loop\n";
    my $num_new_motifs = @$new_lens_ref;
    for (my $new_motif_i = 0; $new_motif_i < $num_new_motifs; $new_motif_i++) {
      my $new_mot_len = $$new_lens_ref[$new_motif_i];
      my @new_mot_pssm = $$new_weights_ref[$new_motif_i];

      for (my $k_motif_i = 0; $k_motif_i < $num_k_motifs; $k_motif_i++) {
        my $k_mot_len = $$known_lens_ref[$k_motif_i];
        my @k_mot_pssm = $shuffled_knowns[$k_motif_i];

        my $score = Align(@new_mot_pssm, $new_mot_len, @k_mot_pssm, $k_mot_len, "no");
        if ($score < 0) {
	  die "score can't be less than 0";
        }
        push(@all_matches, $score);
        #print "$score\n";
      }
    #print ".";
    }
  }

  my $num_total = @all_matches;
  my @sorted_scores = sort { $a <=> $b } @all_matches;

  my $twenty_percent_i = int($num_total * (1 - (.2 / $num_k_motifs)));
  print "Confidence .20 cutoff is $sorted_scores[$twenty_percent_i] ($twenty_percent_i score out of $num_total scores) \n";
  my $ten_percent_i = int($num_total * (1 - (.1 / $num_k_motifs)));
  print "Confidence .10 cutoff is $sorted_scores[$ten_percent_i] ($ten_percent_i score out of $num_total scores) \n";
  my $five_percent_i = int($num_total * (1 - (.05 / $num_k_motifs)));
  print "Confidence .05 cutoff is $sorted_scores[$five_percent_i] ($five_percent_i out of $num_total scores)\n";
  my $one_percent_i = int($num_total * (1 - (.01 / $num_k_motifs)));
  print "Confidence .01 cutoff is $sorted_scores[$one_percent_i] ($one_percent_i out of $num_total scores)\n";

  #if ($confidence eq ".20") {
  #  print "using 20%\n";
  #  return $sorted_scores[$twenty_percent_i];
  #} elsif ($confidence eq ".10") {
  #  print "using 10%\n";
  #  return $sorted_scores[$ten_percent_i];
  #} elsif ($confidence eq ".05") {
  #  print "using 5%\n";
  #  return $sorted_scores[$five_percent_i];
  #} elsif ($confidence eq ".01") {
  #  print "using 1%\n";
  #  return $sorted_scores[$one_percent_i];
  #} else {
  #  die "bad percent arg $confidence";
  #}

  $res[$CONFIDENCE_01] = $sorted_scores[$one_percent_i];
  $res[$CONFIDENCE_05] = $sorted_scores[$five_percent_i];
  $res[$CONFIDENCE_10] = $sorted_scores[$ten_percent_i];

  return @res;
}

__DATA__

pssm_align.pl <candidate motifs file> <target motifs file> <confidence>

   confidence = (.10/.05/.01)

   From the paper: "Searching databases of conserved sequence regions
                    by aligning protein multiple-alignments",
                    Shmuel Pietrokovski, NAR 1996

   1. Simulate: permute all the positions in the targets motifs, and align
      each of the candidate pssms to each target motif, and compute the 
      score as the sum of the pearson correlations of each aligned position.
      Get a distribution of scores for alignments. This entire process is
      repeated 5 times. Then you take the percentile according to the 
      specified input confidence level (e.g. 0.05).

   2. Aligns each pssm in the candidates to the targets and compute the Pearson
      correlation between each aligned position. The total score for the match
      between every pair of pssms is the sum of these pearson correlations (no gaps).

   3. Report pairs that are significant with the specified confidence.

   Note: this best works when the length of motifs in the target motifs are similar
         and when the length of motifs in the candidate motifs are similar.

