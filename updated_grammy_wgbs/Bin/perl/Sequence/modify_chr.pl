#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $modify_type = get_arg("t", "Both", \%args);
my $add_upstream = get_arg("au", "", \%args);
my $add_downstream = get_arg("ad", "", \%args);
my $add_column_upstream = get_arg("acu", "", \%args);
my $add_column_downstream = get_arg("acd", "", \%args);
my $boundary_column_upstream = get_arg("bcu", "", \%args);
my $boundary_column_downstream = get_arg("bcd", "", \%args);
my $upstream_downstream_to_start_end = get_arg("ud2se", 0, \%args);
my $skip = get_arg("skip", 0, \%args);
my $zero_bound = get_arg("zero_bound", 0, \%args);
my $res = get_arg("res", 0, \%args);
my $res_mode = get_arg("res_mode", 1, \%args);
my $strand_mode = get_arg("strand_mode", 0, \%args);

if ($modify_type eq "Sep" && (length($add_upstream) <= 0 || length($add_downstream) <= 0)) {
   die ("Error: both au (add upstream) and ad (add downstream) parameters are required in \"Sep\" mode.\n");
}

for (my $i = 0; $i < $skip; $i++) {
   my $line = <$file_ref>;
   print "$line";
}

if ($res > 0)			# Filter by start position
{
   my $last_pos = -1;
   my $canditator = -1;
   my $canditator_str;
   my $last_segment = "";
   my $curr_segment;
   my $segment_changed = 0;
   while (<$file_ref>) {
      chop;
      my @row = split(/\t/);
      my $direction = $row[2] < $row[3] ? 1 : -1;
      
      if ($curr_segment ne $row[0]) {
	 $last_segment = $curr_segment;
	 $curr_segment = $row[0];
	 $segment_changed = 1;
      } else {
	 $segment_changed = 0;
      }
      
      if ($direction * $strand_mode >= 0) {
	 my $start_pos = $row[2] < $row[3] ? $row[2] : $row[3];
	 if ($res_mode == 0)	# fixed mode
	 {
	    if (($start_pos - $last_pos) % $res == 0 || $last_pos == -1 || $segment_changed == 1) {
	       $last_pos = $start_pos;
	       print "$_\n";
	    }
	 } else			#greedy mode
	 {
	    if ($segment_changed == 1) {
	       if ($canditator != -1) {
		  $canditator = -1;
		  print "$canditator_str\n";
		  $canditator_str = "";
	       }
	       $last_pos = -1;
	       print "$_\n";
	    } elsif ($start_pos == $last_pos + $res || $last_pos == -1) {
	       $last_pos = $start_pos;
	       $canditator = -1;
	       $canditator_str = "";
	       print "$_\n";
	    } elsif ($start_pos >= $last_pos + 2 * $res) {
	       if ($canditator != -1) {
		  $last_pos = $canditator;
		  print "$canditator_str\n";
		  $canditator = $start_pos;
		  $canditator_str = $_;
	       } else {
		  $last_pos = $start_pos;
		  print "$_\n";
	       }
	    } else {
	       if ($canditator == -1 || abs($last_pos + $res - $start_pos) < abs($last_pos + $res - $canditator)) {
		  $canditator = $start_pos;
		  $canditator_str = $_;
	       }
	    }
	 }
      }
   }
   if ($canditator != -1) {
      print "$canditator_str\n";
   }

} else {
   while (<$file_ref>) {
      chop;

      my @row = split(/\t/);

      my $forward = $row[2] < $row[3] ? 1 : 0;

      if ($modify_type eq "Sep") {
	 if ($forward == 1) {
	    $row[2] = &ModifyStart($row[2], -$add_upstream);
	    $row[3] = &ModifyEnd($row[3], $add_downstream);
	 } else {
	    $row[2] = &ModifyStart($row[2], $add_upstream);
	    $row[3] = &ModifyEnd($row[3], -$add_downstream);
	 }
      } else {
	 if (length($add_upstream) > 0) {
	    if ($forward == 1) {
	       $row[2] = &ModifyStart($row[2], -$add_upstream);
	       $row[3] = &ModifyEnd($row[3], -$add_upstream);
	    } else {
	       $row[2] = &ModifyStart($row[2], $add_upstream);
	       $row[3] = &ModifyEnd($row[3], $add_upstream);
	    }
	 }
	 if (length($add_downstream) > 0) {
	    if ($forward == 1) {
	       $row[2] = &ModifyStart($row[2], $add_downstream);
	       $row[3] = &ModifyEnd($row[3], $add_downstream);
	    } else {
	       $row[2] = &ModifyStart($row[2], -$add_downstream);
	       $row[3] = &ModifyEnd($row[3], -$add_downstream);
	    }
	 } elsif (length($add_column_upstream) > 0) {
	    if ($forward == 1) {
	       $row[2] = &ModifyStart($row[2], -$row[$add_column_upstream]);
	       $row[3] = &ModifyEnd($row[3], -$row[$add_column_upstream]);
	    } else {
	       $row[2] = &ModifyStart($row[2], $row[$add_column_upstream]);
	       $row[3] = &ModifyEnd($row[3], $row[$add_column_upstream]);
	    }
	 } elsif (length($add_column_downstream) > 0) {
	    if ($forward == 1) {
	       $row[2] = &ModifyStart($row[2], $row[$add_column_downstream]);
	       $row[3] = &ModifyEnd($row[3], $row[$add_column_downstream]);
	    } else {
	       $row[2] = &ModifyStart($row[2], -$row[$add_column_downstream]);
	       $row[3] = &ModifyEnd($row[3], -$row[$add_column_downstream]);
	    }
	 } elsif (length($boundary_column_upstream) > 0) {
	    if ($forward == 1) {
	       if (($modify_type eq "Both" or $modify_type eq "Start") and $row[2] < $row[$boundary_column_upstream]) {
		  $row[2] = $row[$boundary_column_upstream];
	       }
	       if (($modify_type eq "Both" or $modify_type eq "End") and $row[3] < $row[$boundary_column_upstream]) {
		  $row[3] = $row[$boundary_column_upstream];
	       }
	    } else {
	       if (($modify_type eq "Both" or $modify_type eq "Start") and $row[2] > $row[$boundary_column_upstream]) {
		  $row[2] = $row[$boundary_column_upstream];
	       }
	       if (($modify_type eq "Both" or $modify_type eq "End") and $row[3] > $row[$boundary_column_upstream]) {
		  $row[3] = $row[$boundary_column_upstream];
	       }
	    }
	 } elsif (length($boundary_column_downstream) > 0) {
	    if ($forward == 1) {
	       if (($modify_type eq "Both" or $modify_type eq "Start") and $row[2] > $row[$boundary_column_downstream]) {
		  $row[2] = $row[$boundary_column_downstream];
	       }
	       if (($modify_type eq "Both" or $modify_type eq "End") and $row[3] > $row[$boundary_column_downstream]) {
		  $row[3] = $row[$boundary_column_downstream];
	       }
	    } else {
	       if (($modify_type eq "Both" or $modify_type eq "Start") and $row[2] < $row[$boundary_column_downstream]) {
		  $row[2] = $row[$boundary_column_downstream];
	       }
	       if (($modify_type eq "Both" or $modify_type eq "End") and $row[3] < $row[$boundary_column_downstream]) {
		  $row[3] = $row[$boundary_column_downstream];
	       }
	    }
	 } elsif ($upstream_downstream_to_start_end == 1) {
	    my $min = $row[2] < $row[3] ? $row[2] : $row[3];
	    my $max = $row[2] > $row[3] ? $row[2] : $row[3];
	    $row[2] = $min;
	    $row[3] = $max;
	 }
      }

      for (my $i = 0; $i < @row; $i++) {
	 if ($i > 0) {
	    print "\t";
	 }

	 print "$row[$i]";
      }
      print "\n";
   }
}

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub ModifyStart 
{
   my ($start, $add_number) = @_;

   my $res;

   if ($modify_type eq "Both" or $modify_type eq "Start" or $modify_type eq "Sep") {
      $res = $start + $add_number;
      if ($res <= 0 && $zero_bound == 1) {
	 $res = 1;
      }
   } else {
      $res = $start;
   }

   return $res;
}

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub ModifyEnd
{
   my ($end, $add_number) = @_;

   my $res;

   if ($modify_type eq "Both" or $modify_type eq "End" or $modify_type eq "Sep") {
      $res = $end + $add_number;
      if ($res <= 0 && $zero_bound == 1) {
	 $res = 1;
      }
   } else {
      $res = $end;
   }

   return $res;
}

