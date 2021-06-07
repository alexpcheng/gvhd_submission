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

my $arg_plot_mean = get_arg("pmean", 0, \%args);
my $arg_plot_std = get_arg("pstd", 0, \%args);

my $arg_plot_ylim_min = get_arg("pylim_min", "", \%args);
my $arg_plot_ylim_max = get_arg("pylim_max", "", \%args);

my $arg_plot_xlabel = get_arg("xlabel", "", \%args);
my $arg_plot_ylabel = get_arg("ylabel", "", \%args);

my $arg_plot_line_width = get_arg("lw", 1, \%args);

my $arg_plot_smooth_window_size = get_arg("sm", 1, \%args);

my $arg_plot_symbol = get_arg("s", "", \%args);

my $arg_plot_x_vec = get_arg("xvec", "", \%args);

my $arg_image_mean = get_arg("imean", 0, \%args);
my $arg_image_all = get_arg("iall", 0, \%args);
my $arg_title1 = get_arg("t", "Here should be a title...", \%args);
my $arg_title2 = get_arg("t2", "", \%args);

my $arg_title = "";

if (length($arg_title2) > 0)
{
   $arg_title = "{\'\'$arg_title1\'\' \'\'$arg_title2\'\'}";
}
else
{
   $arg_title = "{\'\'$arg_title1\'\'}";
}

my $arg_figure_name = get_arg("fig", "figure", \%args);
my $arg_figure_format = get_arg("figmat", "png", \%args);

my $r = int(rand(1000000));
my $matrix_for_matlab_file_name = "tmp_figure_mat_" . "$r";
open(MATRIX_FOR_MATLAB, ">$matrix_for_matlab_file_name") or die("Could not open a temporary file for writing: '$matrix_for_matlab_file_name'.\n");

my $tmp_row = <$matrix_file_ref>;
chomp($tmp_row);
my @r;
my $header_row;

if (length($tmp_row) > 0)
{
   @r = split(/\t/,$tmp_row,2);
   $header_row = $r[1];
}

while($tmp_row = <$matrix_file_ref>)
{
  chomp($tmp_row);
  @r = split(/\t/,$tmp_row,2);
  print MATRIX_FOR_MATLAB "$r[1]\n";
}

close(MATRIX_FOR_MATLAB);

my $arg_matrix_file_name = "$matrix_for_matlab_file_name";

my $validate_non_empty_matrix = `cat $matrix_for_matlab_file_name | body.pl 2 -1 | cut.pl -f 1 | lin.pl | tail -n 1 | cut.pl -f 1`;

if ((length($validate_non_empty_matrix) == 0) or ($validate_non_empty_matrix < 1))
{
   print STDERR "WARNING: make_matlab_matrix_plot: empty matrix.\n";
   system ("rm $matrix_for_matlab_file_name");
   exit;
}


