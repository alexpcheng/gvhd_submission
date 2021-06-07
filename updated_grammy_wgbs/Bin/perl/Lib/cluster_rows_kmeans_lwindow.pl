#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/liblist.pl";
#require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $matrix_file = $ARGV[0];
my $matrix_file_ref;

if (length($matrix_file) < 1 or $matrix_file =~ /^-/)
{
  $matrix_file_ref = \*STDIN;
}
else
{
  open(MATRIX_FILE, $matrix_file) or die("Could not open the tab-delimited matrix file '$matrix_file'.\n");
  $matrix_file_ref = \*MATRIX_FILE;
}

my $DEBUG = get_arg("d", 0, \%args);
my $verbose = get_arg("q", 1, \%args);

my $K = get_arg("k", 1, \%args);
my $L = get_arg("l", "", \%args);
my $num_iterations = get_arg("itcl", 50, \%args);
my $tolerance = get_arg("tol", 0, \%args);

my $zero_initial = get_arg("z", "", \%args);
my $kmeans_lwindow_arg_figure_name = get_arg("fig", "", \%args);
my $kmeans_lwindow_arg_figure_format = get_arg("figmat", "fig", \%args);
my $kmeans_lwindow_arg_res = get_arg("res", 1, \%args);

my $print_centroids = get_arg("prcen", 0, \%args);
my $file_centroids = get_arg("prf", "", \%args);
my $K_real = get_arg("rk", 1, \%args);

my $Dwithim = get_arg("dim", "", \%args);
my $Dind = get_arg("d", "", \%args);
my $iter_rand = get_arg("itr", 3, \%args);
my $iter_hier = get_arg("ith", 1, \%args);

##DEBUG
#print "K = $K\nL = $L\n"; exit;

my $r = int(rand(1000000));
my $matrix_for_matlab_file_name = "tmp_cluster_rows_kmeans_lwindow_mat_" . "$r";
open(MATRIX_FOR_MATLAB, ">$matrix_for_matlab_file_name") or die("Could not open a temporary file for writing: '$matrix_for_matlab_file_name'.\n");

my $kmeans_lwindow_arg_matrix_file_name = "$matrix_for_matlab_file_name";
my $kmeans_lwindow_arg_num_of_clusters = $K;

my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
my $mfile = "cluster_rows_kmeans_lwindow_plot";
my $matlabPath = "matlab";


my $INFINITY = 100000000;

###########################
#                         #
# Matrices initialization #
#                         #
###########################

my @lines = <$matrix_file_ref>;
(@lines > 2) or die("Error: expect the tab file to have at least 2 rows (1 header row + 1 data row).\n");
my $tmp_row = $lines[0];
chomp($tmp_row);

my @tmp = split(/\t/,$tmp_row);
my @tmp_d = split(/;/,$tmp[0]);

my $Dall = @tmp_d+0;


$tmp_row = $lines[1];
chomp($tmp_row);
@tmp = split(/\t/,$tmp_row);

my $m = @lines - 1; ## = num of rows
my $n = @tmp - 1; ## = num of columns

my @Delems;
my %Dhash;
if ((length $Dind)>0)
{
   @Delems = split(/,/, $Dind);
   foreach my $t (@Delems)
   {
      if ($t>$Dall || $t<1)
      {
	 die ("ERROR: one or more of the elements asked for does not exist\n") ;
      }
      $Dhash{$t}=1;
   }
} else {
   @Delems = (1..$Dall);
}
my $D = @Delems+0;



$L = ((length($L) > 0) and ($L => 1) and ($L <= $n)) ? $L : $n;

$zero_initial = (length($zero_initial) > 0) ? $zero_initial : (-1 * (int($n/2)));

my @X_init;          # The initial sequences (with all mtab types).
                     #  $X_init[i]->[j]->[t] == values of data instance i, position j, data type t.

my @Xs;              # The starts assignments.
                     #  $Xs[c]->[i]== the start index of the L-window of the i'th data instance of cluster c.
my @CM;              # The number of data instances in clusters.
                     #  $CM[c] == the number of data instances in cluster c.
