#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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

my $kmeans_arg_num_of_clusters = get_arg("k", "2", \%args);
my $kmeans_arg_distance = get_arg("dist", "correlation", \%args);
my $kmeans_arg_start = get_arg("start", "sample", \%args);
my $kmeans_arg_replicates = get_arg("rep", 5, \%args);
my $kmeans_arg_maxiter = get_arg("maxiter", 100, \%args);
my $kmeans_arg_emptyaction = get_arg("emptyaction", "drop", \%args);
my $kmeans_arg_figure_name = get_arg("fig", "cluster_rows_kmeans_figure", \%args);
my $kmeans_arg_figure_format = get_arg("figmat", "png", \%args);

my $r = int(rand(1000000));
my $matrix_for_matlab_file_name = "tmp_cluster_rows_kmeans_mat_" . "$r";
my $result_file_name = "tmp_cluster_rows_kmeans_res_" . "$r";
open(MATRIX_FOR_MATLAB, ">$matrix_for_matlab_file_name") or die("Could not open a temporary file for writing: '$matrix_for_matlab_file_name'.\n");
open(RESULT, ">$result_file_name") or die("Could not open a temporary file for writing: '$result_file_name'.\n");

my $tmp_row = <$matrix_file_ref>;
chomp($tmp_row);
my @r = split(/\t/,$tmp_row,2);
my $header_row = $r[1];

while($tmp_row = <$matrix_file_ref>)
{
  chomp($tmp_row);
  @r = split(/\t/,$tmp_row,2);
  print MATRIX_FOR_MATLAB "$r[1]\n";
  print RESULT "$r[0]\n";
}

close(MATRIX_FOR_MATLAB);
close(RESULT);

my $kmeans_arg_matrix_file_name = "$matrix_for_matlab_file_name";
my $kmeans_arg_output_file_name = "tmp_cluster_rows_kmeans_out" . "$r";

my $params = "(\'$kmeans_arg_matrix_file_name\',$kmeans_arg_num_of_clusters,\'$kmeans_arg_distance\',\'$kmeans_arg_start\',$kmeans_arg_replicates,$kmeans_arg_maxiter,\'$kmeans_arg_emptyaction\',\'$kmeans_arg_figure_name\',\'$kmeans_arg_figure_format\',\'$kmeans_arg_output_file_name\')";

my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
my $mfile = "cluster_rows_kmeans";
my $matlabPath = "matlab";

my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";

print STDERR "Calling Matlab with: $command\n";

system ($command) == 0 || die "Failed to run Matlab\n";

my $str = `paste $result_file_name $kmeans_arg_output_file_name`;

my @lines = split(/\n/,$str);
for(my $i=0; $i < @lines; $i++)
{
  my $line = $lines[$i];
  chomp($line);
  print STDOUT "$line\n";
}

system ("rm $matrix_for_matlab_file_name $result_file_name $kmeans_arg_output_file_name");

__DATA__

Syntax:
    
    cluster_rows_kmeans.pl <file_name>

Description:

    Run k-means clustering on the rows of <file_name>, assuming the format is a tab delimited matrix, 
    with one row header and one column header. Save a figure that includes all clusters profiles,
    and output (STDOUT) the list of cluster assignments with respect to the column header.
    IMPORTANT! assumes a full matrix, with no empty entries.
    See Matlab help on "kmeans.m" for more information on parameter settings.

Output: 
    
    <row_id><\t><cluster_number>

Flags:
    
    -k               The number of clusters (default = 2)

    -dist <d>        The distance function to use, where <d> = 

                       correlation/sqEuclidean/cityblock/cosine/Hamming (defualt = correlation)

    -start <s>       The starting choice of the clusters' centroids (the "seeds"), where <s> = 

                       sample/uniform/cluster (default = sample)

    -rep <int>       The number of replicated runs (default = 5)

    -maxiter <int>   The maximum number of iterations for a run (default = 100)

    -emptyaction <e> The action to take when a cluster gets "empty", where <e> =

                       drop/error/singleton (default = drop, i.e. reduce k by one)

    -fig <str>       The file name for the figure (default = cluster_rows_kmeans_figure)

    -figmat <fm>     The figure file format, where <fm> = 

                       ai/bmp/emf/eps/fig/jpg/m/pbm/pcx/pgm/png/ppm/tif (default = png)

