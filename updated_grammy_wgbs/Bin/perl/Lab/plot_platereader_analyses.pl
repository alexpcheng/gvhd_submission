#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) 
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my $arg_command = get_full_arg_command(\@ARGV);
open OUTFILE, ">>plot_commands.tab";
print OUTFILE "$0 " . get_full_arg_command(\@ARGV) . "\n";
close(OUTFILE);

my %args = load_args(\@ARGV);

my $num_plates = get_arg("p", 0, \%args);
my $plot_input_dir = get_arg("input_dir", 0, \%args);
my $plot_combined = get_arg("plot_all_combined", "", \%args);
my $plot_combined_together = get_arg("plot_all_combined_together", "", \%args);
my $plot_separate = get_arg("plot_all_separate", "", \%args);
my $plot_subset_combined = get_arg("plot_subset_combined", "", \%args);
my $plot_subset_separate = get_arg("plot_subset_separate", "", \%args);
my $plot_subset_together = get_arg("plot_subset_together", "", \%args);
my $plot_subset_average = get_arg("plot_subset_average", "", \%args);
my $plot_groupbyx_boxplot = get_arg("plot_groupbyx_boxplot", "", \%args);
my $plot_groupbyx_points = get_arg("plot_groupbyx_points", "", \%args);



#Exec("rm -f Makefile");
#Exec("ln -s /home/genie/Genie/Develop/Templates/Make/platereader_analysis.mak Makefile");
Exec("mkdir -p Plots");
Exec("mkdir -p FigureSpecs");

if ($num_plates > 0)
{
	open(OUTFILE, ">Plots.private");

	print OUTFILE "\nPLOT_FILE_IDS = ";
	for (my $i = 1; $i <= $num_plates; $i++)	
	{
  	print OUTFILE "$i ";

	  Exec("mkdir -p Plots/Plate$i");
	}
	print OUTFILE "\n\n";

	print OUTFILE "PLOT_FILE_INPUT_DIRS = ";
	for (my $i = 1; $i <= $num_plates; $i++)	
	{
  	print OUTFILE "TabData/Plate$i/*.tab ";
	}
	print OUTFILE "\n\n";

	print OUTFILE "PLOT_FILE_OUTPUT_DIRS = ";
	for (my $i = 1; $i <= $num_plates; $i++)	
	{
  	print OUTFILE "Plots/Plate$i ";
	}
	print OUTFILE "\n\n";

	close(OUTFILE);
}
else
{
	open(OUTFILE, ">Plots.private");

	print OUTFILE "\nPLOT_FILE_IDS = 1\n\n";
	print OUTFILE "PLOT_FILE_INPUT_DIRS = $plot_input_dir/*.tab\n\n";
	print OUTFILE "PLOT_FILE_OUTPUT_DIRS = Plots\n\n";

	close(OUTFILE);
}

open(OUTFILE, ">plot_params.xml");
print OUTFILE "<Figures>\n";
close(OUTFILE);

my @row = split('\,', $plot_combined);
for (my $i = 0; $i < @row; $i++)
{
  Exec("sed 's/__INPUTMATRIX__/$row[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/plot_combined_params.xml >> plot_params.xml");
}

my @row = split('\,', $plot_combined_together);
for (my $i = 0; $i < @row; $i++)
{
  Exec("sed 's/__INPUTMATRIX__/$row[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/plot_combined_together_params.xml >> plot_params.xml");
}


if (length($plot_separate) > 0)
{
  my @row = split('\,', $plot_separate);

  Exec("sed 's/__INPUTMATRIX__/$row[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/plot_separate_params.xml >> plot_params.xml");

  open(OUTFILE, ">>plot_params.xml");
  for (my $i = 0; $i < @row; $i++)
  {
    print OUTFILE "    <Plot Title=\"$row[$i] \$\$IterateFigureWellName\$\$\">\n";
    print OUTFILE "      <Curve Matrix1=\"$row[$i]\" Wells1=\"\$\$IterateFigure\$\$\"/>\n";
    print OUTFILE "    </Plot>\n";
  }
  print OUTFILE "  </Figure>\n";
  close(OUTFILE);
}

