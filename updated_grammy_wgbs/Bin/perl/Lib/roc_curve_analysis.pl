#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
#require "$ENV{PERL_HOME}/Lib/format_number.pl";
#require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

(@ARGV > 0) or die("How about passing some parameters????\n");

my $arg_matrix_file = get_arg("m", "", \%args);
my $arg_matrix_in_rows = get_arg("r", 0, \%args);
my $arg_calc_auc_without_figures = get_arg("auc", 0, \%args);
my $arg_legend_file = get_arg("l", "", \%args);
my $arg_fig_title = get_arg("t", "ROC curve", \%args);
my $arg_fig_file_name = get_arg("fig", "roc_curve", \%args);
my $arg_fig_file_format = get_arg("figmat", "jpg", \%args);
my $arg_group1 = get_arg("g1", "", \%args);
my $arg_group2 = get_arg("g2", "", \%args);
my $arg_group3 = get_arg("g3", "", \%args);
my $arg_group4 = get_arg("g4", "", \%args);
my $arg_group5 = get_arg("g5", "", \%args);

open(TMP, $arg_matrix_file) or die("Could not open the matrix file '$arg_matrix_file'.\n");
close(TMP);
open(TMP1, $arg_legend_file) or die("Could not open the legend file '$arg_legend_file'.\n");
close(TMP1);

my $params = "(\'$arg_matrix_file\', $arg_matrix_in_rows, \'$arg_legend_file\', $arg_calc_auc_without_figures, \'$arg_fig_title\', \'$arg_fig_file_name\', \'$arg_fig_file_format\', \'$arg_group1\', \'$arg_group2\', \'$arg_group3\', \'$arg_group4\', \'$arg_group5\')";

my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
my $mfile = "roc_curve_analysis";
my $matlabPath = "matlab";

my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";

print STDERR "Calling Matlab with: $command\n";

my $run_matlab = system ($command);

while ($run_matlab != 0)
{
   sleep 10;
   $run_matlab = system ($command);
}
sleep 10;

#
#      ** notice that you can give the matrix as the transpose of the above description using the'-r' flag. **
#

__DATA__

Syntax:

    roc_curve_analysis.pl -m <matrix.tab> -l <legend.tab>

Description:

    Calculate and plot ROC curves (Receiver Operating Characteristic) and AUC values (Area Under the roc Curve).

Input:

    A matrix <matrix.tab> with 2 columns per tested method: <L1><\t><S1><\t>...<\t><Ln><\t><Sn>

      L: The lable of the data point, '1' and '0' for the positive and negative sets, respectively.
      S: The score of the data point (a good score gives the 'positive' data points high scores).

    A legend <legend.tab> file: <N1><\n>...<\n><Nn>

      N is the name of the scoring method used in the plots.

Output:

    Figures of ROC curves with their AUC values:

      (1) All ROC curves (16 subplots in a figure).
      (2) ROC curves for groups of selected scoring methods (up to 5 such groups - using the '-g1'...'-g5' flags)

    AUC mode: calculate AUC (without figures) for many scoring methods into a file 'xxx.tab' use
    '-m m.tab -l l.tab -fig xxx.tab -auc -r'.

Flags:

    -m <matrix.tab>             The column matrix of Labels and Scores (see above).

    -r                          Declare that the matrix is given as transposed to the above description,
                                i.e., by rows instead of columns (default: by columns).
                                ** notice that in this mode we do not load the matrix at once, but rather the rows for
                                each scoring method one at a time and save much memory, especially in '-auc' mode **

    -l <legend.tab>             The list of Names for the scoring methods (see above).

    -fig <str>                  The file template name for the figures (default: 'roc_curve')

    -figmat <fm>                The figure file format (default: 'jpg')
                                <fm> = ai/bmp/emf/eps/fig/jpg/m/pbm/pcx/pgm/png/ppm/tif

    -auc                        Calculate AUC values and print into a file (specify file name using '-fig').
                                In this mode **no figures** are being generated.

    -t <str>                    The title for the (groups) figures (default: "ROC curve")

    -g1 <str>                   The vector of scoring methods indices (rank in <legend.tab>) to plot their
                                ROC curves together, given in Matlab syntax (default: no such figure).
                                E.g., -g1 '[1:4 14 6]' for ploting together methods 1 2 3 4 14 6.

    -g2  ... -g5                Same as '-g1'. Currently only 5 groups are supported.

