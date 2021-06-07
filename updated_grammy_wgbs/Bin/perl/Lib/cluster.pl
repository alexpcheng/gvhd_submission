#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $linkage = get_arg("l", "average", \%args);
my $clustering_type = get_arg("type", "hierarchical", \%args);
my $distance_function = get_arg("d", "euclidean", \%args);
my $kmeans_iterations = get_arg("it", 100, \%args);
my $kmeans_repetitions = get_arg("rep", 10, \%args);
my $distance_normalization = get_arg("dn", 0, \%args);
my $expression = get_arg("expression", 0, \%args);
my $color_scaling = get_arg("cscale", "", \%args);
my $font_size = get_arg("font", 0, \%args);
my $clust_num = get_arg("n", "2", \%args);
my $cut_off = get_arg("c", "", \%args);
my $class_output = get_arg("class", "", \%args);
my $tree_output = get_arg("tree", "", \%args);
my $dendrogram_output = get_arg("dend", "", \%args);
my $plot_output = get_arg("plot", "", \%args);
my $skip = get_arg("skip", "0", \%args);
my $not_scaled = get_arg("not_scaled", "", \%args);
my $header = get_arg ("h", "0", \%args);
my $debug = get_arg ("debug", "", \%args);
my $top = get_arg ("top", "", \%args);
my $clustering_criterion = get_arg ("cr", "inconsistent", \%args);
my $plot_type = get_arg ("plot_type", "all", \%args);
my $wlt_weight = get_arg ("wlt", 1, \%args);
my $tmp_file = "tmp_".int(rand(100000000));
my $tmp_mfile = $tmp_file.".m";
my $tmp_tabfile = $tmp_file.".tab";
my $tmp_headerfile = $tmp_file."_header.tab";

my $output0std = get_arg ("output0std", 0, \%args);
my $tmp_unclustered_headerfile = $tmp_file."_unclustered_header.tab";
my $num_constant_vectors = 0;

my $non_unique_clustering=0;

open (TMP_TAB,">$tmp_tabfile");
open (TMP_HEAD,">$tmp_headerfile");

open (TMP_UNCLUSTERED_HEAD,">$tmp_unclustered_headerfile");

while (my $line = <STDIN>){
  chomp $line;
  my $h;
  if ($skip<1){
    if ($header){
      $line=~/^(\S+)\t(.+)$/;
      $h="$1";
      $line="$2";
    }
    my $tmp_line=$line;
    $tmp_line=~y/\t//d;
    next if ($tmp_line eq "");

    if ( $distance_function eq "correlation" or $distance_function eq "cosine" ) {
      my @line = split(/\t/,$line);
      my $line_std = ArrayRefStd(\@line);
      if ( $line_std == 0 ) {
	if ( $output0std ) {
	  print TMP_UNCLUSTERED_HEAD $h,"\n";
	  $num_constant_vectors++;
	}
	next;
      }
    }

    print TMP_TAB $line,"\n";
    print TMP_HEAD $h,"\n";
  }
  else {
    $skip--;
  }
}
close (TMP_HEAD);
close (TMP_TAB);
close (TMP_UNCLUSTERED_HEAD);

if (!$header) {
  unlink $tmp_headerfile;
  unlink $tmp_unclustered_headerfile;
}


my $clustering_stop_param = "'maxclust',$clust_num";
if ($cut_off ne ""){
  $clustering_stop_param = "'cutoff',$cut_off";
}

my $matlabPath = "matlab";
my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";


my $script = "";
$script .= "path(path,'$matlabDev');\n";
$script .= "A=importdata('$tmp_tabfile');\n";

# clustering

