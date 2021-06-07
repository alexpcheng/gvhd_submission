#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $CDS_FLANK = 200;
my $SITE_LENGTH = 25;

my $POLY_A = "A" x $CDS_FLANK;

my %args = load_args(\@ARGV);

my $prefix = get_arg("prefix", "", \%args);
my $debug = get_arg("debug", 0, \%args);
my $ext_utr_fn = get_arg("ext_utr", "", \%args);
my $id = get_arg("id", "", \%args);
my $start = get_arg("start", "", \%args);
my $locations_file = get_arg("f", "", \%args);
my $DDG_AREA = get_arg("ddG_context", 70, \%args);
my $PLOT_AREA = get_arg("plot_context", 70, \%args);

my $echoed_plot_args = 
  echo_arg("output", \%args) . 
  echo_arg("format", \%args) .
  echo_arg("prefix", \%args);
  
my $r = int(rand(100000));

if ($ext_utr_fn eq "") { die "Must provide extended UTR stab file.\n"; }

if ($locations_file eq "")
{
	if ($id eq "") { die "Must provide ID to plot.\n";}
	if ($start eq "") { die "Must provide start position of site.\n"; }
}

## Step 1: Generate PS images

print STDERR "Creating images...\n";


if ($locations_file ne "")
{
	dsystem ("cat $locations_file " .
			 "| cut.pl -f 1,1,2,2,2 " .
			 "| merge_columns.pl -1 1 -2 2 -d \"_\" " .
			 "| modify_column.pl -c 2 -s $SITE_LENGTH " .
			 "| modify_column.pl -c 2,3 -a $CDS_FLANK " .
			 "| modify_column.pl -c 2 -s $PLOT_AREA " .
			 "| modify_column.pl -c 3 -a $PLOT_AREA " .
			 "> tmp_extract_$r ");
	
	dsystem ("extract_sequence.pl -f tmp_extract_$r -dn < $ext_utr_fn " .
			 "| RNAfold.pl -sequence " .
			 "| add_column.pl -s $PLOT_AREA " .
			 "| add_column.pl -s " . ($PLOT_AREA + $SITE_LENGTH) . " " .
			 "> tmp_folded_$r");
}
else
{
	my $start_loc = $start + $CDS_FLANK - $PLOT_AREA - $SITE_LENGTH;
	my $end_loc = $start + $CDS_FLANK + $PLOT_AREA;
	
	dsystem ("extract_sequence.pl -k $id -s $start_loc -e $end_loc -dn < $ext_utr_fn " .
	         "| add_column.pl -b -s $start " .
	         "| cut.pl -f 2,1,3- " .
	         "| merge_columns.pl -d \"_\" " .
			 "| RNAfold.pl -sequence " .
			 "| add_column.pl -s $PLOT_AREA " .
			 "| add_column.pl -s " . ($PLOT_AREA + $SITE_LENGTH) . " " .
			 "> tmp_folded_$r");
}

dsystem ("cat tmp_folded_$r " .
		 "| RNAplot.pl -m 3 -sf $echoed_plot_args");

dsystem ("/bin/rm -rf tmp_extract_$r tmp_folded_$r");

exit(0);


sub dsystem {

        my $cmd = $_[0];

        if ($debug) { print STDERR "Executing $cmd\n"; }
        system ($cmd);
        
}


__DATA__
syntax: pita_plot.pl [OPTIONS]

Create structure icons showing microRNA target sites identified by PITA.

options:
    -ext_utr <filename>:  Name and location of the extended UTR file created by pita_run.pl
    
    -id <string>:         The ID of the UTR to be drawn
    
    -start <num>:         Start position of the target on the UTR (5' of microRNA)
    
    -f <filename>:        Optional filename containing pairs of IDs, start. If given
                          the id and start flags are ignored, and an image is generated
                          for each of the pairs in the file.
                          
    -plot_context <bp>:   Number of bases upstream and downstream that are shown on the structure
                          plots
                          
    -output <directory>:  Path to where images should be placed (default: current directory)
        
    -format <name>:       In addition to creating ps files, convert them to the given
                          format (e.g. png, bmp, gif, jpg, tiff). Uses "convert".

    -prefix <string>:     Add the string as a prefix to the output image files.

    -debug                Run in debug mode (leave untouched tmp files)
    
