#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
use Math::Trig;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

my $RNAplot_EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs/";
my $BG_FILE         = "$ENV{GENIE_HOME}/Runs/Folding/Rabani06/Model/BG_model/bg.tab";

my $DOT = ".";
my $OPEN_BRACKET = "(";
my $CLOSE_BRACKET = ")";
my $SEQUENCE = "@";

my @SINGLE_NUC = ("A","C","G","U");
my @PAIR_NUC = ("AU","UA","GC","CG","GU","UG");

# Graph display parameters
my $BIF_X_SHIFT = 70;

# Most probable structure parameters
my $END_CIRCLE_RADIUS = 3;
my $OUTLINE_COLOR = 0.7;
my $PAIR_WIDTH = 2.5;
my $PAIR_SCALE_FACTOR = 1/(1-0.2); # grey level = 0 (black) for p=1, grey level = 1 (white) for p=0.2 or less
my $SINGLE_RADIUS = 2;
my $SEQ_COLOR_FACTOR = 0.2; # color range between Factor to 1
my $SEQ_COLOR_BLUE = 0.3;   # increase blue intensity by



# =============================================================================
# Main part
# =============================================================================

if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my $file = $ARGV[0];
my %args = load_args(\@ARGV);
my $output = get_arg("output", "model_cons", \%args);
my $format = get_arg("format", "", \%args);
my $seq_threshold = get_arg("seq", 0.5, \%args);
my $plot_graph = get_arg("graph", 0, \%args);






# --------------------------------------------------------
# Plot the model as a graph
# --------------------------------------------------------
if ($plot_graph) {

  # reading graph structure
  my $file_ref;
  if (length($file) < 1 or $file =~ /^-/) {
    $file_ref = \*STDIN;
  }
  else {
    open(INPUT, "$file") or die "Cannot read input file $file\n";
    $file_ref = \*INPUT;
  }

  my @state_children;
  my @state_type;
  my @state_probs;
  my @output_probs;
  my $origin;

  while (<$file_ref>) {
    chomp $_;
    my ($type, $id, $pid) = split("\t", $_);
    $state_type[$id] = $type;
    $state_children[$id] = [];

    if ($pid >= 0) {
      my $ref = $state_children[$pid];
      push(@$ref, $id);

      my $parent_prob_ref = $state_probs[$pid];
      my @child_prob; # transition probabilities
      for (my $i = 0; $i < scalar(@$parent_prob_ref); $i++) {
	my $line = <$file_ref>;
	my @probs = split("\t", $line);
	
	for (my $j = 0; $j < scalar(@probs); $j++) {
	  $child_prob[$j] = $child_prob[$j] + $probs[$j]*$$parent_prob_ref[$i];
	}
      }
      $state_probs[$id] = \@child_prob;

      if ($type eq "C") {
	my @child_output; # emission probabilities

	my $line = <$file_ref>; # pair
	my @probs = split("\t", $line);
	for (my $j = 4; $j < scalar(@PAIR_NUC)+4; $j++) {
	  push(@child_output, $probs[$j]*$child_prob[0]);
	}

	my $line = <$file_ref>; # left
	my @probs = split("\t", $line);
	for (my $j = 0; $j < scalar(@SINGLE_NUC); $j++) {
	  push(@child_output, $probs[$j]*$child_prob[1]);
	}

	my $line = <$file_ref>; # right
	my @probs = split("\t", $line);
	for (my $j = 0; $j < scalar(@SINGLE_NUC); $j++) {
	  push(@child_output, $probs[$j]*$child_prob[2]);
	}

	my $line = <$file_ref>; # Delete
	my $line = <$file_ref>; # Insert

	$output_probs[$id] = \@child_output;
      }
    }
    else {
      my $line = <$file_ref>;
      my @probs = split("\t", $line);
      $state_probs[$id] = \@probs;
      $origin = $id;
    }
  }

  my @bif_count = count_bif(\@state_children, $origin);
  print STDERR "BIFURCATION_COUNT: ";
  foreach my $k (@bif_count) {
    print STDERR "$k\t";
  }
  print STDERR "\n";

  # creating output postscript file
  open(OUTPUT, ">$output.ps") or die "Cannot open ps file $output.ps \n";
  print_header(\*OUTPUT);

  my @stack = ();
  my $node = $origin;

  my $trx = 0;
  my $try = 0;
  my $max_try = 0;

  my $bp = 0;
  while (defined $node) {

    my $children_ref = $state_children[$node];
    my $start_try = 0;
    while (scalar(@$children_ref) > 0) {
      my $type = $state_type[$node];
      print STDERR "$node\t$type\n";

      if ($type eq "S") { # start
	$try += print_start_node(\*OUTPUT);
      }
      elsif ($type eq "B") { # bifurcation
	$try += print_bifurcation_node(-1*$bif_count[$bp]*$BIF_X_SHIFT, \*OUTPUT);
	$trx = 2*$bif_count[$bp]*$BIF_X_SHIFT;
	$bp++;

	push(@stack, $$children_ref[1]);
	push(@stack, $try);
	$start_try += $try;
	$try = 0;
	push(@stack, $trx);
	$trx = 0;
      }
      elsif ($type eq "C") { # Emitting state
	my $state_output_ref = $output_probs[$node];
	$try += print_output_node($state_output_ref, $seq_threshold, \*OUTPUT);
      }
      else {
	print STDERR "Type $type does not exists\n";
	exit;
      }

      $node = $$children_ref[0];
      $children_ref = $state_children[$node];
    }

    # end node
    $try += print_end_node(\*OUTPUT);
    $bp++;

    # move to the right side of the last bifurcation
    if (scalar(@stack) > 0) {
      $trx = pop(@stack)-0.5*$trx+20;
      $try = $try + 20;
      print OUTPUT "$trx $try translate\n";
      print STDERR "$trx $try translate\n";
    }
    $start_try += $try;
    $try = pop(@stack);
    $node = pop(@stack);

    if ($start_try > $max_try) {
      $max_try = $start_try;
    }
  }

  print OUTPUT "showpage\n";
  close(OUTPUT);

  # scale the ps file
  my $scale = 800/$max_try;
  system("cat $output.ps | sed 's/@/$scale/g' > t; mv t $output.ps;");
}