if ($clustering_type eq 'hierarchical'){
  my $dendrogram_header="";
  if ($header){
    $script .= "header=textread('$tmp_headerfile','%s');\n";
    $dendrogram_header=",'labels',header";
  }
  $script .= "B=pdist(A,\@dist_nan,'$distance_function',$distance_normalization);\n";
  $script .= "C=linkage(B,'$linkage');\n";
  if ($tree_output ne ''){
    $script .= "matrix2tab(C,'$tree_output');\n";
  }
  if ($dendrogram_output ne ''){
    if ($dendrogram_output eq '1') {
      $dendrogram_output="hierarchical_clustering_dendrogram_output.ps";
    }
    if ($expression)
    {
    	$script .= "subplot (1,2,2);\n";	
    	$script .= "[H,T,perm]=dendrogram(C,0$dendrogram_header , 'orientation', 'right');\n";
    	if ($font_size) { $script .= "set(gca, 'FontSize', $font_size);\n"; }
	if ($color_scaling ne ""){
	  (my $cscaling_min,my $cscaling_max)=($color_scaling=~/(\S+),(\S+)/);
	  $color_scaling=",[$cscaling_min $cscaling_max]";
	}
    	$script .= "AR=A(perm,:);\n";
	$script .= "colormap(redgreencmap);\n";
    	$script .= "subplot (1,2,1); imagesc(flipud(AR)".$color_scaling.");\n";
	$script .= "colorbar;\n";
    	if ($font_size) { $script .= "set(gca, 'FontSize', $font_size);\n"; }
    	$script .= "print(gcf,'-dpsc','$dendrogram_output');\n";
    }
    else
    {
		$script .= "[H,T,perm]=dendrogram(C,0$dendrogram_header);\n";
		$script .= "print(gcf,'-dpsc','$dendrogram_output');\n";
	}
  }
  if ($clustering_criterion eq 'distance' or $clustering_criterion eq 'inconsistent'){
    $script .= "D=cluster(C,'criterion','$clustering_criterion',$clustering_stop_param);\n";
  }
  if ($clustering_criterion eq 'maxltfront'){
    $script .= "D=cluster_maxltfront(C);\n";
  }
  if ($clustering_criterion eq 'maxwltfront'){
    $script .= "D=cluster_maxwltfront(C,$wlt_weight);\n";
  }
  if ($clustering_criterion eq 'lifetime'){
    $non_unique_clustering=1;
    if ($cut_off ne ""){
      $script .= "D=cluster_lt(C,'lifetime',$cut_off);\n";
    }
    else{
      $script .= "D=cluster_lt(C,'clustnum',$clust_num);\n";
    }
  }
  if ($clustering_criterion eq 'weighted_lifetime'){
    $non_unique_clustering=1;
    if ($cut_off ne ""){
      $script .= "D=cluster_wlt(C,'lifetime',$cut_off,$wlt_weight);\n";
    }
    else{
      $script .= "D=cluster_wlt(C,'clustnum',$clust_num,$wlt_weight);\n";
    }
  }
}

if ($clustering_type eq 'kmeans'){
   $script .= "D=kmeans_clustering(A,$clust_num,$kmeans_iterations,'$distance_function',$distance_normalization,$kmeans_repetitions);\n";
}


# output

if (!$non_unique_clustering){
  $script .= "out=zeros(size(D,2),$clust_num);\nfor i=1:size(D,2)\nif(~isnan(D(i)))\nout(i,D(i))=1;\nend\nend\nD=out;\n";
}
else{
  $script .= "out=D;\n";
}



# in case constant vectors were not clustered (when using correlation or cosine as the distance function)
# and if required, the constant vectors are added back as an aditional cluster:
#
if ( $num_constant_vectors > 0 and $header ) {
  $script .= "[num_clustered_vectors original_num_clusters]=size(out);\n";
  $script .= "out=[out zeros(num_clustered_vectors,1) ; zeros(".$num_constant_vectors.",original_num_clusters) ones(".$num_constant_vectors.",1)];\n";
  system("cat $tmp_unclustered_headerfile >> $tmp_headerfile");
}


if ($class_output ne ''){
  $script .= "matrix2tab(out,'$class_output');\n";
}

# plots
if ($plot_output ne ''){
  my $plot_type_string;
    $plot_type_string = "plot(A(find(D(:,i)==1),:)');\n";
    if ($plot_type eq "mean"){
      $plot_type_string = "[ax,h1,h2]=plotyy(nanmean(d,1), nanstd(d,0,1),sum(~isnan(d),1)./size(d,1),zeros(1,size(d,2)),'errorbar');\n";
    }
  elsif ($plot_type eq "median"){
    $plot_type_string = "[ax,h1,h2]=plotyy(nanmedian(d,1), nanstd(d,0,1),sum(~isnan(d),1)./size(d,1),zeros(1,size(d,2)),'errorbar');\n";
  }
  $script .= "figure();\n";
  $script .= "n=[];\n";
  if ($top eq ""){
      $script .= "display_clusters = 1:size(D,2);\n";
  }
  else{
    $script .= "for i=1:size(D,2)\n";
    $script .= "  n(i)=sum(D(:,1));\n";
    $script .= "end\n";
    $script .= "[y,i]=sort(n,2,'descend');\n";
    $script .= "display_clusters=i(1:$top);\n";
  }
  $script .= "t=ceil(sqrt(length(display_clusters)));\n";
  $script .= "j=0;\n";
  $script .= "for i = display_clusters\n";
  $script .= "  j=j+1;\n";
  $script .= "  d=A(find(D(:,i)==1),:);\n";
  $script .= "  subplot(t,t,j);\n";
  $script .= "  hold on;\n";
  $script .= "  axis([1 size(A,2) min(min(A)) max(max(A))]);\n";
  $script .= "  $plot_type_string";
  $script .= "  title(['c = ' num2str(i) ', n = ' num2str(size(d,1))]);\n";
  if ($plot_type ne "all"){
    $script .= "  set(ax,'xlim',[1 size(A,2)],'ytickmode','auto','xtickmode','auto');\n";
    if ($not_scaled eq "") { $script .= "  set(ax(1),'ylim',[min(min(A)) max(max(A))]);\n"; }
    $script .= "  set(ax(2),'ylim',[0 1],'ycolor','black');\n";
    $script .= "  h1c=get(h1,'children');\n";
    $script .= "  h2c=get(h2,'children');\n";
    $script .= "  set(h2c(1),'color','black','linestyle','-.');\n";
    $script .= "  set(h2c(2),'visible','off');\n";
    $script .= "  set(h1c(1),'linewidth',3,'color','red');\n";
    $script .= "  set(h1c(2),'linestyle','none','marker','.');\n";
  }
  $script .= "end;\n";
  $script .= "print(gcf,'-dpsc','$plot_output');\n";
}


