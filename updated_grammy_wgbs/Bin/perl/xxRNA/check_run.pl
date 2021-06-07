#!/usr/bin/perl
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my $WC_DIR = "wc";
my $RUNNING_LOG = "check_run_log.txt";

my %args = load_args(\@ARGV);
my $stage = get_arg("s", 0, \%args);
my $ok = get_arg("ok", 0, \%args);
my $fail = get_arg("f", 0, \%args);
my $mega_fail = get_arg("mf", 0, \%args);
my $num_mega_fail = get_arg("n", 10, \%args);
my $report_file = get_arg("r", 0, \%args);
my $output_file = get_arg("o", 0, \%args);


open(RFILE, ">>$report_file");
open(OFILE, ">$output_file");
open(OFILEB, ">post_$output_file");

my @features = split(/\n/, `ls Features | cut -d "." -f 1`);
my $align_features = ";010;040;041;050;051;eof";
my $expected_count = `cat tu_filtered.ref | wc -l`;
chomp ($expected_count);
my $expected_dist = $expected_count*($expected_count-1)/2;
my $expected_files_count = 2 ** scalar(@features);
my $command_ok = 1;
my $now_string = `date`; #gmtime();

# if already run more than $num_mega_fail times -- exit
my $log_count = `wc -l $RUNNING_LOG`;
if ($?) {
  $log_count = 0;
}
if ($log_count > $num_mega_fail) {

  print RFILE "$now_string\n";
  print RFILE "-----------------------------------------------------------\n";
  print RFILE " Problem!!! Mega fail $stage\n";
  print RFILE "-----------------------------------------------------------\n\n\n";
  print "$mega_fail\n";
  exit;
}

# Features
if ($stage eq "features") {

  print RFILE "$now_string\n";
  print RFILE "-----------------------------------------------------------\n";
  print RFILE "Features (attempt $log_count): \n";
  print RFILE " Expect $expected_count features per file\n";

  foreach my $f (@features) {
    my $count = `cat $WC_DIR/Features-$f.tab`;
    chomp ($count);
    if ($? or $count != $expected_count) {
      print RFILE " Problem! Feature $f -- $count lines\n";
      print OFILE "q.pl make feature_$f\n;";
      $command_ok = 0;
    }
  }
}


# Distances
elsif ($stage eq "distances") {

  print RFILE "$now_string\n";
  print RFILE "-----------------------------------------------------------\n";
  print RFILE "Distances (attempt $log_count):\n";
  print RFILE " Expect $expected_dist distances per file\n";

  my $merge = 0;
  foreach my $f (@features) {

    my $count = `cat $WC_DIR/Distances-$f.tab`;
    chomp ($count);
    if ($? or $count != $expected_dist) {
      print RFILE " Problem! Distance $f -- $count lines\n";
      $command_ok = 0;

      if ($align_features =~ m/;$f;/g) {
	my @dirs = split(/\n/, `ls Parallel_$f | cut -d "_" -f 2-`);
	foreach my $d (@dirs) {

	  my $count_dir = `cat $WC_DIR/Parallel_$f-part_$d-dist_$f.tab`;
	  chomp ($count_dir);
	  if ($? or $count_dir <= 0) {
	    print RFILE " Problem! Distance $f/part_$d  -- $count_dir lines\n";
	    if ($d =~ m/_/g) {
	      print OFILE "cd Parallel_$f/part_$d; ".
		          "q.pl make distances_$f comp=\\\"-c1 Parallel_$f/part_$d/$f.tab.co\\\" fpath=Parallel_$f/part_$d/ dpath=Parallel_$f/part_$d/dist_;\n";
	    }
	    else {
	      print OFILE "cd Parallel_$f/part_$d; ".
		          "q.pl make distances_$f fpath=Parallel_$f/part_$d/ dpath=Parallel_$f/part_$d/dist_;\n";
	    }
	  }
	}
	$merge = 1;
      }
      else {
	print OFILE "q.pl make distances_$f;\n";
      }
    }
  }

  if ($merge) {
    print OFILEB "make all_distances_merge\n";
  }
  else {
    print OFILEB "echo \\\"Nothing to do\\\"\n";
  }
}


# Normdist
elsif ($stage eq "normdist") {

  print RFILE "$now_string\n";
  print RFILE "-----------------------------------------------------------\n";
  print RFILE "Normdist (attempt $log_count):\n";
  print RFILE " Expect $expected_dist normalized distances per file\n";

  foreach my $f (@features) {
    my $count = `cat $WC_DIR/Normdist-$f.tab`;
    chomp ($count);
    if ($? or $count != $expected_dist) {
      print RFILE " Problem! Normdist $f -- $count lines\n";
      print OFILE "q.pl make normdist feature=$f;\n";
      $command_ok = 0;
    }
  }
}