my @CI;              # The mapping from cluster data instances to all data instances.
                     #  $CI[c]->[i] == the index in $X[] and $X_init[] of the i'th data instance of cluster c.
my @centroids_mean;  # The centroids of the clusters (means).
                     #  $centroids_mean[c]->[j]->[d] == the mean value of cluster c, position j, data type d.
my @centroids_var;   # The variance of clusters centroids.
                     #  $centroids_var[c]->[j]->[d] == the variance of cluster c, position j, data type d.

# the arrays to hold the data of the best clustering so far.

#my @X_good;
my @Xs_good;
my @CM_good;
my @CI_good;
my @centroids_mean_good;
my @centroids_var_good;

my $best_var = 1;
my $max_iter = $iter_rand+$iter_hier;
my $num_iter=0;
my $first = 1;

#######################################
# added - initialze for good vectors
#####################################
for (my $c=0; $c < $K; $c++)
{
   $CM_good[$c] = 0;
   my @tmp_xsc_good;
   $Xs_good[$c]= \@tmp_xsc_good;
   $Xs_good[$c]->[0] = 0;
   
   my @a_c_mean_good;
   my @a_c_var_good;
   @centroids_mean_good[$c] = \@a_c_mean_good;
   @centroids_var_good[$c] = \@a_c_var_good;
   
   my @a_ci_good;
   @CI_good[$c] = \@a_ci_good;
   $CI_good[$c]->[0] = 0;
   
   $centroids_mean_good[$c]->[0] = 0;
   $centroids_var_good[$c]->[0] = 0;
   
   for (my $j=1; $j <= $L; $j++)
   {
      my @tmp_d_mean_good;
      my @tmp_d_var_good;
      $centroids_mean_good[$c]->[$j] = \@tmp_d_mean_good;
      $centroids_var_good[$c]->[$j] = \@tmp_d_var_good;
      for (my $d=0; $d < $Dall; $d++)
      {
	 $centroids_mean_good[$c]->[$j]->[$d] = 0;
	 $centroids_var_good[$c]->[$j]->[$d] = 0;
      }
   }
}

# The data needs to be read in to @X_init once. this dousn't change.

my $tmp_row = $lines[0];
chomp($tmp_row);
my @tmp = split(/\t/, $tmp_row);
$X_init[0]=\@tmp;


for (my $i=1; $i < @lines; $i++)
{
   my $tmp_row = $lines[$i];
   chomp($tmp_row);
   my @tmp = split(/\t/, $tmp_row);
   my @tmp1;
   my @tmp2;
   
   $X_init[$i] = \@tmp2;

   # name of gene
   $X_init[$i]->[0] = $tmp[0];

   for (my $t=1; $t < @tmp; $t++)
   {
      my @tmp_all_d = split(/;/,$tmp[$t]);
      $X_init[$i]->[$t] = \@tmp_all_d;
   }
}

