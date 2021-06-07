#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
   print STDOUT <DATA>;
   exit;
}

my %args = load_args(\@ARGV);
my $peak_shape_init_file = get_arg("shape", "", \%args);
my $arg_output_inferred_centers_of_peaks_file_name = get_arg("ocp", "tmp_ocp.chr", \%args);
my $arg_output_inferred_average_occupancy_file_name = get_arg("oao", "tmp_oao.chr", \%args);
my $arg_output_inferred_peak_fit_file_name = get_arg("opf", "tmp_opf.chr", \%args);
my $arg_output_figure_file_name = get_arg("ofig", "", \%args);
my $arg_output_figure_file_format = get_arg("figmat", "", \%args);
my $arg_binding_start = get_arg("bstart", 1, \%args);
my $arg_binding_length = get_arg("blength", 147, \%args);
my $arg_gamma = get_arg("gamma", 0, \%args);
my $arg_fs_winsize = get_arg("fswin", 0, \%args);
my $arg_fast_fs = get_arg("fast_fs", 0, \%args);
my $arg_use_wa = get_arg("wa", 0, \%args);
my $arg_use_sparsity = get_arg("sparse", 0,\%args);
my $arg_fs_smooth_winsize = get_arg("fssmooth", -1, \%args);
my $arg_data_smooth_winsize = get_arg("datasmooth", 0, \%args);
my $max_gap = get_arg("maxgap", 100, \%args);
my $min_length = get_arg("minl", 200, \%args);
my $max_length = get_arg("maxl", 10000, \%args);
my $min_edge_data = get_arg("edge", 50, \%args);
my $overlap = get_arg("overlap", 100, \%args);
my $debug = get_arg("debug", 0, \%args);

my $signal_file = $ARGV[0];

if ($arg_fs_smooth_winsize==-1){$arg_fs_smooth_winsize=$arg_fs_winsize}
my $use_fs_enhancement=1-$arg_fast_fs;

open(SIGNAL_FILE, $signal_file) or die("Could not open the signal chr file '$signal_file'.\n");

my $r = int(rand(1000000000));


my $chr="";
my $pos=0;
my $segment_counter=0;
my $seg_start="";
my $prev_chr="";
my $prev_pos=0;
my @segment_list;

unlink $arg_output_inferred_average_occupancy_file_name;
unlink $arg_output_inferred_centers_of_peaks_file_name;
unlink $arg_output_inferred_peak_fit_file_name;

# go over signal file and divide into segments
while(<SIGNAL_FILE>){
  chomp;
  ($chr,my $featname,$pos,my $end,my $valname,my $val)=split /\t/;

  if($seg_start eq "" or $chr ne $prev_chr or $pos-$prev_pos+1>$max_gap){
    if ($seg_start ne ""){
      add_segment($prev_chr,$seg_start,$prev_pos);
    }
    $seg_start=$pos;
  }
  $prev_pos=$pos;
  $prev_chr=$chr;
}
add_segment($prev_chr,$seg_start,$prev_pos);

seek(SIGNAL_FILE,0,0);

$pos=-10000000000000000;
$chr="";
$seg_start="";
$prev_chr="";
$prev_pos=$pos;
my @active_positions;

# go over signal file, writing each segment to a file and solving on it

