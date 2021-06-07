#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help") {
   print STDOUT <DATA>;
   exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) {
   $file_ref = \*STDIN;
} else {
   open(FILE, $file) or die("Could not open file '$file'.\n");
   $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);

my $A_column = get_arg("A", 0, \%args);
my $B_column = get_arg("B", 1, \%args);
my $sort_neighbors = get_arg("sort", 0, \%args);
my $sort_neighbors_numerically = get_arg("sortn", 0, \%args);
my $sort_in_reverse_order = get_arg("sortr", 0, \%args);
my $sort_all = get_arg("sortall", 0, \%args);
my $sum_neighbors = get_arg("sum", 0, \%args);
my $mean_neighbors = get_arg("mean", 0, \%args);
my $mean_of_logs_neighbors = get_arg("meanoflogs", 0, \%args);
my $std_neighbors = get_arg("std", 0, \%args);
my $count_neighbors = get_arg("count", 0, \%args);
my $min_num_neighbors = get_arg("min", 0, \%args);
my $delim = get_arg("d", "\t", \%args);

my $LOG_BASE = $mean_of_logs_neighbors > 0 ? log($mean_of_logs_neighbors) : log(2);

my %rows_hash;
my @rows;

my %row2neighbors;

print STDERR "list2neighborhood.pl @ARGV reading input file ";

my $row_counter = 1;
while (<$file_ref>) {
   chop;

   if ($row_counter % 10000 == 0) {
      print STDERR ".";
   }

   my @row = split(/\t/);

   if (length($row2neighbors{$row[$A_column]}) > 0) {
      $row2neighbors{$row[$A_column]} .= "\t";
   }
   $row2neighbors{$row[$A_column]} .= "$row[$B_column]";

   if (length($rows_hash{$row[$A_column]}) == 0) {
      $rows_hash{$row[$A_column]} = "1";
      push(@rows, $row[$A_column]);
   }

   $row_counter++;
}

print STDERR "Done.\n";

foreach my $row (@rows) {
   my @neighbors = split(/\t/, $row2neighbors{$row});

   if ($sort_neighbors == 1) {
      if ($sort_in_reverse_order == 1) {
	 @neighbors = sort { $b cmp $a; } @neighbors;
      } else {
	 @neighbors = sort { $a cmp $b; } @neighbors;
      }
   }
   if ($sort_neighbors_numerically == 1) {
      if ($sort_in_reverse_order == 1) {
	 @neighbors = sort { $b <=> $a; } @neighbors;
      } else {
	 @neighbors = sort { $a <=> $b; } @neighbors;
      }
   }
   if ($sort_all == 1) {
      push (@neighbors, $row);
      @neighbors = sort { $b cmp $a; } @neighbors;
   }

   if (@neighbors >= $min_num_neighbors) {
      if ($sort_all == 1) {
	 for (my $i = 0; $i < @neighbors; $i++) {
	    print "$neighbors[$i]$delim";
	 }
      } else {
	 print "$row";
      }
       
      if ($count_neighbors == 1) {
	 my $num_neighbors = @neighbors;
	 print "$delim$num_neighbors";
      }
       
      if ($sum_neighbors == 1 or $mean_neighbors == 1 or $mean_of_logs_neighbors > 0 or $std_neighbors == 1) {
	 my $sum = 0;
	 my $sum_of_logs = 0;
	 my $sum_XX = 0;
	 for (my $i = 0; $i < @neighbors; $i++) {
	    $sum += $neighbors[$i];
	    if ($mean_of_logs_neighbors > 0) {
	    	$sum_of_logs += $neighbors[$i] > 0 ? log($neighbors[$i]) / $LOG_BASE : 0;
	    }
	     
	    $sum_XX += $neighbors[$i] * $neighbors[$i];
	 }
	  
	 if ($sum_neighbors == 1) {
	    print "$delim$sum";
	 }

	 if ($mean_neighbors == 1) {
	    my $mean = $sum / @neighbors;
	    print "$delim$mean";
	 }

	 if ($mean_of_logs_neighbors > 0) {
	    my $mean_of_logs = $sum_of_logs / @neighbors;
	    print "$delim$mean_of_logs";
	 }

	 if ($std_neighbors == 1) {
	    my $std = sqrt($sum_XX / @neighbors - ($sum / @neighbors) * ($sum / @neighbors));
	    print "$delim$std";
	 }
      } elsif ($sort_all == 0) {
	 for (my $i = 0; $i < @neighbors; $i++) {
	    print "$delim$neighbors[$i]";
	 }
      }
      print "\n";
   }
}


__DATA__

list2neighborhood.pl <file>

Takes in a list of pairs of <A><tab><B> and makes a tab delimited
file out of that with the different A's at rows and all B's for the 
   same A will appear as the neighborhood of A.

   Note that you can also specify <A><tab><B><tab><value> using the -V
option and then the value at the value column will be written and not '1'

-A <num>:          specifies the column for the A value of the pair (default: 0)
-B <num>:          specifies the column for the B value of the pair (default: 1)

-sort:             Sort the neighbors of each row
-sortn:            Sort the neighbors of each row numerically
-sortr:            Sort in reverse order
-sortall:          Sort all the row (including the first column)
-min <num>:        Print neighborhoods with at least <num> elements (default: 0)
-sum:              Sum the neighbors of each row
-mean:             Print mean of the neighbors of each row
-meanoflogs <num>: Print the mean of the logs of the neighbors of each row in base <num>
-std:              Print Standard deviation of the neighbors of each row
-count:            Add the number of neighbors of each row

-d <delim>:        delimiter between neighbors (default: '\t')
-s                 The given file is already sorted by the key
