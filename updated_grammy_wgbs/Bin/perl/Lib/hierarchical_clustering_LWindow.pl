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


my $K = get_arg("k", 3, \%args); # number of final groups
my $L = get_arg("l", "", \%args); # window size to clustr with
my $Dind = get_arg("d", "", \%args); # string with indexes of elements to consider
my $Dall = get_arg("dall", "", \%args); # all the elements in each cell.
my $centroid_file = get_arg("cenf", "", \%args);

my %centroids; # hash to hold all centroids in a given time of the running of the algorithem
               # the number of centroids will go from M down to to K.
my %centroids_dist;  # hash holding a half matrix which in each cell hold the distance distance between i and j 
                     # and the places from where the window length is taken
                     # $centroid_dist{$j}->[$i]->[0] holds the distance between the centroids of clusters i and j
                     # $centroid_dist{$j}->[$i]->[1] holds the place in $i from where to take window length 
                     # $centroid_dist{$j}->[$i]->[2] holds the place in $j from where to take window length 
my %num_in_clus ;  #hash that holds in place i the number of elements in the group represented by centroid i.

my @smallest_arr; # array to hold the smallest distance calculated in each loop


my $INFINITY =  100000000;

# hash to hold centroids - (groups who are too small were taken out in the clustering phase)

open (CEN_IN, "<$centroid_file") or die "can't open centroid file $centroid_file\n";
my $cen_in_ref = \*CEN_IN;
my @old_centroid = <$cen_in_ref>;

(@old_centroid > 0) or die("Error: need to have at least one centroid in hirarcial clustering.\n");

my $M = @old_centroid+0; # The number of clusters we're dealing with

my @Delems = split(/,/, $Dind);
foreach my $t (@Delems)
{
   if ($t>$Dall || $t<1)
   {
      die ("ERROR: one or more of the elements asked for does not exist\n") ;
   }
}


#my $countd=0;
#foreach my $e (@Delems)
#{ 
#   print "Delem $countd is:$e \n";
#   $countd++;
#}
#print "M is: $M\n";

for (my $j=1; $j<=$M; $j++)
{
   my $line = $old_centroid[$j-1];
   chomp($line);
   my @cent = split(/\t/, $line);
   $num_in_clus{$j}=$cent[0];
   shift(@cent);
   $centroids{$j} = \@cent;
}


#foreach my $el (keys %centroids)
#{
#   my $arr_el = $centroids{$el};
#   foreach my $t (@$arr_el)
#   {
#      print "$t\t";
#   }
#   print "\n";
#}



## build a hash to hold all distances between centroids - the keys are group numbers and they point to arrays holding the 
## distance to all other centroids.
# maybe can make half a matrix (check only for centroids for group numbers smaller then $key)?


## make centroid for each group (put in hash of centroids) and put values of distances in hash
my $smallest_dist;
my $first=1;


for (my $j=1; $j<=$M; $j++)
{
   #print "j is: $j\n";
   my @dist_vec;
   for (my $i=1; $i<$j; $i++)
   {
      #print "j is: $j\t i is: $i\n";
      my ($dist,$place_i, $place_j) = calc_dist($i, $j, $L, \%centroids, \@Delems, $INFINITY);
      
      my @vals = ($dist,$place_i, $place_j);
      #print "dist: $dist\t place_i: $place_i\t place_j: $place_j\n";
      $dist_vec[$i]=\@vals;
      
      if ($first==1) 
      {
	 $smallest_dist=$dist+1;
	 $first=0;
      }
      if ($dist<$smallest_dist)
      {
	 $smallest_arr[0]=$dist;
	 $smallest_arr[1]=$i;
	 $smallest_arr[2]=$j;
	 $smallest_dist = $dist;
      }
     # $centroids_dist{$j}=\@dist_vec;
   #   print "\n";
   }
   $centroids_dist{$j}=\@dist_vec;
}

#debug!! printing matrix
#for (my $j=1; $j<=$M; $j++)
#{
#   for (my $i=1; $i<$j; $i++)
#   {
#      my $arr_p = $centroids_dist{$j};
#      my $arr_vals_p = $$arr_p[$i];
      #print "array in place 3,2:\n";
#      foreach my $p (@$arr_vals_p)
#      {
#	 print "$p,";
#      }
#      print "\t";
#   }
#   print "\n";
#}
#print "\n";

# for  i and j are closest 
#  1. calc new centroid - put in place i and erase key j of centroid hash
#  2. calc distance of new centroid from all others and update in hash

my $size = (keys %centroids) +0;