__DATA__

modify_chr.pl <file>

   Modifies a chr file according to filters

   General
   =======
   -ud2se:      Convert from Upstream/Downstream representation to Start/End (i.e, lose direction information)
   -skip <num>: Skip num rows in the file (default: 0)

   Extend flanking regions
   =======================
   -t <str>:    What to modify (Start/End/Both/Sep default: Both. 
                Sep (Seperate) means add -au upstream and -ad downstream the location).

   -au <num>    Add <num> upstream to the location
   -ad <num>    Add <num> downstream to the location

   -acu <num>:  Add the number in column <num> upstream of the location
   -acd <num>:  Add the number in column <num> downstream of the location

   -bcu <num>:  Set the upstream boundary as the number in column <num>
   -bcd <num>:  Set the downstream boundary as the number in column <num>


   -zero_bound: If specified, coordinates must be positive (default: coords can be negative).

   Filter entries by their start position
   ======================================

   *  This option excludes the "Extend flanking regions" option.

   Prerequisite: chr is sorted by: col1 && min(col3,col4)

   -res <num>:            Resolution to filter by (step size).

   -res_mode <0/1>:       The selection strategy with respect to the resolution. (default: mode 1)

                          mode 0:     starting at the first feature, select only probes 
                                      with indices that are multiplicities of the resolution.
                          mode 1:     starting at the first feature, greedily select the next probe 
                                      in the order: start+res, start+res-1, start+res+1, start+res-2 ...

   -strand_mode <1/-1/0>: Filter by feature strandness (default: mode 0).

                          mode 1:     Pass only features on the + strand.
                          mode -1:    Pass only features on the - strand ('"-1"' in command line).
                          mode 0:     Pass features on the both strands (taking min(start,end) as the start position).
