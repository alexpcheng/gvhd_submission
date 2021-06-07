#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my %args = load_args(\@ARGV);

my $output_file = get_arg("o", "", \%args);
my $input_file = get_arg("i", "", \%args);
my $max_mega = get_arg("m", 1024, \%args);

if ($output_file eq "")  {print STDERR "Error: Did not specify output file name.\n";exit 1;}
if ($input_file eq "") {print STDERR "Error: Did not specify input file name.\n";exit 1;}

my $image_output_file = substr($output_file, length($output_file)-4, 4) eq ".jpg" ? $output_file : $output_file.".jpg";

# Eilon: Produce a tmp input file with the header rows from the input gxw (which you'll get either from stdin or as the first parameter and replace it with $input_file

open (INPUT_FILE, "<$input_file") or die "Error: Failed to open file: $input_file";
my $genomica_input_file = "tmp_fmm_logo_$$.txt";

open (TMP_OUTPUT, ">$genomica_input_file") or die "Error: Failed to open file: $genomica_input_file";

my $reading_features = 0;
my $image_width = 0;
my $image_height = 0;
my $column_width = 0;
my $column_spacing = 0;
my $connecting_mode = 1;
my $fill_feature = 0;

while (<INPUT_FILE>)
{
   chop;
   if ($reading_features == 0)
   {
      my @r = split (/=/);
      $r[1] =~ s/\s//g;

      if (/^Feature_id/)
      {
	 $reading_features = 1;
      }
      elsif (/^ImageWidth/)
      {
	 $image_width = $r[1];
      }
      elsif (/^ImageHeight/)
      {
	 $image_height = $r[1];
      }
      elsif (/^CharSpacing/)
      {
	 $column_spacing = $r[1];
      }
      elsif (/^CharWidth/)
      {
	 $column_width = $r[1];
      }
      elsif (/^ConnectMode/)
      {
	 $connecting_mode = $r[1];
      }
      elsif (/^FillFeature/)
      {
	 $fill_feature = $r[1];
      }
   }
   else
   {
      print TMP_OUTPUT "$_\n";
   }
}
close (TMP_OUTPUT);
close (INPUT_FILE);


if ($image_width == 0) {print STDERR "Error: Did not specify image width parameter.\n";exit 1;}
if ($image_height == 0) {print STDERR "Error: Did not specify image height parameter.\n";exit 1;}
if ($column_width == 0) {print STDERR "Error: Did not specify column width parameter.\n";exit 1;}
if ($column_spacing == 0) {print STDERR "Error: Did not specify column spacing parameter.\n";exit 1;}


#print STDERR "DEBUG RUN:\n $ENV{JAVA_HOME}/bin/java -jar $ENV{GENOMICA_HOME}/Release/Genomica.jar $ENV{GENOMICA_HOME}/Release/Samples/sample.gxp -a FMM_LOGO -if $genomica_input_file -image_width $image_width -image_height $image_height -char_width $column_width -spacing $column_spacing -o $image_output_file -features_mode $connecting_mode" . ($fill_feature == 1 ? " -fill_feature" : "") . "\n";
 
# Running Genomica requires a dummy XServer - pointing DISPLAY to it
my $display = `ps -ef | grep Xvfb | grep -v grep | sed 's/  */\t/g' | cut -f 8- | cut -f 2- -d ':' | cut -f 1`;
$display =~ s/\s//g;

$ENV{'DISPLAY'} = ":$display";

system ("$ENV{JAVA_HOME}/bin/java -mx${max_mega}m -jar $ENV{GENOMICA_HOME}/Release/Genomica.jar $ENV{GENOMICA_HOME}/Release/Samples/sample.gxp -a FMM_LOGO -if $genomica_input_file -image_width $image_width -image_height $image_height -char_width $column_width -spacing $column_spacing -o $image_output_file -features_mode $connecting_mode" . ($fill_feature == 1 ? " -fill_feature" : "") . ">/dev/null");

system ("rm $genomica_input_file");

__DATA__

fmm_tab_logo2fmm_logo.pl 

    Creates FMM logo image (jpg) from a gxw file

    -i <str>: Input file name
    -o <str>: Output image file name (.jpg will be appended to <str>)
  
    -m <NUM>: Maximum number of MB to be allocated for the java process (default: 1024MB)

    Input file format example:
    -------------------------
    ImageWidth = 960
    ImageHeight = 1200
    CharWidth = 120
    CharSpacing = 10
    ConnectMode = 1
    FillFeature = 1
    Feature_id	Feature_hash_code	Feature_start_pos	Feature_end_pos	Feature_Top_cor	Feature_Bottom_cor	Position	Letters
    37	LPP3L1P4L3	3	4	0	247	3	C
    37	LPP3L1P4L3	3	4	0	247	4	T
    38	LPP4L1P5L3	4	5	248	480	4	C
    38	LPP4L1P5L3	4	5	248	480	5	T
          .
          .
          .


    Description:
    -----------
    ConnectMode has too options:
        1 - Box around each letter, boxes connected by a line
        2 - One box surrounds the whole feature

    FillFeature will draw a light gray background for composite features when specified.