# Pvalues
elsif ($stage eq "pvalues") {

  print RFILE "$now_string\n";
  print RFILE "-----------------------------------------------------------\n";
  print RFILE "Pvalues (attempt $log_count):\n";
  print RFILE " Expect $expected_dist pvalues per file\n";

  foreach my $f (@features) {
    my $count = `cat $WC_DIR/Pvalues-$f.tab`;
    chomp ($count);
    if ($? or $count != $expected_dist) {
      print RFILE " Problem! Pvalues $f -- $count lines\n";
      print OFILE "q.pl make pvalues feature=$f;\n";
      $command_ok = 0;
    }
  }
}


# Combined
elsif ($stage eq "combined") {

  print RFILE "$now_string\n";
  print RFILE "-----------------------------------------------------------\n";
  print RFILE "Combined (attempt $log_count):\n";
  print RFILE " Expect $expected_dist combined pvalues per file\n";
  print RFILE " Expect $expected_files_count combined pvalues files\n";

  my @files = features_powerset();
  foreach my $f (@files) {
    my $count = `cat $WC_DIR/Combined-$f.tab`;
    chomp ($count);
    if ($? or $count != $expected_dist) {
      print RFILE " Problem! Combined $f -- ";
      print RFILE ( ($?) ? "missing\n" : "$count lines\n" );
      my $infile = $f;
      $infile =~ s/_/\.tab,/g;
      $infile = $infile.".tab";
      print OFILE "q.pl make combined_func infiles=$infile outfile=$f;";
      $command_ok = 0;
    }
  }
}


# Clustering
elsif ($stage eq "clustering") {

  print RFILE "$now_string\n";
  print RFILE "-----------------------------------------------------------\n";
  print RFILE "Clustering (attempt $log_count):\n";
  print RFILE " Expect $expected_files_count clustering files\n";

  my @files = features_powerset();
  foreach my $f (@files) {
    my $count = `cat $WC_DIR/Clusters-$f.tab`;
    chomp ($count);
    if ($? or $count <= 0) {
      print RFILE " Problem! Cluster $f -- $count lines\n";
      print OFILE "q.pl make matlab_clustering feature=$f;\n";
      $command_ok = 0;
    }
  }
}


# Filtered Clusters
elsif ($stage eq "filterclusters") {
  print RFILE "$now_string\n";
  print RFILE "-----------------------------------------------------------\n";
  print RFILE "Filtered Clusters (attempt $log_count):\n";
  print RFILE " Expect $expected_files_count Filtered clusters files\n";

  my @files = features_powerset();
  foreach my $f (@files) {
    my $count = `cat $WC_DIR/FilteredClusters-$f.tab`;
    chomp ($count);
    if ($? or $count <= 0) {
      print RFILE " Problem! FilteredCluster $f -- $count lines\n";
      print OFILE "q.pl make filter_clusters c=$f;\n";
      $command_ok = 0;
    }
  }
}


# Before we're done
if ($command_ok) {
  print RFILE " Succeeded!\n";
  print RFILE "-----------------------------------------------------------\n\n\n";

  print "$ok\n";
}
else {
  print RFILE "-----------------------------------------------------------\n\n\n";

  print "$fail\n";
}

close(RFILE);
close(OFILE);
close(OFILEB);





# ------------------------------------------------------------------------
# Powerset
# ------------------------------------------------------------------------
sub features_powerset() {
  my @filter_a = ("021", "021", "022", "050", "030", "040", "040", "041");
  my @filter_b = ("022", "023", "023", "051", "031", "041", "042", "042");

  my $cmd = "ls Features | cut -d \".\" -f 1 | powerset.pl -delim \"_\" | cut -f 2";
  for(my $i = 0; $i < scalar(@filter_a); $i++) {
    $cmd = $cmd."| grep -v -P \"$filter_a[$i].+$filter_b[$i]\" | grep -v -P \"$filter_b[$i].+$filter_a[$i]\"";
  }
  my @powerset = split(/\n/, `$cmd`);

  return @powerset;
}


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__
check_run.pl

Check the results of a specific xxRNA running stage.
Print as output the next command.

OPTIONS:
  -s <name>  Stage name (features, distances, pvalues, normdist, combine, clustering, filterclusters)
  -ok <str>  Command to output if stange succeeded
  -f  <str>  Command to output if stage failed
  -mf <str>  Command to output in case of "mega fail", i.e., failed more than
             the suggested number of times.
  -n <num>   Number of repeats before "mega fail" (default: 10).
  -r <file>  Report file
  -o <file>  Output file (rerun commands)