# starting the large iterations here
while ($num_iter < $max_iter)
{
   for (my $c=0; $c < $K; $c++)
   {
      $CM[$c] = 0;
      my @tmp_xsc;
      $Xs[$c]= \@tmp_xsc;
      $Xs[$c]->[0] = 0;
      
      my @a_c_mean;
      my @a_c_var;
      @centroids_mean[$c] = \@a_c_mean;
      @centroids_var[$c] = \@a_c_var;
      
      my @a_ci;
      @CI[$c] = \@a_ci;
      $CI[$c]->[0] = 0;
      
      $centroids_mean[$c]->[0] = 0;
      $centroids_var[$c]->[0] = 0;
      
      for (my $j=1; $j <= $L; $j++)
      {
	 my @tmp_d_mean;
	 my @tmp_d_var;
	 $centroids_mean[$c]->[$j] = \@tmp_d_mean;
	 $centroids_var[$c]->[$j] = \@tmp_d_var;
	 for (my $d=0; $d < $Dall; $d++)
	 {
	    $centroids_mean[$c]->[$j]->[$d] = 0;
	    $centroids_var[$c]->[$j]->[$d] = 0;
	 }
      }
   }

   ##################
   #                #
   # Init centroids #
   #                #
   ##################

   if (1)
   {
      if ($num_iter < $iter_hier)
      {

	 my $k_hier = 10*$K;
	 # getting centroids from hierarchical clustering
	 my $dev = ($n-$L)/2;
	 my $first_win_size = $n-int($dev);
	 my $d_elems = "@Delems";
	 $d_elems =~ s/ /,/g;
	 #################
	 #  -itr 1 -itcl 15
	 ################

	 my $r1 = int(rand(1000000));
	 my $tmp_big_centroid_file = "tmp_big_centroid_${L}_${r1}";
	 my $tmp_hier_centroid_file = "tmp_hier_centroid_${L}_${r1}";
	 my $tmp_to_erase_file = "tmp_hier_centroid_${L}_${r1}";

	 system("cluster_rows_kmeans_lwindow.pl $matrix_file -ith 0 -itr 1 -itcl ${num_iterations} -l ${first_win_size} -k ${k_hier} -d ${d_elems} -rk ${K} -prcen 1 -prf $tmp_big_centroid_file > $tmp_to_erase_file;");
	 system("hierarchical_clustering_LWindow.pl -cenf $tmp_big_centroid_file -k ${K} -l ${L} -d ${d_elems} -dall ${Dall} > $tmp_hier_centroid_file;");

	 ## take in centroids and put in $centroids_mean
	 open(IN, "<$tmp_hier_centroid_file") or die "can't open file $tmp_hier_centroid_file\n";
	 my $n=0;
	 my $line;
	 
	 #print "centroids from hierarcial clustering:\n";
	 while($line=<IN>)
	 {
	    chomp($line);
	    my @tmp = split(/\t/, $line);
	    my $count_tmp = @tmp+0;
	    my @tmp1;
	    $centroids_mean[$n] = \@tmp1;
	    $centroids_mean[$n]->[0] = 0; #never used
	    for (my $j=1; $j <= $count_tmp; $j++)
	    {
	       my @tmp_d = split(/;/,$tmp[$j-1]);
	       my @tmp_d_mean;
	       $centroids_mean[$n]->[$j]=\@tmp_d_mean;
	       
	       ######!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	       ### need to take care of places were there is no value in d
	       ######!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	       for (my $d=0; $d < (@tmp_d+0); $d++)
	       {
		  $centroids_mean[$n]->[$j]->[$d] = $tmp_d[$d];
		  #print "$centroids_mean[$n]->[$j]->[$d] ";
	       }
	       #print "\t";
	    }
	    ++$n;
	    #print "\n";
	 }


	 #system("rm tmp_hier_clus*; rm tmp_hier_centroid_file*;");

      } else {
	 # getting centroids from random choosing
	
	 my @list;
	 my $num  = $K;
      
	 for (my $i=0; $i < $m; $i++)
	 {
	    @list[$i] = $i;
	 }
	 #print "making random centroids!\n";

	 for (my $c=0; $c < $K; $c++)
	 {
	    #print "c is: $c\n";
	    my $tmp_num_c = rand();
	    $tmp_num_c *= @list;
	    $tmp_num_c = int($tmp_num_c);
	    my $num_c = splice(@list, $tmp_num_c, 1);

	    my $num_j = rand();
	    $num_j *= ($n - $L);
	    $num_j = int($num_j);
	    $num_j += 1;

	    $centroids_mean[$c]->[0] = $X_init[$num_c + 1]->[0];

	    for (my $l=1; $l <= $L; $l++)
	    {
	       for (my $d=0; $d < $Dall; $d++)
	       {
		  $centroids_mean[$c]->[$l]->[$d] = $X_init[$num_c + 1]->[$num_j + $l - 1]->[$d];
		#  print "$centroids_mean[$c]->[$l]->[$d] ";
	       }
	       #print "\t";
	    }
	    #print "\n";
	 }
	# print "ended centroids\n";
      }
   }

   if ($verbose)
   {
      print STDERR "Iter";

      for (my $c=0; $c < $K; $c++)
      {
	 my $tmp_cluster = $c + 1;
	 print STDERR "\tVarCluster#$tmp_cluster";
      }
      
      print STDERR "\tVarTotal\n";
   }
   
   my $old_total_variance = $INFINITY;;
   my $new_total_variance = 0;
   my $delta_variance = $INFINITY;
   my $iter=0;
   
   #while (($iter < $num_iterations)&&($delta_variance>$tolerance))
   while ($iter < $num_iterations)
   {
      $new_total_variance = 0;
      
      for (my $c=0; $c < $K; $c++)
      {
	 my @a_ci;
	 @CI[$c] = \@a_ci;
	 $CI[$c]->[0] = 0;
	 $CM[$c] = 0;
      }
      
      #############################################
      #                                           #
      # Cluster the rows by distance to centroids #
      #                                           #
      # The E-step                                #
      #                                           #
      #############################################
      
      for (my $i=1; $i <= $m; $i++)
      {
	 my $min_var_i = $INFINITY;
	 my $min_var_i_index_c = 0;
	 my $min_var_i_index_start = -1;
	 my $min_var_i_index_start_c = -1;
	 
	 for (my $c=0; $c < $K; $c++)
	 {
	   
	    #print "n is: $n    L is: $L   " ;
	    my ($min_var_c, $min_var_i_index_start) = get_distance($i,$c,$n,$L,\@X_init,\@centroids_mean, \@Delems, $Dall, $INFINITY);
	    #print "index start: $min_var_i_index_start\n ";
	    
	    if ($min_var_c < $min_var_i)
	    {
	       $min_var_i = $min_var_c;
	       $min_var_i_index_c = $c;
	       $min_var_i_index_start_c = $min_var_i_index_start;
	    }
	 }
	 
	 if ($min_var_i == $INFINITY)
	 {
	    my $tmp = rand();
	    $tmp *= $K;
	    $min_var_i_index_c = int($tmp);
	    $tmp = rand();
	    $tmp *= ($n - $L + 1);
	    $min_var_i_index_start_c = (int($tmp) + 1);
	 }
	 
	 my $t = $CM[$min_var_i_index_c] + 1;
	 
	 $CM[$min_var_i_index_c] = $t;
	 $CI[$min_var_i_index_c]->[$t] = $i;
	 $Xs[$min_var_i_index_c]->[$t]= $min_var_i_index_start_c;
      }
      
      #############################
      #                           #
      # Compute means (centroids) #
      #                           #
      # The M-step                #
      #                           #
      #############################

      for (my $c=0; $c < $K; $c++)
      {
	 my $m_c = $CM[$c];
	 my $tmp_var_c = 0;
	 
	 for (my $l=1; $l <= $L; $l++)
	 {
	    #here we want all Ds because we're making whole new centroid
	    for (my $d=0; $d < $Dall; $d++)
	    {
	       my $eff_i = 0;
	       my $tmp_mean = 0;
	       my $tmp_var = 0;
	       my $looked_at=0;

	       for (my $i=1; $i <= $m_c; $i++)
	       {
		  my $start = $Xs[$c]->[$i];
		  my $global_i = $CI[$c]->[$i];
		  my $tmp_x = $X_init[$global_i]->[$start + $l -1]->[$d];

		  if (length($tmp_x) > 0)
		  {
		     $eff_i++;
		     my $a = (($eff_i - 1) / $eff_i);
		     $tmp_var  = ($a * $tmp_var) + ($a * (1 - $a) * (($tmp_x - $tmp_mean) ** 2));
		     $tmp_mean = ($a * $tmp_mean) + ((1 - $a) * $tmp_x);
		     $looked_at=1;
		  }
	       }
	       if ($looked_at==0)
	       {
		  $centroids_mean[$c]->[$l]->[$d] = "";
		  $centroids_var[$c]->[$l]->[$d] = $tmp_var;
	       } else {
	       
		  $centroids_mean[$c]->[$l]->[$d] = $tmp_mean;
		  $centroids_var[$c]->[$l]->[$d] = $tmp_var;
	       }
	       # calculating in total varience only values within D's
	       if (exists($Dhash{($d+1)}))
	       {
		  $tmp_var_c += $tmp_var;
	       }
	    }
	 }
	 
	 $tmp_var_c /= ($L * $D); # here D is only what's calculated
	 $centroids_var[$c]->[0] = $tmp_var_c;
	 $new_total_variance += $tmp_var_c;
      }
      
      $new_total_variance /= $K;
      
      if ($verbose)
      {
	 my $it = $iter + 1;
	 print STDERR "$it";
	 my $tmp_print_total_var = 0;
	 
	 for (my $c=0; $c < $K; $c++)
	 {
	    my $tmp_print_var = $centroids_var[$c]->[0];
	    
	    print STDERR "\t$tmp_print_var";
	 }
	 print STDERR "\t$new_total_variance\n";
      }
      
      $delta_variance = abs($old_total_variance - $new_total_variance);
      $old_total_variance = $new_total_variance;
      $iter++;
   }
   # here $new_total_variance is the varience that the cluster produced holds
   ############ here to check the new variance and to update _good vectors, and print out varience recieved.
   
   if ($first==1)
   {
      $best_var = $new_total_variance+1;
      $first=0;
   }
   
   print STDERR "best_var: $best_var\nnew_total_variance: $new_total_variance\n";

   if ($best_var > $new_total_variance)
   {
      print STDERR "taking new variance of $new_total_variance \n";
      
      $best_var = $new_total_variance;
      
      # initializing to remove problems
      for (my $c=0; $c < $K; $c++)
      {
	 
	 my @tmp_xsc_good;
	 $Xs_good[$c]= \@tmp_xsc_good;
	 $Xs_good[$c]->[0] = 0;
	 
	 my @a_c_mean_good;
	 my @a_c_var_good;
	 @centroids_mean_good[$c] = \@a_c_mean_good;
	 @centroids_var_good[$c] = \@a_c_var_good;
	 
	 my @a_ci_good;
	 @CI_good[$c] = \@a_ci_good;
	 $CI_good[$c]->[0] = 0;
	 
	 $centroids_mean_good[$c]->[0] = 0;
	 $centroids_var_good[$c]->[0] = 0;
	 
	 for (my $j=1; $j <= $L; $j++)
	 {
	    my @tmp_d_mean_good;
	    my @tmp_d_var_good;
	    $centroids_mean_good[$c]->[$j] = \@tmp_d_mean_good;
	    $centroids_var_good[$c]->[$j] = \@tmp_d_var_good;
	    for (my $d=0; $d < $D; $d++)
	    {
	       $centroids_mean_good[$c]->[$j]->[$d] = 0;
	       $centroids_var_good[$c]->[$j]->[$d] = 0;
	    }
	 }
      }

      #changing to better clustering:
      for (my $c=0; $c < $K; $c++)
      {
	 $CM_good[$c] = $CM[$c];
	 my $num_in_clus = $CM_good[$c];
	 
	 for (my $i=0; $i<=$num_in_clus; $i++)
	 {
	    $Xs_good[$c]->[$i] = $Xs[$c]->[$i];
	 }

	 for (my $i=1; $i<=$num_in_clus; $i++)
	 {
	    $CI_good[$c]->[$i] = $CI[$c]->[$i] ; 
	 }

	 $centroids_mean_good[$c]->[0] = $centroids_mean[$c]->[0];
	 $centroids_var_good[$c]->[0] = $centroids_var[$c]->[0];
	 
	 for (my $j=1; $j <= $L; $j++)
	 {
	    for (my $d=0; $d < $Dall; $d++)
	    {
	       $centroids_mean_good[$c]->[$j]->[$d] = $centroids_mean[$c]->[$j]->[$d];
	       #print "my d is: $centroids_mean_good[$c]->[$j]->[$d]\n";
	       $centroids_var_good[$c]->[$j]->[$d] = $centroids_var[$c]->[$j]->[$d];
	    }
	 }
      }
   }
   $num_iter++;
}