my $params;
if ((length($arg_plot_ylim_max) > 0) and (length($arg_plot_ylim_min) > 0))
{
   if (length($arg_plot_symbol) > 0)
   {
      if (length($arg_plot_x_vec) > 0)
      {
	 $params = "(\'$arg_matrix_file_name\',$arg_plot_mean,$arg_plot_std,$arg_image_mean,$arg_image_all,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',$arg_plot_ylim_min,$arg_plot_ylim_max, \'$arg_plot_xlabel\', \'$arg_plot_ylabel\', \'$arg_plot_symbol\', \'$arg_plot_x_vec\', $arg_plot_line_width, $arg_plot_smooth_window_size)";
      }
      else
      {
	 $params = "(\'$arg_matrix_file_name\',$arg_plot_mean,$arg_plot_std,$arg_image_mean,$arg_image_all,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',$arg_plot_ylim_min,$arg_plot_ylim_max, \'$arg_plot_xlabel\', \'$arg_plot_ylabel\', \'$arg_plot_symbol\', \'\', $arg_plot_line_width, $arg_plot_smooth_window_size)";
      }
   }
   else
   {
      if (length($arg_plot_x_vec) > 0)
      {
	 $params = "(\'$arg_matrix_file_name\',$arg_plot_mean,$arg_plot_std,$arg_image_mean,$arg_image_all,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',$arg_plot_ylim_min,$arg_plot_ylim_max, \'$arg_plot_xlabel\', \'$arg_plot_ylabel\', \'\', \'$arg_plot_x_vec\', $arg_plot_line_width, $arg_plot_smooth_window_size)";
      }
      else
      {
	 $params = "(\'$arg_matrix_file_name\',$arg_plot_mean,$arg_plot_std,$arg_image_mean,$arg_image_all,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',$arg_plot_ylim_min,$arg_plot_ylim_max, \'$arg_plot_xlabel\', \'$arg_plot_ylabel\', \'\', \'\', $arg_plot_line_width, $arg_plot_smooth_window_size)";
      }
   }
}
else
{
   if (length($arg_plot_symbol) > 0)
   {
      if (length($arg_plot_x_vec) > 0)
      {
	 $params = "(\'$arg_matrix_file_name\',$arg_plot_mean,$arg_plot_std,$arg_image_mean,$arg_image_all,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'\',\'\', \'$arg_plot_xlabel\', \'$arg_plot_ylabel\', \'$arg_plot_symbol\', \'$arg_plot_x_vec\', $arg_plot_line_width, $arg_plot_smooth_window_size)";
      }
      else
      {
	 $params = "(\'$arg_matrix_file_name\',$arg_plot_mean,$arg_plot_std,$arg_image_mean,$arg_image_all,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'\',\'\', \'$arg_plot_xlabel\', \'$arg_plot_ylabel\', \'$arg_plot_symbol\', \'\', $arg_plot_line_width, $arg_plot_smooth_window_size)";
      }

   }
   else
   {
      if (length($arg_plot_x_vec) > 0)
      {
	 $params = "(\'$arg_matrix_file_name\',$arg_plot_mean,$arg_plot_std,$arg_image_mean,$arg_image_all,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'\',\'\', \'$arg_plot_xlabel\', \'$arg_plot_ylabel\', \'\', \'$arg_plot_x_vec\', $arg_plot_line_width, $arg_plot_smooth_window_size)";
      }
      else
      {
	 $params = "(\'$arg_matrix_file_name\',$arg_plot_mean,$arg_plot_std,$arg_image_mean,$arg_image_all,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'\',\'\', \'$arg_plot_xlabel\', \'$arg_plot_ylabel\', \'\', \'\', $arg_plot_line_width, $arg_plot_smooth_window_size)";
      }
   }
}

my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
my $mfile = "make_matlab_matrix_plot";
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

system ("rm $matrix_for_matlab_file_name");

__DATA__

Syntax:
    
    make_matlab_matrix_plot.pl <matrix.tab>

Description:

    Creat a figure of a matrix images/plots using Matlab.
    <matrix.tab> is a tab file, with 1 row header & 1 column header, possibly with missing data.

    See Matlab help on "make_matlab_matix_plot.m" for more information on parameter settings.

Output: 
    
    A figure.

Flags:
    
    -pmean           A Plot of the mean row profile (default: doesn't plot)

    -pstd            Add standard deviation to the mean row profile (default: only mean)

    -imean           A scaled Image of the mean row profile (default: doesn't plot)

    -iall            A scaled Image of the matrix, i.e. All rows (default: doesn't plot)

    -fig <str>       The file name for the figure (default: figure)

    -figmat <fm>     The figure file format, where <fm> =

                       ai/bmp/emf/eps/fig/jpg/m/pbm/pcx/pgm/png/ppm/tif (default: png)

    -t <str>         The title for the figure (default: "Here should be a title...")

    -xlabel <str>    The label of the X-axis (default: "")
    -ylabel <str>    The label of the Y-axis (default: "")

    -pylim_min <num> Set the Y-axis-limits (default: tight)
    -pylim_max <num> Set the Y-axis-limits (default: tight)

    -xvec <str>      The X vector to plot against (X-axis coordinates) to plot (default: plot against the indices).
                     <str> is in the Matlab syntax, e.g. [-7500:10:2450]

    -sm <int>        Smooth the data using average window of size <int> (default: 1, i.e., no smoothing)

    -s <str>         Matlab symbol for the plot command (default: no symbol)
                     Various line types, plot symbols and colors may be obtained with
                     <str> is a character string made from one element from any or all the following 3 columns:

                     b     blue          .     point              -     solid
                     g     green         o     circle             :     dotted
                     r     red           x     x-mark             -.    dashdot
                     c     cyan          +     plus               --    dashed
                     m     magenta       *     star             (none)  no line
                     y     yellow        s     square
                     k     black         d     diamond
                     w     white         v     triangle (down)
                                         ^     triangle (up)
                                         <     triangle (left)
                                         >     triangle (right)
                                         p     pentagram
                                         h     hexagram