my @row = split(/\,/, $plot_subset_combined);
for (my $i = 0; $i < @row; $i++)
{
  my @dir_names_vec = split(/\//, $row[$i]);
  my @file_name_vec = split(/\./, $dir_names_vec[@dir_names_vec - 1]);

  Exec("sed 's/__SUBSET_FILE__/$file_name_vec[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/plot_subset_combined_params.xml >> plot_params.xml");

  open(OUTFILE, ">>plot_params.xml");

  open(INFILE, "<$row[$i]");
  my $line_str = <INFILE>;
  chomp $line_str;
  my @line = split(/\t/, $line_str);
  my @matrices = split(/\,/, $line[1]);
  while(<INFILE>)
  {
		chomp;
    my @line = split(/\t/);
    my @wells = split(/\,/, $line[1]);

    for (my $j = 0; $j < @matrices; $j++)
    {
      print OUTFILE "    <Plot Title=\"$line[0] $matrices[$j]\">\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line[1]\" AverageAcrossWells=\"0\" UseSameStyleForCurves=\"0\"/>\n";
 #     print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line[1]\" AverageAcrossWells=\"1\" LineWidth=\"3\"/>\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line[1]\" AverageAcrossWells=\"0\" UseSameStyleForCurves=\"0\" CurveType=\"PointMax\"/>\n";
 #     print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line[1]\" AverageAcrossWells=\"1\" CurveType=\"PointMax\"/>\n";
      print OUTFILE "    </Plot>\n";
    }
  }
  close(INFILE);

  print OUTFILE "  </Figure>\n";
  close(OUTFILE);
}

my @row = split(/\,/, $plot_subset_separate);
for (my $i = 0; $i < @row; $i++)
{
  my @dir_names_vec = split(/\//, $row[$i]);
  my @file_name_vec = split(/\./, $dir_names_vec[@dir_names_vec - 1]);

  open(INFILE, "<$row[$i]");
  my $line_str = <INFILE>;
  chomp $line_str;
  my @line = split(/\t/, $line_str);
  my @matrices = split(/\,/, $line[1]);
  while(<INFILE>)
  {
		chomp;
    my @line = split(/\t/);
    my @wells = split(/\,/, $line[1]);

    Exec("sed 's/__SUBSET_FILE__/$file_name_vec[0]_$line[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/plot_subset_separate_params.xml >> plot_params.xml");

    open(OUTFILE, ">>plot_params.xml");

    for (my $j = 0; $j < @matrices; $j++)
    {
      print OUTFILE "    <Plot Title=\"$line[0] $matrices[$j]\" DisplayLegends=\"1\">\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line[1]\" AverageAcrossWells=\"0\" UseSameStyleForCurves=\"0\"/>\n";
#      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line[1]\" AverageAcrossWells=\"1\" LineWidth=\"3\"/>\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line[1]\" AverageAcrossWells=\"0\" UseSameStyleForCurves=\"0\" CurveType=\"PointMax\"/>\n";
#      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line[1]\" AverageAcrossWells=\"1\" CurveType=\"PointMax\"/>\n";
      print OUTFILE "    </Plot>\n";
    }

    print OUTFILE "  </Figure>\n";
    close(OUTFILE);
  }
  close(INFILE);
}

my @row = split(/\,/, $plot_subset_average);
for (my $i = 0; $i < @row; $i++)
{
  my @dir_names_vec = split(/\//, $row[$i]);
  my @file_name_vec = split(/\./, $dir_names_vec[@dir_names_vec - 1]);
  
  Exec("sed 's/__SUBSET_FILE__/$file_name_vec[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/plot_subset_average_params.xml >> plot_params.xml");

  open(OUTFILE, ">>plot_params.xml");

  open(INFILE, "<$row[$i]");
  my $line_str = <INFILE>;
  chomp $line_str;
  my @line = split(/\t/, $line_str);
  my @matrices = split(/\,/, $line[1]);
  # read all the subsets into arrays
  my @lines;
  my @wells;
  while (<INFILE>)
  {
       chomp;
       my @line = split(/\t/);
       my @well_list = split(/\,/, $line[1]);
       push(@lines, \@line);
       push(@wells, \@well_list);
  }
# go over all the matrices in the file 
  for (my $j = 0; $j < @matrices; $j++) 
  {
    print OUTFILE "     <Plot Title=\"$matrices[$j]\" DisplayLegends=\"1\">\n";
    # go over all the lines
    for (my $k = 0; $k < @lines; $k++)
    {
	my $line_ref= $lines[$k];
    
#	print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line_ref->[1]\" AverageAcrossWells=\"1\" LineWidth=\"2\"/>\n";
	print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line_ref->[1]\" CurveType=\"Errorbars\" LineWidthErrorbars=\"1\" LineWidth=\"2\" AverageAcrossWells=\"1\" StdAcrossWells=\"1\"/>\n";
      # print OUTFILE "      <Curve Matrix1=\"$line[0]\" Wells1=\"$line_ref->[1]\" AverageAcrossWells=\"0\" UseSameStyleForCurves=\"0\" CurveType=\"PointMax\"/>\n";
     print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line_ref->[1]\" AverageAcrossWells=\"1\" CurveType=\"PointMax\"/>\n";
    }
    print OUTFILE "    </Plot>\n";
  }
  print OUTFILE "  </Figure>\n";
   close(INFILE);
  close(OUTFILE);
}

my @row = split(/\,/, $plot_subset_together);
for (my $i = 0; $i < @row; $i++)
{
  my @dir_names_vec = split(/\//, $row[$i]);
  my @file_name_vec = split(/\./, $dir_names_vec[@dir_names_vec - 1]);
  
  Exec("sed 's/__SUBSET_FILE__/$file_name_vec[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/plot_subset_together_params.xml >> plot_params.xml");

  open(OUTFILE, ">>plot_params.xml");

  open(INFILE, "<$row[$i]");
  my $line_str = <INFILE>;
  chomp $line_str;
  my @line = split(/\t/, $line_str);
  my @matrices = split(/\,/, $line[1]);
  # read all the subsets into arrays
  my @lines;
  my @wells;
  while (<INFILE>)
  {
       chomp;
       my @line = split(/\t/);
       my @well_list = split(/\,/, $line[1]);
       push(@lines, \@line);
       push(@wells, \@well_list);
  }
  # go over all the matrices in the file 
  for (my $j = 0; $j < @matrices; $j++) 
  {
    print OUTFILE "     <Plot Title=\"$matrices[$j]\" DisplayLegends=\"1\">\n";
    # go over all the lines
    for (my $k = 0; $k < @lines; $k++)
    {
	my $line_ref= $lines[$k];
    
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line_ref->[1]\" AverageAcrossWells=\"0\" UseSameStyleForCurves=\"1\"/>\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line_ref->[1]\" AverageAcrossWells=\"1\" LineWidth=\"3\"/>\n";
      # print OUTFILE "      <Curve Matrix1=\"$line[0]\" Wells1=\"$line_ref->[1]\" AverageAcrossWells=\"0\" UseSameStyleForCurves=\"0\" CurveType=\"PointMax\"/>\n";
     print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"$line_ref->[1]\" AverageAcrossWells=\"1\" CurveType=\"PointMax\"/>\n";
    }
    print OUTFILE "    </Plot>\n";
  }
  print OUTFILE "  </Figure>\n";
   close(INFILE);
  close(OUTFILE);
}




GroupByX($plot_groupbyx_boxplot, 1);
GroupByX($plot_groupbyx_points, 0);

open(OUTFILE, ">>plot_params.xml");
print OUTFILE "</Figures>\n";
close(OUTFILE);

#--------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------
sub GroupByX
{
  my ($params, $boxplot) = @_;

	my $file_param = $boxplot == 1 ? "boxplot" : "points";
	my $curve_param = $boxplot == 1 ? "Boxplot" : "Points";

  my @row = split(/\,/, $params);
  for (my $i = 0; $i < @row; $i++)
  {
    my @dir_names_vec = split(/\//, $row[$i]);
    my @file_name_vec = split(/\./, $dir_names_vec[@dir_names_vec - 1]);

    Exec("sed 's/__GROUPBYX_FILE__/$file_name_vec[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/plot_groupbyx_${file_param}_params.xml >> plot_params.xml");

    open(OUTFILE, ">>plot_params.xml");

    open(INFILE, "<$row[$i]");
    my $line_str = <INFILE>;
    chomp $line_str;
    my @line = split(/\t/, $line_str);
    my @matrices = split(/\,/, $line[1]);

    for (my $j = 0; $j < @matrices; $j++)
    {
      print OUTFILE "    <Plot Title=\"$matrices[$j] Max\">\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"ALL\" CurveType=\"GroupByXValue$curve_param\" MaxAcrossTimes=\"1\" Wells2XValues=\"$row[$i]\"/>\n";
      print OUTFILE "    </Plot>\n";
      print OUTFILE "    <Plot Title=\"$matrices[$j] Time of Max\">\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"ALL\" CurveType=\"GroupByXValue$curve_param\" TimeOfMaxAcrossTimes=\"1\" Wells2XValues=\"$row[$i]\"/>\n";
      print OUTFILE "    </Plot>\n";
      print OUTFILE "    <Plot Title=\"$matrices[$j] Time of Onset\">\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"ALL\" CurveType=\"GroupByXValue$curve_param\" TimeOfOnset=\"1\" OnsetThreshold=\"0.1\" Wells2XValues=\"$row[$i]\"/>\n";
      print OUTFILE "    </Plot>\n";
      print OUTFILE "    <Plot Title=\"$matrices[$j] t0.5\">\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"ALL\" CurveType=\"GroupByXValue$curve_param\" TimeOfXPercent=\"1\" Percent=\"0.5\" Wells2XValues=\"$row[$i]\"/>\n";
      print OUTFILE "    </Plot>\n";
      print OUTFILE "    <Plot Title=\"$matrices[$j] t0.9\">\n";
      print OUTFILE "      <Curve Matrix1=\"$matrices[$j]\" Wells1=\"ALL\" CurveType=\"GroupByXValue$curve_param\" TimeOfXPercent=\"1\" Percent=\"0.9\" Wells2XValues=\"$row[$i]\"/>\n";
      print OUTFILE "    </Plot>\n";
    }

    close(INFILE);

    print OUTFILE "  </Figure>\n";
    close(OUTFILE);
  }
}

#--------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------
sub Exec
{
  my ($exec_str) = @_;
  
  print("Running: [$exec_str]\n");
  system("$exec_str");
}

__DATA__

plot_platereader_analysis.pl <file>

   Sets up a directory for plate reader analyses

   -p <num>:                         The number of different plates that are measured in this directory (default: no plates, just a plots directory)

   -input_dir <str>:                 Input directory for files if plates are not specified

   -plot_all_combined <str>:         Combined plot of all wells of matrices in str. Separate matrices by ",". Example: 'YFP,OD'
   -plot_all_combined_together <str>:         Combined plot of all wells of matrices in str (all in the same plot). Separate matrices by ",". Example: 'YFP,OD'
   -plot_all_separate <str>:         Separate plot of all wells of matrices in str. Separate matrices by ",". Example: 'YFP,OD'

   -plot_subset_separate <str>:      List of well subset files. A separate figure will be made for each well subset within each subset file.
   -plot_subset_combined <str>:      List of well subset files. A single figure will be made. The figure will contain several plots- each plot of a well subset within each subset file
                                     FILE FORMAT: header: "Matrices" tab <comma separated matrices list>, <subsetname> tab <comma separated well list>
    -plot_subset_together <str>:     List of well subset files. A single plot will be made. In this plot, each subset will be coloured differently.
   -plot_subset_average <str>:       List of well subset files. A single plot will be made with the average of the subsets. 
   -plot_groupbyx_boxplot <str>:     List of group files. For each file, wells of the same value will be grouped together on the x-axis, and be displayed as a box plot
   -plot_groupbyx_points <str>:      List of group files. For each file, wells of the same value will be grouped together on the x-axis, and all their points will be displayed
                                     FILE FORMAT: header: <group name> tab <matrices>, rows: <well id> tab <value> tab <reference- 1 if yes, nothing if no>
    