###########################################
#                                         #
# Output - printing out the best clusters #
#                                         # 
###########################################


# if for hierarcial clustering printing out centroids (only of clusters larger then limit)
if ($print_centroids == 1)
{
   my $limit = (@X_init/$K)/3; ## maybe want to change the limit??????!!!!!!!!!!!!1
   #my $limit=0;
   my $count_out = 0;
   my $count_in = 0;
   open(CEN_FILE, ">$file_centroids") or die "can't open file $file_centroids\n";
   for (my $c=0; $c < $K; $c++)
   {
      my $num = $CM_good[$c];
      if (($num>$limit)||($K-($count_out+$count_in) <= ($K_real-$count_in)))  #taking even bins who are too small if needed
      {
	 print CEN_FILE "$num";
	 for (my $j=1; $j <= $L; $j++)
	 {
	    print CEN_FILE "\t";
	    my $tmp = $centroids_mean_good[$c]->[$j]->[0];
	    $tmp = (length($tmp)>0) ? $tmp : "";
	    print CEN_FILE "$tmp";
	    for (my $d=1; $d < $Dall; $d++)
	    {
	       $tmp = $centroids_mean_good[$c]->[$j]->[$d];
	       $tmp = (length($tmp)>0) ? $tmp : ""; 
	       print CEN_FILE ";$tmp";	    
	    }
	 }
	 print CEN_FILE "\n";
	 $count_in++;
      } else {
	 $count_out++;
      }
   }
}

