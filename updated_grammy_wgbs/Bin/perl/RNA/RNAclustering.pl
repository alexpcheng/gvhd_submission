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

# creating work directory
my $rc = `mkdir clustering_$$`;
if ($? != 0) {
  die "cannot create working directory\n\n";
}
chdir("clustering_$$");

my $distance_file = $ARGV[0];
if (length($distance_file) < 1 or $distance_file =~ /^-/) {
  my $file_ref = \*STDIN;

  open(OUT, ">tmp_distance.tab") or die "cannot create distance file\n";
  while (<$file_ref>) {
    chomp $_;
    print OUT "$_\n";
  }
  close(OUT);
  $distance_file = "tmp_distance.tab";
}
else {
  shift(@ARGV);
  $distance_file = "../".$distance_file;
}

my %args = load_args(\@ARGV);
my $output_file = get_arg("out", "high_level_clusters.tab", \%args);
my $motif_file = get_arg("clusters", "", \%args);
my $percentile = get_arg("percent", 1, \%args);
my $linkage_method = get_arg("link", "MaxLinkage", \%args);
if ($linkage_method eq "min") {
  $linkage_method = "MinLinkage";
}
elsif ($linkage_method eq "avg") {
  $linkage_method = "AverageLinkage";
}
else {
  $linkage_method = "MaxLinkage";
}
my $use_file = get_arg("use_file", 0, \%args);
my $use_chr = get_arg("use_chr", 0, \%args);
print "$use_file\t$use_chr\n";

# running clustering
if ($motif_file ne "") {
  RNAclustering($distance_file, $motif_file, $linkage_method, $percentile, $output_file, "", $use_file, $use_chr);
}
else {
  RNAclustering($distance_file, "", $linkage_method, $percentile, "", "", $use_file, $use_chr);
}


# move relevant files and then delete work directory
chdir("../");

if ($motif_file ne "") {
  `mv clustering_$$/$output_file .`;
  if ($? != 0) {
    die "Cannot create output file\n";
  }
}

`rm -rf clustering_$$/`;
if ($? != 0) {
  die "Cannot delete working directory \n";
}




# =============================================================================
# Subroutines
# =============================================================================

# -----------------------------------------------------------------------------
# RNAclustering(distance_file, motif_file, linkage_method, percentile, high_level_file, output_file, use_file, use_chr)
#
# Cluster RNA motifs using the given distance file and print the clusters.
# -----------------------------------------------------------------------------
sub RNAclustering($$$$$) {
  my ($distance_file, $motif_file, $linkage_method, $percentile, $high_level_file, $output_file, $use_file, $use_chr) = @_;

  my $line_count = 0;
  my $high_level = (($motif_file ne "") and ($high_level_file ne ""));
  my $out_ref = \*STDOUT;
  if ($output_file ne "") {
    open(FILE, ">$output_file") or die "cannot open $output_file\n";
    $out_ref = \*FILE;
  }

  # running clustering
  create_clustering_xml("clustering", $percentile, $linkage_method, "$distance_file", $use_file, $use_chr);
  $rc = `map_learn clustering.map`;
  print "$rc\n\n";

  # collecting results
  print STDERR "Collecting results ...\n";

  # reading motif sequences
  my %motifs;
  if ($high_level) {
    open(MOTIF, "../$motif_file") or die "cannot read $motif_file\n";

    while (<MOTIF>) {
      chomp;
      my ($id, @seq) = split("\t",$_);
      $motifs{$id} = \@seq;
    }
    close(MOTIF);
  }

  # reading clustering output
  my $n = 0;
  open(CLUSTERS, "clustering.out") or die "cannot read clustering results\n\n";
  if ($high_level) {
    open(OUT, ">$high_level_file") or die "cannot create clustering results output file $high_level_file\n\n";
  }

  # creating a chr file for each cluster of size > 1
  while (<CLUSTERS>) {
    my $line = $_;
    chomp($line);

    my ($cluster_id, $cluster_score, $parent_id, $parent_score, $diff_score, $n_leaves, @motif_ids) = split("\t", $line);
    print $out_ref "$cluster_id\t$cluster_score\t$parent_id\t$parent_score\t$diff_score\t$n_leaves";
    foreach my $m (@motif_ids) {
      print $out_ref "\t$m";
    }
    print $out_ref "\n";
    $line_count++;

    # high level clusters (no parent for the cluster)
    if (($high_level) and ($parent_score eq "**")) {
      print OUT "$cluster_id";

      foreach my $m (@motif_ids) {
	my $ref = $motifs{$m};
	my $str = join("\t", @$ref);
	print OUT "\t$str";
      }
      $n++;
      print OUT "\n";
    }
  }
  close(CLUSTERS);

  if ($high_level) {
    close(OUT);
    print STDERR "Total: $n high level clusters were written to file\n";
  }
}




# -----------------------------------------------------------------------------
# creating xml file
# -----------------------------------------------------------------------------
sub create_clustering_xml($$$$) {
  my ($name, $percentile, $linkage_method, $distance_file, $use_file, $use_chr) = @_;

  open(XML, ">$name.map") or die "cannot create $name.map \n";
  print XML "<?xml version=\"1.0\"?>\n\n";
  print XML "<MAP>\n";
  print XML "  <RunVec>\n";
  print XML "    <Run Name=\"Cluster\" Logger=\"$name.log\">\n";
  print XML "      <Step Type=\"LoadGeneGraph\"\n";
  print XML "            Name=\"LoadGeneGraph\"\n";
  print XML "            GeneGraphName=\"gene_graph\"\n";
  if ($use_file) {
    print XML "            UseFileGeneGraph=\"TRUE\"\n";
  }
  if ($use_chr) {
    print XML "            FileType=\"Char\"\n";
  }
  print XML "            File=\"$distance_file\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"Clustering\"\n";
  print XML "            Name=\"Cluster\"\n";
  print XML "            GeneGraphName=\"gene_graph\"\n";
  print XML "            NumClusters=\"1\"\n";
  print XML "            LinkageMethod=\"$linkage_method\"\n";
  print XML "            LinkagePercent=\"$percentile\"\n";
  print XML "            Method=\"Hierarchical\"\n";
  print XML "            MaxMergesPerNode=\"20\"\n";
  print XML "  	         OutputFile=\"$name.out\">\n";
  print XML "      </Step>\n";
  print XML "    </Run>\n";
  print XML "  </RunVec>\n";
  print XML "</MAP>\n";
  close(XML);
}


# ------------------------------------------------------------
# Help message
# ------------------------------------------------------------
__DATA__

RNAclustering.pl <distance_file> [options]

Cluster RNA motifs using the given distance file and print the clusters.
Distance file format: [motif id] [motif id] [distance]

The output of this program is a file containing the clusters in the format:
[cluster id] [score] [parent id] [parent score] [score diff] [number of motifs] [motif ids]

Options:
  -clusters <motif_file>   Create another output file with the high level clusters and the
                           motifs in each of those clusters.
                           The <motif_file> specifiy motifs in the format : [motif id] [motif]
  -out <output_file>       high level cluster's output file name [Default: high_level_clusters.tab]
  -link [max|min|avg]      Linkage method for clustering [Default: max]
  -percent <num>           Linkage percent for clustering, represents the % of the distances between
                           clusters that are considered relevant for clustering [Default: 1 (i.e. 100%)].
  -use_file                Use file in the clustering algorithm or save all data in memory
                           Use only for large data sets.
  -use_chr                 File created by the clustering algorithm will use char instead of double