while ($size > $K)
{
   #print "taking cent out:\n";

   ## making new centroid instead of two
   my $i = $smallest_arr[1];
   my $j = $smallest_arr[2];
   my $start_i = $centroids_dist{$j}->[$i]->[1];
   my $start_j = $centroids_dist{$j}->[$i]->[2];

#   print "i is: $i    j is: $j\n";
#   print "start i: $start_i   start_j: $start_j\n";
   
   my $p_new_cent = get_new_cent($i, $start_i, $j, $start_j, $L, \%centroids, \%num_in_clus, $Dall); #getting pointer to new centroid
   $centroids{$i} = $p_new_cent;
   $num_in_clus{$i} += $num_in_clus{$j};

#############
#   print "new_cent:  ";
#   foreach my $t (@$p_new_cent){
#      print "$t\t";
#   }
#   print "\n\n";
#############

   delete $centroids{$j};
   delete $centroids_dist{$j};
   delete $num_in_clus{$j};

   ## updating %centroids_dist
   my @dist_vec;
   for (my $l=1; $l<$i; $l++)
   {
      my @vals;
      if (exists $centroids{$l})
      {
	 #print "before\n";
	 my ($dist, $place_l, $place_i) = calc_dist($l, $i, $L, \%centroids, \@Delems);
	 #print "after\n";
	 @vals = ($dist,$place_l, $place_i);
	 # print "i is: $i\t l is: $l\n";
	 # print "dist: $dist\t place_i: $place_i\t place_l: $place_l\n\n";
      } else {
	 #print " $l douse not exist\n\n";
	 @vals = (-1,0,0);
      }
       $dist_vec[$l]=\@vals;
   }
   $centroids_dist{$i}=\@dist_vec;

   #my @vals_p;
   for(my $p=$i+1; $p<=$M; $p++)
   {
      if (exists $centroids{$p})
      {
	 my ($dist,$place_i, $place_p) = calc_dist($i, $p, $L, \%centroids, \@Delems);
	 my @vals_p = ($dist,$place_i, $place_p);
	 #print "i is: $i\t p is: $p\n";
	 # print "dist: $dist\t place_i: $place_i\t place_p: $place_p\n\n";
	 $centroids_dist{$p}->[$i] = \@vals_p;
      } else {
	 #print "$p dose not exist\n\n";
	 my @vals_p = (-1,0,0);
	 $centroids_dist{$p}->[$i] = \@vals_p;
      }
   }

   ## erasing the column of the erased centroid
   for (my $l=$j+1;$l<=$M;$l++)
   {
      my @vals_l = (-1,0,0);
      $centroids_dist{$l}->[$j] = \@vals_l;
   }



   ## finding new smallest distance

   $first=1;
   for(my $j=1; $j<=$M; $j++)
   {
      if (exists $centroids{$j})
      {
	 for(my $i=1; $i<$j; $i++)
	 {
	    my $val = $centroids_dist{$j}->[$i]->[0];

	  #  print "!!! finding smallest val:\n";
	  #  print "i is: $i   j is: $j    val is: $val\n";
	    if ($val != (-1))
	    {
	       if ($first==1)
	       {
		  $smallest_arr[0]=$val;
		  $smallest_arr[1]=$i;
		  $smallest_arr[2]=$j;
		  $first=0;
	       }
	       if ($val<$smallest_arr[0])
	       {
		  $smallest_arr[0]=$val;
		  $smallest_arr[1]=$i;
		  $smallest_arr[2]=$j;
	       }
	    }
	 }
      }
   }


   #debug!! printing matrix
 #  for (my $j=1; $j<=$M; $j++)
 #  {
 #     if (exists($centroids_dist{$j}))
 #     {
#	 for (my $i=1; $i<$j; $i++)
#	 {
#	    my $arr_p = $centroids_dist{$j};
#	    my $arr_vals_p = $$arr_p[$i];
#	    #print "array in place 3,2:\n";
#	    foreach my $p (@$arr_vals_p)
#	    {
#	       print "$p,";
#	    }
#	    print "\t";
#	 }
#	 print "\n";
#      }
#   }
#   print "\n";

   $size = (keys %centroids) +0;
}







#---------------------------------------------------------------------#
# OUTPUT                                                              #
#---------------------------------------------------------------------#

## print k centroids from hash to file

for(my $j=1; $j<=$M; $j++)
{
   if (exists $centroids{$j})
   {
      print "$centroids{$j}->[0]";
      for (my $p=1; $p<=$L; $p++)
      {
	 print "\t$centroids{$j}->[$p]";
      }
      print "\n";
   }
}



#---------------------------------------------------------------------#
# SUBROUTINES                                                         #
#---------------------------------------------------------------------#

## calculates distance between two centroids.if the centroids (one or both) 
## are longer then L then all options are considered and the best one taken.
## returns and array (dist,place_i,place_j) - the places are where the counting starts