close(CEN_FILE);


my @Dim;
if ((length $Dwithim)>0)
{
   @Dim = split(/,/, $Dwithim);
   foreach my $t (@Dim)
   {
      if ($t>$Dall || $t<1)
      {
	 die ("ERROR: one or more of the elements asked for in image does not exist\n") ;
      }
   }
} else {
   @Dim = (1..$Dall);
}


for (my $c=0; $c < $K; $c++)
{
   my $m_c = $CM_good[$c];

   my @cluster_zeros;

   for (my $i=1; $i <= $m_c; $i++)
   {
      my $tmp_zero = ($zero_initial + ($Xs_good[$c]->[$i] - 1));
      $cluster_zeros[$i-1] = $tmp_zero;
   }

   my @sorted_cluster_zeros = sort {$a <=> $b} @cluster_zeros;
   my $median_cluster_zero = $sorted_cluster_zeros[int(@sorted_cluster_zeros / 2)];

   @cluster_zeros = ();
   @sorted_cluster_zeros = ();

   my $cluster_id = ($c + 1);

   ##############################
   #                            #
   # Plot the clusters (Matlab) #
   #                            #
   ##############################

   if (length($kmeans_lwindow_arg_figure_name) > 0)
   {
      print MATRIX_FOR_MATLAB "$cluster_id";

      for (my $i = $median_cluster_zero; $i <= ($median_cluster_zero + $L - 1); $i++)
      {
	 print MATRIX_FOR_MATLAB "\t$i";
      }

      print MATRIX_FOR_MATLAB "\n";

      #for (my $d=0; $d < $Dall; $d++) # !!!!!!!!!!!change to "d" and not "d-1" if taking this option!!!!!!!!!!!!!!!!!!
      foreach my $d (@Dim)
      {
	 for (my $i=1; $i <= $m_c; $i++)
	 {
	    my $tmp_i = $CI_good[$c]->[$i];

	    print MATRIX_FOR_MATLAB "$cluster_id";

	    for (my $l=1; $l <= $L; $l++)
	    {
	       my $tmp_l = ($l + $Xs_good[$c]->[$i] - 1);

	       print MATRIX_FOR_MATLAB "\t$X_init[$tmp_i]->[$tmp_l]->[$d-1]";
	    }

	    print MATRIX_FOR_MATLAB "\n";
	 }
      }
   }

   ###########################
   #                         #
   # Print the alignment     #
   #                         #
   ###########################
   for (my $i=1; $i <= $m_c; $i++)
   {
      my $tmp_i = $CI_good[$c]->[$i];

      print STDOUT "$X_init[$tmp_i]->[0]\t$cluster_id\t$Xs_good[$c]->[$i]\n";
   }
}

