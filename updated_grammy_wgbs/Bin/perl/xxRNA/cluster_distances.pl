#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";


my $MATLAB_DEV = "$ENV{DEVELOP_HOME}/Matlab";

# =============================================================================
# Main part
# =============================================================================
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file_name = $ARGV[0];
if (length($file_name) < 1 or $file_name =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  shift(@ARGV);
  open(FILE, "../".$file_name) or die("Could not open $file_name.\n");
  $file_ref = \*FILE;
}


my %args = load_args(\@ARGV);
my $debug = get_arg ("debug", 0, \%args);

my $linkage = get_arg("l", "complete", \%args);
my $lifetime = get_arg("lt", 0, \%args);

my $clusters_filtering = get_arg ("c", "", \%args);
my $class_output = get_arg("co", "", \%args);
my $clust_num = get_arg("cn", "", \%args);
my $cut_off = get_arg("cf", "", \%args);

my $dendrogram_output = get_arg("d", "", \%args);
my $expression = get_arg("dh", 0, \%args);
my $font_size = get_arg("df", 0, \%args);

my $plot_output = get_arg("p", "", \%args);
my $plot_type = get_arg ("pt", "all", \%args);
my $top = get_arg ("pn", "", \%args);




# ----------
# read input distances, and create distances file
# ----------
print STDERR "read input distances, and create distances file ... ";

my %ids;
my %distances;
while (<STDIN>) {
  chomp $_;
  my ($id1, $id2, $dist) = split("\t", $_);
  $ids{$id1} = 1;
  $ids{$id2} = 1;
  my @sid = sort ($id1, $id2);
  $distances{"$sid[0]_$sid[1]"} = $dist;
}

my $tmp_tabfile = "tmp_$$".".tab";
my $tmp_headerfile = "tmp_$$"."_header.tab";
open(TMP_TAB, ">$tmp_tabfile") or die "Cannot open $tmp_tabfile\n";
open(TMP_HEAD, ">$tmp_headerfile") or die "Cannot open $tmp_headerfile\n";
my @ids_list = keys %ids;
for (my $i = 0; $i < scalar(@ids_list); $i++) {
  my $id1 = $ids_list[$i];
  print TMP_HEAD "$id1\n";

  for (my $j = $i+1; $j < scalar(@ids_list); $j++) {
    my $id2 = $ids_list[$j];
    my @sid = sort ($id1, $id2);

    my $k = "$sid[0]_$sid[1]";
    if (defined $distances{$k}) {
      print TMP_TAB "$distances{$k}\n";
    }
    else {
      print TMP_TAB "0\n";
    }
  }
}
close(TMP_HEAD);
close(TMP_TAB);

print STDERR "Done\n";



# ----------
# create matlab script
# ----------
print STDERR "create matlab script ... ";

# clustering
my $tree_output = "tmp_$$"."_tree.tab";
my $script = "path(path,'$MATLAB_DEV');\n";
$script .= "B=load('$tmp_tabfile');\n";
$script .= "header=textread('$tmp_headerfile','%s');\n";
$script .= "C=linkage(B','$linkage');\n";
if ($lifetime) {
  $script .= "L=lifetime(C)';\n";
  $script .= "h=size(header,1);\n";
  $script .= "C=[C [L(h+1:end,:);-1]];\n";
}
$script .= "matrix2tab(C,'$tree_output');\n";
$script .= "C=C(:,1:3);\n";

# clustering criteria
if ($clusters_filtering ne "") {
  my $non_unique_clustering = 0;

  if ($clusters_filtering eq 'maxltfront') {
    $script .= "D=cluster_maxltfront(C);\n";
  }
  elsif ($clusters_filtering eq 'maxwltfront') {
    $script .= "D=cluster_maxwltfront(C);\n";
  }
  elsif ($clusters_filtering eq 'distance' or $clusters_filtering eq 'inconsistent') {
    if ($cut_off ne ""){
      $script .= "D=cluster(C,'criterion','$clusters_filtering','cutoff',$cut_off);\n";
    }
    elsif ($clust_num ne "") {
      $script .= "D=cluster(C,'criterion','$clusters_filtering','maxclust',$clust_num);\n";
    }
    else {
      print STDERR "Error: either cluster num of cut off must be specified\n";
      exit(1);
    }
  }
  elsif ($clusters_filtering eq 'lifetime') {
    $non_unique_clustering = 1;
    if ($cut_off ne "") {
      $script .= "D=cluster_lt(C,'lifetime',$cut_off);\n";
    }
    elsif ($clust_num ne "") {
      $script .= "D=cluster_lt(C,'clustnum',$clust_num);\n";
    }
    else {
      print STDERR "Error: either cluster num of cut off must be specified\n";
      exit(1);
    }
  }
  elsif ($clusters_filtering eq 'weighted_lifetime'){
    $non_unique_clustering = 1;
    if ($cut_off ne "") {
      $script .= "D=cluster_wlt(C,'lifetime',$cut_off);\n";
    }
    elsif ($clust_num ne "") {
      $script .= "D=cluster_wlt(C,'clustnum',$clust_num);\n";
    }
    else {
      print STDERR "Error: either cluster num of cut off must be specified\n";
      exit(1);
    }
  }

  if (not $non_unique_clustering) {
    $script .= "out=zeros(size(D,1),max(D));\n";
    $script .= "for i=1:size(D,1)\n";
    $script .= "  if(~isnan(D(i)))\n";
    $script .= "    out(i,D(i))=1;\n";
    $script .= "  end\n";
    $script .= "end\n";
    $script .= "D=out;\n";
  }
  if ($class_output ne "") {
    $script .= "matrix2tab(D,'$class_output');\n";
  }
}