# --------------------------------------------------------
# Plot most probable structure
# --------------------------------------------------------
else {

  # calculating most probable structure
  if (length($file) < 1 or $file =~ /^-/) {
    open(MODEL, ">tmp_model_file_$$") or die "cannot open tmp_model_file_$$\n";
    while (<STDIN>) {
      print MODEL $_;
    }
    close(MODEL);
    $file = "tmp_model_file_$$";
  }
  my $rc = print_model($file, "tmp_output_$$.tab");

  if ($rc != 0) {
    print STDERR "cannot print model \n";
    exit(1);
  }
  open(CONS, "tmp_output_$$.tab") or die "cannot open tmp_output_$$.tab\n";

  my $left;
  my $right;
  my @right_arr = ($right);
  my $left_seq;
  my $right_seq;
  my @right_seq_arr = ($right);

  my $left_str = "/seq_color [";
  my $right_str;
  my @right_str_arr = ($right_str);
  my $left_prob = "/single_probs [";
  my $right_prob;
  my @right_prob_arr = ($right_prob);
  my $pair_probs = "/pair_probs [";

  my $r = 0;
  while (<CONS>) {
    chomp;
    my ($id, $pid, $type, $value, $prob, $seq, $seq_prob) = split("\t");
    print STDERR "$_\n";

    if ($type eq "E") { # End
      $left = $left.$right;
      $left_seq = $left_seq.$right_seq;
      $left_str = $left_str.$right_str;
      $left_prob = $left_prob.$right_prob;

      $r--;
      if ($r >= 0) {
	$right = $right_arr[$r];
	$right_seq = $right_seq_arr[$r];
	$right_str = $right_str_arr[$r];
	$right_prob = $right_prob_arr[$r];
      }
    }
    elsif ($type eq "B") { # Bifurcation
      $right_arr[$r] = $right;
      $right = "";
      $right_seq_arr[$r] = $right_seq;
      $right_seq = "";
      $right_str_arr[$r] = $right_str;
      $right_str = "";
      $right_prob_arr[$r] = $right_prob;
      $right_prob = "";
      $r++;
    }
    elsif ($type eq "C" and $value eq "P") { # Pair
      $left = $left.$OPEN_BRACKET;
      $right = $CLOSE_BRACKET.$right;
      $pair_probs = $pair_probs." $prob";

      if ($seq_prob >= $seq_threshold) {
	$left_seq = $left_seq.substr($seq, 0, 1);
	$right_seq = substr($seq, 1, 1).$right_seq;
	$left_str = $left_str." $seq_prob";
	$right_str = " $seq_prob".$right_str;
      }
      else {
	$left_seq = $left_seq.$SEQUENCE;
	$right_seq = $SEQUENCE.$right_seq;
	$left_str = $left_str." 1";
	$right_str = " 1".$right_str;
      }
    }
    elsif ($type eq "C" and $value eq "L") { # Left
      $left = $left.$DOT;
      $left_prob = $left_prob." $prob";

      if ($seq_prob >= $seq_threshold) {
	$left_seq = $left_seq.$seq;
	$left_str = $left_str." $seq_prob";
      }
      else {
	$left_seq = $left_seq.$SEQUENCE;
	$left_str = $left_str." 1";
      }
    }
    elsif ($type eq "C" and $value eq "R") { # Right
      $right = $DOT.$right;
      $right_prob = " $prob".$right_prob;

      if ($seq_prob >= $seq_threshold) {
	$right_seq = $seq.$right_seq;
	$right_str = " $seq_prob".$right_str;
      }
      else {
	$right_seq = $SEQUENCE.$right_seq;
	$right_str = " 1".$right_str;
      }
    }
  }
  close(CONS);

  # plot
  my $fold = $left;
  my $sequence = $left_seq;
  my $prob_str = $left_str."] def";
  my $single_probs = $left_prob."] def";
  $pair_probs = $pair_probs."] def";

  my $singles = "/singles [";
  for (my $i = 0; $i < length($fold); $i++) {
    my $s = substr($fold, $i, 1);
    if ($s eq $DOT) {
      $singles = $singles." $i";
    }
  }
  $singles = $singles."] def";

  print STDERR "$sequence\t$fold\n";
  open (SEQFILE, ">tmp_seqfile_$$") or die ("Could not open tmp_seqfile_$$.\n");
  print SEQFILE "> model\n$sequence\n$fold\n";
  close (SEQFILE);
  my $prog_result = `$RNAplot_EXE_DIR/RNAplot < tmp_seqfile_$$`;

  my @pairs;
  my @x;
  my @y;
  my $pair = 0;
  my $coor = 0;
  open(PSIN, "model_ss.ps") or die "Cannot open model_ss.ps\n";
  open(PSOUT, ">$output.ps") or die "Cannot open $output.ps\n";
  while (<PSIN>) {
    my $line = $_;

    # header
    if (($line =~ m/^%%Pages:/g) or ($line =~ m/^%%Creator:/g) or ($line =~ m/^%%BoundingBox:/g) or
	($line =~ m/^\w*%[\s\w]/g) or ($line =~ m/seqcolor/g) or ($line =~ m/paircolor/g)){
      $line = "";
    }

    # draw outline
    $line =~ s/coor 0 get aload pop 0.8 0 360 arc/coor 0 get aload pop $END_CIRCLE_RADIUS 0 360 arc/g;
    $line =~ s/outlinecolor \{0\.2 setgray\}/outlinecolor \{$OUTLINE_COLOR setgray\}/g;

    # draw pairs
    $line =~ s/paircolor\n//g;
    $line =~ s/0.7 setlinewidth\n/$PAIR_WIDTH setlinewidth\n/g;
    $line =~ s/pairs \{aload pop/0\n  pairs \{\n  exch dup pair_probs exch get 1 exch sub $PAIR_SCALE_FACTOR mul setgray exch aload pop/g;
    $line =~ s/coor exch 1 sub get aload pop lineto/coor exch 1 sub get aload pop lineto\n    stroke\n    1 add/g;

    # draw singles
    if ($line =~ m/\/drawbases \{/g) {
      $line = "\/drawsingles \{\n".
	"  0\n".
	"  singles \{\n".
	"   exch dup single_probs exch get 1 exch sub setgray exch\n".
	"   dup coor exch get aload pop moveto\n".
	"   coor exch get aload pop $SINGLE_RADIUS 0 360 arc\n".
	"   fill\n".
	"   1 add\n".
	" \} forall\n".
	"\} bind def\n".
	"\/drawscale \{\n".
	"  20 80 translate\n".
	"  \/values \[0 1 2 3 4 5 6 7 8 9 10\] def\n".
        "  values \{\n".
        "  dup 10 div 1 exch sub setgray 10 mul 0 moveto 10 0 rlineto 0 30 rlineto -10 0 rlineto closepath fill\n".
        "\} forall\n".
	"  0 -30 translate\n".
        "  values \{\n".
        "  dup 10 div dup $seq_threshold ge {\n".
	"    $seq_threshold sub 1 $seq_threshold sub div dup 1 exch sub 0 setrgbcolor 10 mul 0 moveto 10 0 rlineto 0 30 rlineto -10 0 rlineto closepath fill\n".
	"  } if\n".
        "\} forall\n".
	"\/Palaltino-Roman findfont 8 scalefont setfont \n".
	"0 setgray 0 0 moveto 110 0 lineto closepath stroke\n".
	"0 0 moveto 0 -5 lineto closepath stroke 0 -15 moveto (0) show\n".
	"55 0 moveto 55 -5 lineto closepath stroke 50 -15 moveto (0.5) show\n".
	"110 0 moveto 110 -5 lineto closepath stroke 110 -15 moveto (1) show\n".
	"120 10 moveto (sequence) show 120 40 moveto (structure) show\n".
        "\} bind def\n".
	"\/drawbases \{\n";
    }

    # draw bases
    $line =~ s/dup sequence exch 1 getinterval cshow/dup seq_coor exch get aload pop rmoveto\n dup seq_color exch get $seq_threshold sub 1 $seq_threshold sub div dup 1 exch sub 0 setrgbcolor dup sequence exch 1 getinterval cshow/g;

    # variables definition
    if ($pair and $line =~ m/\[(\d+) (\d+)\]/g) {
      $pairs[$1] = $2;
      $pairs[$2] = $1;
    }
    if ($coor and $line =~ m/\[(-?\d+\.?\d+?) (-?\d+\.?\d+?)\]/g) {
      push(@x,$1);
      push(@y,$2);
    }

    if ($line =~ m/\/coor \[/g) {
      $coor = 1;
    }
    elsif ($line =~ m/\/pairs \[/g) {
      $pair = 1;
    }
    elsif ($line =~ m/\] def/g) {
      $coor = 0;
      $pair = 0;
    }

    if ($line =~ m/^init\n/g) {
      my $seq_coor = "\/seq_coor [\n";

      unshift(@x, $x[0]-1);
      push(@x,$x[scalar(@x)-1]-5);
      unshift(@y, $y[0]-1);
      push(@y,$y[scalar(@y)-1]-5);
      for (my $i = 1; $i < scalar(@x)-1; $i++) {
	my $m = $x[$i-1] == $x[$i+1] ? -100000 : ($y[$i-1]-$y[$i+1])/($x[$i-1]-$x[$i+1]); # slope = dy/dx
	my $n = $y[$i-1] - $x[$i-1]*$m;
	my $alpha = atan($m); # angle with x axis (rad)

	my $sign = $y[$i] - ($m*$x[$i]+$n);
	if ($sign == 0) {
	  my $p = $pairs[$i];
	  $sign = $y[$p] < $y[$i] ? 1 : -1;
	}
	elsif ($pairs[$i] != 0) {
	  my $p = $pairs[$i];
	  my $d = $y[$p] != $y[$i] ? $y[$p] - $y[$i] : $x[$p] - $x[$i];
	  $sign = $d < 0 ? 1 : -1;

	  my $cm = $y[$p] == $y[$i] ? -100000 : -1*($x[$p] - $x[$i])/($y[$p] - $y[$i]);
	  if ((get_sign($cm) != get_sign($m)) and (abs($alpha) > 3.14/4)) { # alpha > 45
	    #print STDERR "$i: $cm  $m\n";
	    $sign = -1*$sign;
	  }
	}
	else {
	  $sign = $sign/abs($sign);
	}

	my $sx = -7*sin($alpha)*$sign;
	my $sy = 7*cos($alpha)*$sign;
	$seq_coor = $seq_coor."[$sx $sy]\n";

	my $ta = $alpha*180/3.14;
	#print STDERR "$i: ($x[$i],$y[$i]),$m,$n\t$ta\t$sign\t$sx\t$sy\n";
      }
      $seq_coor = $seq_coor."\n] def";

      $line = "$pair_probs\n$singles\n$single_probs\n$prob_str\n$seq_coor\n\ninit\n";
    }
    $line =~ s/$SEQUENCE/ /g;

    # execution
    $line =~ s/init\n/gsave\ninit/g;
    $line =~ s/drawpairs\n/drawpairs\ndrawsingles\n/g;
    $line =~ s/showpage\n/grestore\ndrawscale\nshowpage\n/g;

    print PSOUT $line;
  }
  close(PSOUT);
  close(PSIN);

  system ("/bin/rm tmp_seqfile_$$ tmp_output_$$.tab model_ss.ps tmp_model_file_$$");
}

if ($format) {
  system ("convert $output.ps $output.$format; /bin/rm $output.ps;");
}
print STDERR "Done.\n";




# =============================================================================
# Subroutines
# =============================================================================

sub get_sign($) {
  my ($num) = @_;

  if ($num > 0) {
    return 1;
  }
  elsif ($num < 0) {
    return -1;
  }
  else {
    return 0;
  }
}

# ------------------------------------------------------------------------
# print the model consensus probabilities
#  print_model(input file name, output file name)
# ------------------------------------------------------------------------
sub print_model($$) {
  my ($file, $output) = @_;

  # create xml file
  open(XML, ">tmp_xml_$$.map") or die "cannot create tmp_xml_$$.map\n";

  print XML "<?xml version=\"1.0\"?>\n";
  print XML " <MAP>\n";
  print XML "  <RunVec>\n";
  print XML "   <Run Name=\"RNAmodel\" Logger=\"logger.log\">\n";
  print XML "    <Step Type=\"LoadRnaBgParams\"\n";
  print XML "          Name=\"LoadRnaBgParams\"\n";
  print XML "          RnaBgModelName=\"bg_model\"\n";
  print XML "          File=\"$BG_FILE\">\n";
  print XML "    </Step>\n";
  print XML "    <Step Type=\"LoadRnaModelParams\"\n";
  print XML "          Name=\"LoadRnaModelParams\"\n";
  print XML "          RnaModelName=\"model\"\n";
  print XML "          File=\"$file\">\n";
  print XML "    </Step>\n";
  print XML "    <Step Type=\"PrintRnaModel\"\n";
  print XML "          Name=\"PrintModel\"\n";
  print XML "          RnaModelName=\"model\"\n";
  print XML "          RnaBgModelName=\"bg_model\"\n";
  print XML "          PrintFullStructure=\"true\"\n"; #OutputType=\"FullMostProbableStructure\"\n";
  print XML "          OutputFile=\"$output\">\n";
  print XML "    </Step>\n";
  print XML "   </Run>\n";
  print XML "  </RunVec>\n";
  print XML " </MAP>\n";

  close(XML);

  # map learn
  &RunGenie("", "", "tmp_xml_$$.map", "", "", "");
  my $rc = `rm logger.log;`;
  return($?);
}

# ------------------------------------------------------------------------
# count_bif(child_array_ref, origin)
# ------------------------------------------------------------------------
sub count_bif($$) {
  my ($child_array_ref, $origin) = @_;

  my $ref = $$child_array_ref[$origin];
  while (scalar(@$ref) == 1) {
    $ref =  $$child_array_ref[$$ref[0]];
  }

  if (scalar(@$ref) == 0) { # no bif
    return (0);
  }

  my @count_left = count_bif($child_array_ref, $$ref[0]);
  my @count_right = count_bif($child_array_ref, $$ref[1]);
  my $count = $count_left[0] + $count_right[0] + 1;

  return ($count, @count_left, @count_right);
}

# ------------------------------------------------------------------------
# print_header(file_ref)
# ------------------------------------------------------------------------
sub print_header($) {
  my ($file_ref) = @_;

  print $file_ref "%!ps\n\n";
  print $file_ref "% --------------------------------------------------------------\n";
  print $file_ref "% Procedures\n";
  print $file_ref "% --------------------------------------------------------------\n";
  print $file_ref "/square {\n 0 setgray 1 setlinewidth\n 0 0 moveto 0 30 lineto 30 30 lineto 30 0 lineto closepath stroke\n} def\n\n";
  print $file_ref "/rectangle {\n 0 setgray 1 setlinewidth\n 0 0 moveto 0 100 lineto 30 100 lineto 30 0 lineto closepath stroke\n} def\n\n";
  print $file_ref "/arrow {\n 0 setgray 1 setlinewidth\n 0 0 moveto 0 -10 lineto closepath stroke\n -5 -10 moveto 5 -10 lineto 0 -20 lineto closepath fill\n} def\n\n";
  print $file_ref "/split_arrow {\n 0 setgray 1 setlinewidth\n 0 0 moveto dup 0 exch lineto closepath stroke\n dup -5 exch moveto dup 5 exch lineto -20 add 0 exch lineto closepath fill\n } def\n\n";
  print $file_ref "/DrawLeftLetter {\n gsave -25 0 rmoveto 0.8 0.2 0.2 setrgbcolor scale show grestore\n} def\n\n";
  print $file_ref "/DrawRightLetter {\n gsave 30 0 rmoveto 0.2 0.2 0.8 setrgbcolor scale show grestore\n} def\n\n";
  print $file_ref "/DrawPair {\n gsave 0.3 0.8 0.3 setrgbcolor scale -25 0 rmoveto show 30 0 rmoveto show -26 10 rmoveto -22 0 rlineto 10 setlinewidth stroke grestore \n} def\n\n";
  print $file_ref "% --------------------------------------------------------------\n";
  print $file_ref "% Main\n";
  print $file_ref "% --------------------------------------------------------------\n";
  print $file_ref "@ @ scale 300 @ div 830 @ div translate\n";
  print $file_ref "/Palatino-Bold findfont 30 scalefont setfont\n\n";
}


# ------------------------------------------------------------------------
# print_start_node(file_ref)
# ------------------------------------------------------------------------
sub print_start_node($) {
  my ($file_ref) = @_;
  print $file_ref "-15 -50 translate square 5 5 moveto (S) show 15 0 translate arrow\n";
  return(30);
}

# ------------------------------------------------------------------------
# print_end_node(file_ref)
# ------------------------------------------------------------------------
sub print_end_node($) {
  my ($file_ref) = @_;
  print $file_ref "-15 -50 translate square 5 5 moveto (E) show\n";
  return(50);
}


# ------------------------------------------------------------------------
# print_bifurcation_node(file_ref)
# ------------------------------------------------------------------------
sub print_bifurcation_node($$) {
  my ($width, $file_ref) = @_;
  my $sign = $width/abs($width);
  my $deg = 80;

  my $y = $sign*abs($width/sin($deg)-20);
  my $height = $sign*abs($width)*cos($deg)/sin($deg);

  print $file_ref "-15 -50 translate square 5 5 moveto (B) show\n";
  print $file_ref "15 0 translate\n";
  print $file_ref "gsave $deg rotate $y split_arrow grestore\n";
  print $file_ref "gsave -$deg rotate $y split_arrow grestore\n";
  print $file_ref "$width $height translate\n";
  return(40);
}


# ------------------------------------------------------------------------
# print_output_node(state_probs_ref, state_output_ref, file_ref)
# ------------------------------------------------------------------------
sub print_output_node($$$) {
  my ($state_output_ref, $min_show, $file_ref) = @_;

  my $sum = 0;
  for (my $i = 0; $i < scalar(@$state_output_ref); $i++) {
    $sum = $sum + $$state_output_ref[$i];
  }

  if ($sum == 0) {
    print $file_ref "-15 -120 translate rectangle 15 0 translate arrow\n";
    return;
  }

  print $file_ref "-15 -120 translate rectangle\n";
  my $p = 0;
  my $nval = scalar(@PAIR_NUC) + 2*scalar(@SINGLE_NUC);

  # Right
  for (my $i = 0; $i < scalar(@SINGLE_NUC); $i++) {
    my $prob = $$state_output_ref[scalar(@PAIR_NUC) + scalar(@SINGLE_NUC) + $i];
    if ($prob >= $min_show) {
      my $pt = $prob/$sum * 100/20;
      print $file_ref "0 $p moveto ($SINGLE_NUC[$i]) 1 $pt DrawRightLetter\n";
      $p = $p + 20*$pt;
    }
  }

  # Left
  for (my $i = 0; $i < scalar(@SINGLE_NUC); $i++) {
    my $prob = $$state_output_ref[scalar(@PAIR_NUC) + $i];
    if ($prob >= $min_show) {
      my $pt = $prob/$sum * 100/20;
      print $file_ref "0 $p moveto ($SINGLE_NUC[$i]) 1 $pt DrawLeftLetter\n";
      $p = $p + 20*$pt;
    }
  }

  # Pair
  for (my $i = 0; $i < scalar(@PAIR_NUC); $i++) {
    my $prob = $$state_output_ref[$i];
    if ($prob >= $min_show) {
      my $left_n = substr($PAIR_NUC[$i], 0, 1);
      my $right_n = substr($PAIR_NUC[$i], 1, 1);
      my $pt = $prob/$sum * 100/20;
      print $file_ref "0 $p moveto ($right_n) ($left_n) 1 $pt DrawPair\n";
      $p = $p + 20*$pt;
    }
  }

  print $file_ref "15 0 translate arrow\n";
  return(120);
}



# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAmodel_plot.pl <CM file> [options]

RNAmodel_plot.pl reads covariance model file (produced by RNAmotif_finder.pl) and produces
a drawing of the most probable structure according to the model, including some sequence
features of this structure.

OPTIONS
  -output <string>       Output image files are named <string> (Default = model_cons)
  -format <name>         Create the ouptut in the given format (e.g. png, bmp, gif, jpg, tiff).
                         Uses "convert" (Default = ps).
  -seq <num>             Print the sequence only if the prob >= <num> (Default = 0.5).
  -graph                 Plot the model graph structure, including base probabilities in each
                         position of the model.