close(MATRIX_FOR_MATLAB);

# geting min and max for d's which are to b imaged
if (length($kmeans_lwindow_arg_figure_name) > 0)
{
   my $min_y = $INFINITY;
   my $max_y = (-1 * $INFINITY);

   for (my $c=0; $c < $K; $c++)
   {
      for (my $l=1; $l <= $L; $l++)
      {
	 foreach my $dim (@Dim)
	 {
	    my $y = $centroids_mean_good[$c]->[$l]->[$dim-1];

	    if (length($y) > 0)
	    {
	       $min_y = ($y < $min_y) ? $y : $min_y;
	       $max_y = ($y > $max_y) ? $y : $max_y;
	    }
	 }
      }
   }

   my $kmeans_lwindow_arg_legend = "\'\'";

   my @tmp_str = split(/;/,$X_init[0]->[0]);
   if ( $Dall == @tmp_str )
   {
      my $first=1;
      my $tmp_str1;
      foreach my $d (@Dim)
      {
	 if ($first==1)
	 {
	    $tmp_str1 = "\'$tmp_str[$d-1]\'";
	    $first=0;
	 } else {
	    $tmp_str1 .= " ; \'$tmp_str[$d-1]\'";
	 }

	 
      }

      #my $tmp_str1 = "\'$tmp_str[0]\'";
      #for (my $ts=1; $ts < @tmp_str; $ts++)
      #{
#	 $tmp_str1 .= " ; \'$tmp_str[$ts]\'";
#      }
      $kmeans_lwindow_arg_legend = "\{ $tmp_str1 \}";
   }
   else
   {
      print STDERR "Error. Dall=$Dall. tmp_str= @tmp_str .\n";
   }

   my $kmeans_lwindow_arg_duplicates = $Dall;
   my $kmeans_lwindow_arg_duplicates_withim = @Dim+0;
   my $params = "(\'$kmeans_lwindow_arg_matrix_file_name\',$kmeans_lwindow_arg_num_of_clusters,\'$kmeans_lwindow_arg_figure_name\',\'$kmeans_lwindow_arg_figure_format\',$min_y,$max_y,$kmeans_lwindow_arg_res,$kmeans_lwindow_arg_duplicates_withim,$kmeans_lwindow_arg_legend)";
   my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";

   print STDERR "Calling Matlab with: $command\n";
   system ($command) == 0 || die "Failed to run Matlab\n";

   ## MEROMIT please please please delete tmp files at the end...
  # system("/bin/rm -f $tmp_big_centroid_file $tmp_hier_centroid_file $tmp_to_erase_file");
}