# dendrogram output
if ($dendrogram_output ne "") {
  my $dendrogram_header = ",'labels',header";
  if ($expression) {
    $script .= "subplot(1,2,2);\n";
    $script .= "[H,T,perm]=dendrogram(C,0$dendrogram_header,'orientation','right');\n";
    if ($font_size) {
      $script .= "set(gca,'FontSize',$font_size);\n";
    }
    $script .= "A=zeros(size(header,1));p=1;j=1;\n";
    $script .= "for i=size(header,1)-1:-1:1\n";
    $script .= "  A(j,j+1:size(A,2))=B(p:p+i-1);\n";
    $script .= "  A(j+1:size(A,2),j)=B(p:p+i-1)';\n";
    $script .= "  p=p+i;\n";
    $script .= "  j=j+1;\n";
    $script .= "end\n";
    $script .= "AR=A(perm,perm);\n";
    $script .= "subplot(1,2,1);\n";
    $script .= "imagesc(flipud(AR));\n";
    $script .= "axis off;\n";
    if ($font_size) {
      $script .= "set(gca,'FontSize',$font_size);\n";
    }
    $script .= "print(gcf,'-dpsc','$dendrogram_output');\n";
  }
  else {
    $script .= "[H,T,perm]=dendrogram(C,0$dendrogram_header);\n";
    $script .= "print(gcf,'-dpsc','$dendrogram_output');\n";
  }
}

my $tmp_mfile = "tmp_$$".".m";
open (MFILE,">$tmp_mfile") or die "Cannot open $tmp_mfile\n";
print MFILE $script;
close (MFILE);

print STDERR "Done\n";


# ----------
# execute matlab script
# ----------
if ($debug) {
  print STDERR "-------------------------------------------------------------\n";
  print STDERR "$script \n";
  print STDERR "-------------------------------------------------------------\n";
}

print STDERR "execute matlab script: \n";
print STDERR "matlab -nodesktop -nojvm -nodisplay -nosplash -r \"tmp_$$; exit;\"\n";

my $debug_output = `matlab -nodesktop -nojvm -nodisplay -nosplash -r \"tmp_$$; exit;\"`;
if ($class_output ne '') {
  system("paste $tmp_headerfile $class_output > tmp_$$"."_classes; mv tmp_$$"."_classes $class_output;");
}
print STDERR "Done\n";

if ($debug) {
  print STDERR "-------------------------------------------------------------\n";
  print STDERR "$debug_output\n";
  print STDERR "-------------------------------------------------------------\n";
}
else {
  unlink ("$tmp_mfile");
  unlink ("$tmp_tabfile");
  unlink ("$tmp_headerfile");
}

# ----------
# print results
# ----------
my @ids_size;
for(my $i = 0; $i < scalar(@ids_list); $i++) {
  $ids_size[$i] = 1;
}

open(FILE, "$tree_output") or die "Cannot open $tree_output\n";
my $next = scalar(@ids_list);
my $count = 0;
while (<FILE>) {
  chomp $_;
  my ($id1, $id2, $score, $lt) = split("\t", $_);
  $ids_size[$next] = $ids_size[$id1-1] + $ids_size[$id2-1];
  $id1 = $ids_list[$id1-1];
  $id2 = $ids_list[$id2-1];
  $ids_list[$next] = "$id1\t$id2";
  my $list_str = $ids_list[$next];
  my $list_size = $ids_size[$next];
  $list_str =~ tr/\t/;/;
  if ($lifetime) {
    print "$count\t$list_size\t$score\t$lt\t$list_str\n";
  }
  else {
    print "$count\t$list_size\t$score\t$list_str\n";
  }
  $count++;
  $next++;
}
close(FILE);
unlink("$tree_output");


# =============================================================================
# Subroutines
# =============================================================================

# --------------------------------------------------------
# help message
# --------------------------------------------------------

__DATA__

cluster.pl [file]

clusters the input distances using matlab heirarchical clustering.
Input Format: <id1> <id2> <distance>
Output Format: <cluster id> <cluster_size> <cluster score> <list of nodes in the cluster>

Options:
  -l <string>  linkage method (single/complete/average/weighted/centroid/median/ward).
               [default=complete].
  -lt          Include the lifetime in the output.

  -c <string>  criterion for filtering clusters (distance/inconsistent/maxltfront/
               maxwltfront/lifetime/weighted_lifetime).
  -co <string> filename for output cluster assignments.
  -cn <num>    number of clusters.
  -cf <num>    cutoff value (given instead of number of clusters)

  -d <string>  filename for output dendrogram figure (ps).
  -dh          also include a heatmap of the distances.
  -df <num>    change axis fontsize [default: 12].

  -debug      debug mode.