open (MFILE,">$tmp_mfile");
print MFILE $script;
close (MFILE);

my $debug_output = `$matlabPath -nodesktop -nojvm -nodisplay -nosplash -r \"$tmp_file; exit;\"`;

my $run="modify_column.pl -A -p 1 < $class_output | paste $tmp_headerfile - > $tmp_file"."_classes" ;
`$run`;
$run="cat $tmp_file"."_classes | transpose.pl | lin.pl -0 | transpose.pl > $class_output";
`$run`;

if ($debug ne ""){
  print "$debug_output\n";
}

if ($debug eq ""){
  unlink ("$tmp_mfile");
  unlink ("$tmp_tabfile");
  unlink ("$tmp_headerfile");
  unlink ("$tmp_file"."_classes");
  unlink ("$tmp_unclustered_headerfile");
}


__DATA__

cluster.pl

clusters the row vectors of the standard input using matlab clustering (hierarchical or kmeans clustering).
vectors with missing values are accepted (but see note on distance function). for more information
on clustering option see matlab help on these functions. empty vectors will be ignored by the script.


 general options:

  -h:               file contains a header column (will be used for dendrogram labels).
  -skip <num>:      rows to skip at beginning of file. default=0
  -debug:           print matlab session output to standard output for debugging. cancels deletion of tmp files
                    that are created by the script.

 general clustering options:

  -type <string>:   kmeans/hierarchical (default=hierarchical)
  -d <string>:      distance function (euclidean/cosine/correlation/hamming/any other matlab pdist() metric).
                    NOTES: (1) pdist distance functions have been rewritten to deal with missing values. to
                    calculate the distance between vectors a and b, only coordinates that are not missing
                    values in either a or b are used for calculation (effectively this shortens a and b).
                    (2) if cosine or correlation are used, vectors with zero standard deviation are removed
                    from data.
                    default=euclidean.

  -dn:              normalize distance metric. "normalized" in this context means normalization by the
                    number of non-empty pairs. some distance functions that are not "normalized" may cause
                    distortion of the vector space when using vectors of different lengths.

  -n <num>:         number of clusters

  -output0std:      In case distance metric is cosine or correlation, regard all constant vectors as a cluster
                    (on top of the n clusters), and do not simply remove them.
                    This is relevant only if the -h option is set.

 kmeans options:

  -it <num>:        number of iterations (default=100)
  -rep <num>:       number of repetitions (default=10)

 hierarchical clustering options:

  -l <string>:      linkage method (single/complete/average/weighted/centroid/median/ward).
                    default=average.
  -cr <string>:     criterion for forming clusters (distance/inconsistent/maxltfront/maxwltfront/lifetime/weighted_lifetime). default=inconsistent.
  -c <num>:         cutoff value
  -wlt <num>:       weighted lifetime parameter for importance of cluster size (default=1).
                    weighted_lifetime(c) = lifetime(c) * size(c) ^ <num>

 output options:

  -tree <string>:   filename for output tree.
  -class <string>:  filename for output cluster assignments.
  -dend <string>:   filename for output dendrogram figure (ps). only for hierarchical clustering.
  -expression:      also include a heatmap of the expression data (works only with -dend).
  -cscale <min>,<max>: scale colors between <min> and <max> (works only with -expression).
  -font <num>:      change axis fontsize (default: 12).
  
  -plot <string>:   filename for separate plots of each cluster (ps).
  -plot_type <str>: all/mean/median. all plots all instances. mean/median plots the mean/median and std dev
                    of each cluster. default=all.

  -not_scaled:      dont force plots to be on same scale.
  -top <num>:       show only <num> largest clusters.

  -debug:           debug mode.