#system("rm -f $matrix_for_matlab_file_name");




#	# print "The centroids from hierarcial clustering are:\n";
#	 for (my $t=0; $t<$K; $t++)
#	 {
#	    print "centroid $t:  ";
#	    for (my $j=1; $j <= $L; $j++)
#	    {
#	       for (my $d=0; $d < $D; $d++)
#	       {
#		  #print "in for\n";
#		  print "\t$centroids_mean[$t]->[$j]->[$d]" ;		 
#	       }
#	    }
#	    print "\n";
#	 }

#######################
#                     #
# SUBROUTINES         #
#                     #
#######################

###########################
#                         #
# @list Permutation($num) #
#                         #
###########################
sub Permutation
{
   my $num = $_[0];
   my @res0;

   for (my $w=0; $w < $num; $w++)
   {
      my @tmp_pair;
      $res0[$w] = \@tmp_pair;
      $res0[$w]->[0] = rand();
      $res0[$w]->[1] = $w;
   }

   my @sorted_res0 = sort {$a->[0] <=> $b->[0]} @res0;

   my @res;
   for (my $w=0; $w < $num; $w++)
   {
      $res[$w] = $sorted_res0[$w]->[1];
   }

   return @res;
}

sub get_distance
{
   # i is the place in X
   # c is the cluster mean (in place ($c-1)
   # $n is total length $L is length 
   my ($i,$c,$n,$L,$X_initp,$centroids_meanp, $D_arr, $Dall, $INFINITY) = @_;

   my $total_dist;
   my $place_j;
   my $first = 1;

   for (my $j=1; $j <= ($n - $L + 1); $j++)
   {
      my $tmp_var_j;

      foreach my $d (@$D_arr)
      {
	 my $eff_i = 0;
	 my $tmp_var_d = 0;

	 for (my $l=1; $l <= $L; $l++)
	 {
	     my $tmp_x = $$X_initp[$i]->[$j + $l - 1]->[$d-1];
	     my $tmp_y = $$centroids_meanp[$c]->[$l]->[$d-1];

	     if ((length($tmp_x) > 0) and (length($tmp_y) > 0))
	     {
		$eff_i++;
		my $tmp_a = (($eff_i - 1) / $eff_i);
		$tmp_var_d  = (($tmp_a * $tmp_var_d) + ((1 - $tmp_a) * (($tmp_x - $tmp_y) ** 2)));
	     }
	  }	

	  $tmp_var_d = ($eff_i > 0) ? $tmp_var_d : $INFINITY;
	  $tmp_var_j += $tmp_var_d;
	
      }
      if ($first==1)
      {
	 $total_dist = $tmp_var_j+1;
	 $first=0;
      }
      if ($tmp_var_j < $total_dist)
      {
	 $total_dist = $tmp_var_j;
	 $place_j = $j;
      }
   }
   return ($total_dist, $place_j);
}