for my $s (0..$#segment_list){
  while((($pos<=$segment_list[$s]{end} and $chr eq $segment_list[$s]{chr}) or $chr lt $segment_list[$s]{chr}) and !eof(SIGNAL_FILE)){
    my $line=<SIGNAL_FILE>;
    chomp $line;
    my @a=split /\t/,$line;
    $chr=$a[0];
    $pos=$a[2];
    my %tmp_pos=("chr"=>$a[0],"pos"=>$a[2],"val"=>$a[5]);
    push @active_positions,\%tmp_pos;
  }
  my @tmp_act;
  open (ARG_DATA_FILE, ">tmp_data_file_$s"."_$r");
  for my $p (0..$#active_positions){
    if ($active_positions[$p]{chr} eq $segment_list[$s]{chr} and $active_positions[$p]{pos}>=$segment_list[$s]{start} and $active_positions[$p]{pos}<=$segment_list[$s]{end}){
      if (!defined $segment_list[$s]{first_position}){
	$segment_list[$s]{first_position}=$active_positions[$p]{pos};
      }
      print ARG_DATA_FILE $active_positions[$p]{pos},"\t",$active_positions[$p]{val},"\n";
    }
    if (($active_positions[$p]{chr} eq $segment_list[$s]{chr} and $active_positions[$p]{pos}>=$segment_list[$s]{start}) or ($active_positions[$p]{chr} gt $segment_list[$s]{chr})){
      push @tmp_act,$active_positions[$p];
    }
  }
  @active_positions=@tmp_act;
  close (ARG_DATA_FILE);
  solve($s);
  unlink "tmp_data_file_$s"."_$r";
}
close(SIGNAL_FILE);



sub add_segment{
  my $chr=shift;
  my $start=shift;
  my $end=shift;

  $start+=$min_edge_data;
  $end-=$min_edge_data;
  my $length=$end-$start+1;

  my $parts=int($length/$max_length)+1;
  if (int($length/$parts)>=$min_length){
    for my $i (1..$parts){
      $segment_list[$segment_counter]{chr}=$chr;
      $segment_list[$segment_counter]{true_start}=$start+($i-1)*int($length/$parts);
      $segment_list[$segment_counter]{true_end}=$start+($i)*int($length/$parts)-1;
      $segment_list[$segment_counter]{start}=$segment_list[$segment_counter]{true_start}-$overlap;
      $segment_list[$segment_counter]{end}=$segment_list[$segment_counter]{true_end}+$overlap;
      $segment_counter++;
    }
  }
}


# solve peak-fitting for segment

sub solve{
  my $seg=shift;

  my $figname="";
  if ($arg_output_figure_file_name ne ""){
    $figname=$arg_output_figure_file_name."_".$segment_list[$seg]{chr}."_".$segment_list[$seg]{first_position};
  }
  my $params = "(\'tmp_data_file_$seg"."_$r\',\'$peak_shape_init_file\',$arg_binding_start,$arg_binding_length,$arg_gamma,$arg_fs_winsize,$arg_data_smooth_winsize,$arg_fs_smooth_winsize,$arg_use_wa,$arg_use_sparsity,$use_fs_enhancement,\'$figname\',\'$arg_output_figure_file_format\',\'tmp_centers_file_$seg"."_$r\',\'tmp_aveocc_file_$seg"."_$r\',\'tmp_fit_file_$seg"."_$r\')";

  my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
  my $mfile = "peak_fitting2";
  my $matlabPath = "matlab";

  my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";

  print STDERR "Calling Matlab with: $command\n";

  my $failed_to_run_matlab = 0;

  my $command_results = system($command);

  while($command_results != 0)
    {
      $command_results = system($command);
      $failed_to_run_matlab = 1;
      sleep(10);
    }

  $failed_to_run_matlab and print STDERR "Failed to run Matlab\n";

  open (IN,"tmp_centers_file_$seg"."_$r");
  open (OUT,">>$arg_output_inferred_centers_of_peaks_file_name");
  my $current_position=$segment_list[$seg]{first_position};
  while(<IN>){
    if($current_position>=$segment_list[$seg]{true_start} and $current_position<=$segment_list[$seg]{true_end}){
      /(\S+)/;
      print OUT $segment_list[$seg]{chr},"\t$seg\t$current_position\t$current_position\tcenters\t$1\n";
    }
    $current_position++;
  }
  close(IN);
  close(OUT);

  open (IN,"tmp_aveocc_file_$seg"."_$r");
  open (OUT,">>$arg_output_inferred_average_occupancy_file_name");
  my $current_position=$segment_list[$seg]{first_position};
  while(<IN>){
    if($current_position>=$segment_list[$seg]{true_start} and $current_position<=$segment_list[$seg]{true_end}){
      /(\S+)/;
      print OUT $segment_list[$seg]{chr},"\t$seg\t$current_position\t$current_position\taveocc\t$1\n";
    }
    $current_position++;
  }
  close(IN);
  close(OUT);

  open (IN,"tmp_fit_file_$seg"."_$r");
  open (OUT,">>$arg_output_inferred_peak_fit_file_name");
  my $current_position=$segment_list[$seg]{first_position};
  while(<IN>){
    if($current_position>=$segment_list[$seg]{true_start} and $current_position<=$segment_list[$seg]{true_end}){
      /(\S+)/;
      print OUT $segment_list[$seg]{chr},"\t$seg\t$current_position\t$current_position\tfit\t$1\n";
    }
    $current_position++;
  }
  close(IN);
  close(OUT);

  unlink "tmp_centers_file_$seg"."_$r";
  unlink "tmp_aveocc_file_$seg"."_$r";
  unlink "tmp_fit_file_$seg"."_$r";
}




