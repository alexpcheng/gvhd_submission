#!/usr/bin/perl

use strict;

#require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}



#my %args = load_args(\@ARGV);
#my $matlabDev = get_arg("path", "$ENV{DEVELOP_HOME}/Matlab", \%args);

my $dir_name = $ARGV[0];

my $DEFUALT_FILES_DIR = "$ENV{DATA_HOME}/Promoter/Expression";


system ("mkdir $dir_name;") == 0
  or die ("Failed to create directory: $dir_name\n");

print STDERR "Made directory: $dir_name\n";

chdir($dir_name) or die ("Failed to change directory to: $dir_name\n");

system ("mkdir Local;") == 0
  or die ("Failed to create directory: $dir_name/Local\n");

print STDERR "Made Local directory inside the directory, this is where you should put the plate reader files\n";

system ("ln -s $DEFUALT_FILES_DIR/data.mak Makefile;") == 0
  or die ("Failed to create soft link to: $DEFUALT_FILES_DIR/data.mak\n");

print STDERR "Created soft link to the Makefile\n";


system ("cp $DEFUALT_FILES_DIR/Makefile.private.default Makefile.private;") == 0
  or die ("Failed to copy: $DEFUALT_FILES_DIR/Makefile.private.default\n");

print STDERR "Copied the private make file. Here you can add plate analysis files names\n";

system ("ln -s $DEFUALT_FILES_DIR/f500_plate_analysis_param.txt.default f500_plate_analysis_param.txt;") == 0
  or die ("Failed to create soft link to: $DEFUALT_FILES_DIR/f500_plate_analysis_param.txt.default\n");

print STDERR "Created soft link to f500_plate_analysis_param.tx. This is the defualt analysis parameters file\n";

#system ("cp $DEFUALT_FILES_DIR/f500_plate_analysis_param.txt.default f500_plate_analysis_param.txt;") == 0
#  or die ("Failed to copy: $DEFUALT_FILES_DIR/f500_plate_analysis_param.txt.default\n");


print STDERR "Done!\n";


__DATA__

create_CM_data_dir.pl <dir name>

Creates a data directory for f500 plate reader data