#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         cluster_rows_kmeans_lwindow.pl <matrix.tab>

 Description:    The l-window k-means clustering algorithm: a hard EM clustering on extended Naive Bayse model, with hidden variables (roots):
                 (1) the clustering assingment, and (2) the start of the (the l-window) alignment assignemnt.

                 Centroids initialization by two methods: (1) preprocess of hierarchical clustering, (2) pick random rows & windows from the given matrix.
                 The best clustering is taken over all specified starting points.

                 Assume <matrix.tab> has one row header and one column header.

                 Can handle with missing values.

                 *** Can handle a "multiple tab format", where each value entry of <matrix.tab> has D >= 1 values in the format "value1;value2;...;valueD".
                     In such a case, for each d=1,...,D we keep seperate centroids and compute seperate means & variances, but the start and ends of
                     centroids is the same for all d. ***

 Output:         <vector_id> \t <cluster_id> \t <l-window start>

                 where: <vector_id>      is from the 1st column header of <matrix.tab>
                        <cluster_id>     is 1-based
                        <l-window start> is the 1-based position of the start of the l-window in original vector 
                                         (i.e, l-window start = 1 => the l-window starts at the beginiing of the vector)

 Flags:

   -l <int>      The length of the l-window on which the alignment is defined (default: n = row vector size, i.e. reduce to standard k-means )

   -k <int>      The number of clusters (default: 1)

   -itcl <int>   The number of iterations done in a single clustering run (default: 50)

   -itr <int>    The number of random initializations (default: 3)

   -ith <int>    The number of hierarchical clustering initializations (default: 1)

   -fig <str>    The output file figure, which shows the clusering profiles (default: no figure)

   -figmat <fm>  The figure file format, where <fm> = ai/bmp/emf/eps/fig/jpg/m/pbm/pcx/pgm/png/ppm/tif (default = fig)

   -z <int>      The start coordinate of rows. The plots are taken such that the median position of "zero"
                 after the alignment is zero in each cluster (default: -1 * int(n/2), for n = row vector size)

   -res <int>    The resolution of the data for the figure's plot (default: 1)

   -d <int>      The elements of the tab multipications ("mulitple tab format" case) of the tab file that are used for the clustering
                 (default: all elements ) (example: -d 1,3,5  will cluster by the first, third and fifth elements in the mtab file.)


   -dim <int>    The elements of the tab multipications ("mulitple tab format" case) of the tab file that are ploted as images
                (default: all)

   -prcen       Print out the centroids only of the cluster who are bigger then (num_of_strings/k)/3  to a file by name tmp_centroids_<matrix_input_file>
                this option is used before using hierarcial clustering for inisializing the centroids.

   -prf         The name of the file to print the centroids to.

   -rk          When using to cluter for a larger K input the evential K to be clustered.