__DATA__

Syntax:

    fit_peaks_rlnorm_model.pl <file.chr>

Description:

    A peak fitting algorithm for a location data <file.chr>.

    Given a peak shape, fits a model to the data, assuming the signal is generated by a non-negative
    linear combination of peaks plus Gaussian noise (with fixed variance).

    Solves: min norm(M*X-S,2)^2+gamma*norm(X,1) s.t. X>0
             X
    where S is the signal vector, M a peak shape matrix.

    Assumes <file.chr> has only features that are unique and of size 1bp, and that they
        are sorted by chromosome (lexicographic) and then by start (numeric).


Flags:

    -shape <file>          The peak shape file, in the format: <value1> \n <value2> \n ... \n <valueN> 

    -ofig <str>            The output figure file name (default: no figure).

    -figmat <fm>           The figure file format, where <fm> = 
                           ai/bmp/emf/eps/fig/jpg/m/pbm/pcx/pgm/png/ppm/tif (default: png).

    -ocp <str>             The inferred peak centers output file name (default: tmp_ocp.chr).

    -oao <str>             The inferred average occupancy output file name (default: tmp_oao.chr).

    -opf <str>             The inferred fit output file name (default: tmp_opf.chr)

    -bstart <int>          The start of the binding relative to the peak shape start (default: 1, 
                           i.e. the peak shape starts where the binding starts).

    -blength <int>         The length of the binding relative to the binding start (by '-bstart')
                           (default: 147bp, as for a nucleosome)

    -maxgap <int>          When consecutive locations are distanced more than <int>, break into 
                           independent segments for the peak fitting algorithm (default: 100).

    -minl <int>            Minimum length for a segment to be fitted (default: 200 bp). NOTE: this
                           number is in addition to the edge buffers, i.e. if minl=200 and edge=50
                           then segments shorter than 300 will not be solved.

    -maxl <int>            Maximum length for a segment to be fitted (default: 10000 bp). NOTE: this
                           number is the number of variables in the QP, so it can't be too large.


    -overlap <int>         Length of desired overlap between adjacent segments (default: 100 bp)

    -edge <int>            Number of bps from the edges of each segment that are used for solving
                           but not given in output (default: 50bp)

    -wa                    In feature selection, replaces each nonzero coordinate with a weighted
                           average position (use with fswin>0)

    -gamma <real>          Regularization parameter - use values larger than 0 to obtain sparse solutions (default 0 i.e. no regularization)

    -fswin <int>           Number of bps to take on each side for the "feature selection"
                           sparsity heuristic. 0 means no feature selection. (default: 0)
    -fast_fs               Make "feature selection" fast but less accurate.
    -fssmooth <int>        Number of bps to take on each side for smoothing the "feature selection"
                           (default: use same value as fswin)
    -datasmooth <int>      Number of bps to take on each side for smoothing the data (default: 0)
    -sparse                Take advantage of matrix sparsity (use when peak shape is small)

    -debug                 Show output of matlab session