sub calc_dist
{
   my ($i, $j, $L, $centroids, $d_arr, $INFINITY) = @_;
   my $tmp_arri = $$centroids{$i};
   my $length_i = @$tmp_arri+0;
    
   my $tmp_arrj = $$centroids{$j};
   my $length_j = @$tmp_arrj+0;
   #print "length j is: $length_j\n";
  
   my @dist;
   my $first=1;
   for (my $l=1; $l<=($length_i-$L+1);$l++)
   {
       for (my $n=1; $n<=($length_j-$L+1);$n++)
       {
	  my $tmp_var;
	 	
	  foreach my $d (@$d_arr)
	  { 
	     my $eff_i = 0;
	     my $tmp_var_d = 0;
	     
	     for (my $m=1; $m < $L; $m++)
	     {
		
		my $cell_i = $$centroids{$i}->[$m+$l-1];
		my @cell_arr_i = split(/;/, $cell_i);
		my $cell_j = $$centroids{$j}->[$m+$n-1];
		my @cell_arr_j = split(/;/, $cell_j);
		my $tmp_x = $cell_arr_i[$d-1];
		my $tmp_y = $cell_arr_j[$d-1];
		#print "tmp_x: $tmp_x  tmp_y: $tmp_y\n";
			
		if (((length $tmp_x) > 0) and ((length $tmp_y) > 0))
		{
		   $eff_i++;
		   my $tmp_a = (($eff_i - 1) / $eff_i);
		   $tmp_var_d  = (($tmp_a * $tmp_var_d) + ((1 - $tmp_a) * (($tmp_x - $tmp_y) ** 2)));
		}	
	     }
	     $tmp_var_d = ($eff_i > 0) ? $tmp_var_d : $INFINITY;
	     $tmp_var += $tmp_var_d;
	     #print "tmp_var = $tmp_var\n";
	  }
	  
	  
	  if ($first==1)
	  {
	     $dist[0]=$tmp_var;
	     $dist[1]=$l;
	     $dist[2]=$n;
	     $first=0;
	  } 
	  elsif ($tmp_var < $dist[0])
	  {
	     $dist[0]=$tmp_var;
	     $dist[1]=$l;
	     $dist[2]=$n;
	  }
       }
    }
   return @dist;
}



## given two places of centroids in the hash and their starting points
## the method calculates the new centroid and returns a pointer to it

sub get_new_cent
{
   my ($i, $start_i, $j, $start_j, $L, $hash_p, $nums, $Dall) = @_;
   my @cent;
   my $count=0;
   my $num_i = $$nums{$i};
   my $num_j = $$nums{$j};
   my $num_all = $num_i+$num_j;
   my $before_i = ($num_i/$num_all);
   my $before_j = ($num_j/$num_all);
   
   my $l=($start_i-1);
   my $n=($start_j-1);
   my @Dall = (1..$Dall);

   for(my $c=0; $c<$L; $c++)
   {
      my $cell_i = $$hash_p{$i}->[$c+$l];
      #print "cell i: $cell_i\n";
      my @cell_arr_i = split(/;/, $cell_i);
      
      my $cell_j = $$hash_p{$j}->[$c+$n];
      my @cell_arr_j = split(/;/, $cell_j); 
      
      my $new_cell = "";
      my $first=1;
      # do on all d because need to same all centroid
      foreach my $d (@Dall)
       {
	  my $num;
	  if (($cell_arr_i[$d-1] eq "") && ($cell_arr_j[$d-1] eq ""))
	  {
	     $num="";
	  } else 
	  {
	     if ($cell_arr_i[$d-1] eq "")
	     {
		$num=$cell_arr_j[$d-1];
	     }
	     elsif ($cell_arr_j[$d-1] eq "")
	     {
		$num=$cell_arr_i[$d-1];
	     }
	     else
	     {
		$num =  $before_i*$cell_arr_i[$d-1] + $before_j*$cell_arr_j[$d-1];
	     }
	  }
	
	  
	  if ($first==1)
	  {
	     $new_cell .= "$num";
	     $first=0;
	  } else {
	     $new_cell .= ";$num";
	  }
       }
        $cent[$c] = $new_cell;
    }
   return \@cent;
}





#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         hirarchial_clus_LWindow.pl 

 Description:    recieves a file holding the centroids of groups (recieved by Kclustering): in the first column the 
                 number of elements in the cluster and after that the centroid of the cluster - in tab delimited format.
                 clusters the centroids in an hirarchial way (each time taking the two closest centroids
                 and uniting them), making a new centroid for each group made. The distance function 
                 usses the LWindows method. 

                 The method prints out the K centroids of the final K groups.

               !! The file given should not have a new line at the end of it.!!

 Flags:

   -l <int>      The length of the l-window on which the alignment is defined 

   -k <int>      The number of clusters to reach at the end (default: 3)

   -d            The places of the elements to consider from the centroids in the clustering. 
                 (example - (1,3) will consider ellements 1 and 3

   -dall         The number of elements in the cells.

   -cenf         The file holding the centroids of the groups, in a tab delimited manner each line in the file is for cluster number (i+1)
