#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

# =============================================================================
# Main part
# =============================================================================

if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit(1);
}

# reading input
my $distance_file = $ARGV[0];
if (length($distance_file) < 1 or $distance_file =~ /^-/) {
  my $file_ref = \*STDIN;

  open(OUT, ">tmp_distances_$$.tab") or die "cannot create distance file\n";
  while (<$file_ref>) {
    chomp $_;
    print OUT "$_\n";
  }
  close(OUT);
  $distance_file = "tmp_distances_$$.tab";
}
else {
  shift(@ARGV);
}

my %args = load_args(\@ARGV);
my $clusters = get_arg("clusters", 1, \%args);
my $percentile = get_arg("percent", 1, \%args);
my $diff = get_arg("diff", 0, \%args);
my $tree = get_arg("tree", 0, \%args);
my $linkage_method = get_arg("link", "MaxLinkage", \%args);
if ($linkage_method eq "min") {
  $linkage_method = "MinLinkage";
}
elsif ($linkage_method eq "avg") {
  $linkage_method = "AverageLinkage";
}


# running clustering
print STDERR "Clustering ...\n";
clustering($clusters, $percentile, $linkage_method, $distance_file, "tmp_output_$$.tab");
print STDERR "Done.\n";


# collecting results
print STDERR "Collecting results ...\n";

my $count = 0;
open(CLUSTERS, "tmp_output_$$.tab") or die "cannot read clustering results\n";
while (<CLUSTERS>) {
  chomp $_;
  my ($cluster_id, $cluster_score, $parent_id, $parent_score, $diff_score, $n_leaves, @member_ids) = split("\t", $_);

  if ($tree) {
    my $name = "-";
    if ($n_leaves == 1) {
      $name = $member_ids[0];
    }
    print "$cluster_id\t$parent_id\t$cluster_score\t$name\n";
    $count++;
  }
  elsif ($n_leaves > 1) {
    my $members = join(";", @member_ids);
    if ($diff) {
      my $d = $parent_score - $cluster_score;
      print "$cluster_id\t$n_leaves\t$cluster_score\t$d\t$members\n";
    }
    else {
      print "$cluster_id\t$n_leaves\t$cluster_score\t$members\n";
    }
    $count++;
  }
}
close(CLUSTERS);
print STDERR "Done. $count clusters created.\n";

system("/bin/rm tmp_*_$$.tab;");




# =============================================================================
# Subroutines
# =============================================================================
# -----------------------------------------------------------------------------
# clustering
# -----------------------------------------------------------------------------
sub clustering($$$$) {
  my ($num_clusters, $percentile, $linkage_method, $distance_file, $output) = @_;

  open(XML, ">clustering_xml_$$.map") or die "cannot create xml file\n";
  print XML "<?xml version=\"1.0\"?>\n\n";
  print XML "<MAP>\n";
  print XML "  <RunVec>\n";
  print XML "    <Run Name=\"Cluster\" Logger=\"logger.log\">\n";
  print XML "      <Step Type=\"LoadGeneGraph\"\n";
  print XML "            Name=\"LoadGeneGraph\"\n";
  print XML "            GeneGraphName=\"gene_graph\"\n";
  print XML "            File=\"$distance_file\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"Clustering\"\n";
  print XML "            Name=\"Cluster\"\n";
  print XML "            GeneGraphName=\"gene_graph\"\n";
  print XML "            NumClusters=\"$num_clusters\"\n";
  print XML "            LinkageMethod=\"$linkage_method\"\n";
  print XML "            LinkagePercent=\"$percentile\"\n";
  print XML "            Method=\"Hierarchical\"\n";
  print XML "            MaxMergesPerNode=\"20\"\n";
  print XML "  	         OutputFile=\"$output\">\n";
  print XML "      </Step>\n";
  print XML "    </Run>\n";
  print XML "  </RunVec>\n";
  print XML "</MAP>\n";
  close(XML);

 system("map_learn clustering_xml_$$.map; /bin/rm clustering_xml_$$.map logger.log;");
}


# ------------------------------------------------------------
# Help message
# ------------------------------------------------------------
__DATA__

cluster_tus.pl <file> [options]

Given a file in the format <ID1> <ID2> <p-value> representing
the p-value distances between every two IDs, uses Hierarchical
clustering to create clusters of TUs.

Output format: <Cluster_ID> <n_elements> <score> <ID1;ID2;...IDN>

Where score is the maximal distance between two elements in the cluster.

Parameters:
  -link [max|min|avg]  Linkage method [Default: max]
  -percent <num>       % of the distances between elements in two
                       clusters that are considered when calculating
                       the distance between the clusters
                       [Default: 1 (i.e. 100%)].
  -clusters <num>      Minimal number of high level clusters [Default: 1].
  -diff                Print the difference between cluster score and
                       parent cluster score.
  -tree                Print the tree structure in the format [id] [pid] [dist]
