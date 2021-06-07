#!/usr/bin/perl

use strict;
use List::Util qw [min max];

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

my %args = load_args(\@ARGV);
my $type = get_arg("type", "", \%args);


my $echoed_args = 
  echo_arg_equals("name", \%args) .
  echo_arg_equals("description", \%args) .
  echo_arg_equals("visibility", \%args) .
  echo_arg_equals("color", \%args) .
  echo_arg_equals("useScore", \%args) .
  echo_arg_equals("group", \%args) .
  echo_arg_equals("priority", \%args) .
  echo_arg_equals("db", \%args) .
  echo_arg_equals("offset", \%args) .
  echo_arg_equals("type", \%args) .
  echo_arg_equals("url", \%args) .
  echo_arg_equals("htmlUrl", \%args);

my $flank = get_arg("flank", 50, \%args);
my $position = get_arg("position", "", \%args);
my $type = get_arg("type", "", \%args);

my $freetext = get_arg ("freetext", "", \%args);

if ($freetext) { $echoed_args .= " $freetext" };


my $first_line = 1;
my $cur_chr = "";

while(<$file_ref>)
{
	chomp;
	
	my ($chr, $id, $start, $end, $vtype, $value) = split(/\t/);

	$chr = "chr" . $chr;
	
	my $minusplus = "+";
	$start < $end ? "+" : "-";

  	if ($end < $start)
  	{
    	my $tmp = $start;
    	$start = $end;
    	$end = $tmp;
		$minusplus = "-";
	}

	if ($first_line)
	{
		$first_line = 0;
		
		if ($position)
		{
			print "browser position $position\n";
		}
		else 
		{
			if ($flank)
			{ 
				print "browser position " . $chr . ":" . max ($start - $flank, 1) . "-" . ($end + $flank) . "\n";
			}
		}
		if ($echoed_args ne "")
		{
			print "track " . $echoed_args . "\n";
		}
	}
	
	if ($type eq "wiggle_0")
	{
		if ($chr ne $cur_chr)
		{
			print "variableStep chrom=$chr\n";
			$cur_chr = $chr;
		}
		print "$start " . " $value\n";
	}
	else
	{
		print "$chr $start $end $id $value $minusplus\n";
	}
}

__DATA__

chr2ucsc_custom_track.pl <file>

   Takes in a chr file and converts it to a UCSC custom track file, which includes the relevant
   headers and the actual chr data in BED format.
   
   chr fields: <chr> <ID> <start> <end> <type> <value>
   
   the <type> field is ignored.
   <value> is expected to be in the range 0-1000
   
   -flank <num>     Position the browser around the first entry in the chr with a flank of <num>
                    bases to each side. Default: 50. Use 0 to ignore this feature (browser will be
                    opened at last open position).
         
   -position <str>  Open the broswer at the given position. The string is of the format chr:start-end
                    for example "chr3L:18268261-18269391". If present, overrides the "flank" parameter.
                  
   The following arguments control the track display:
   
   -name <track_label> - Defines the track label that will be displayed to the left of the
                         track in the Genome Browser window, and also the label of the track
                         control at the bottom of the screen. The name can consist of up to 15
                         characters, and must be enclosed in quotes if the text contains spaces.
                         The default value is "User Track".
                         
   -description <center_label> - Defines the center label of the track in the Genome Browser window.
                                 The description can consist of up to 60 characters, and must be enclosed
                                 in quotes if the text contains spaces. The default value is "User
                                 Supplied Track".
                                 
   -visibility <display_mode> - Defines the initial display mode of the annotation track. Values for
                                display_mode include: 0 - hide, 1 - dense, 2 - full, 3 - pack, and
                                4 - squish. The numerical values or the words can be used, i.e. full
                                mode may be specified by "2" or "full". The default is "1".

   -color <RRR,GGG,BBB> - Defines the main color for the annotation track. The track color consists
                          of three comma-separated RGB values from 0-255. The default value is 0,0,0 (black).

   -itemRgb On - If this attribute is present and is set to "On", the Genome Browser will use the RGB
                 value shown in the itemRgb field in each data line of the associated BED track to
                 determine the display color of the data on that line.

   -useScore <use_score> - If this attribute is present and is set to 1, the score field in each of the
                           track's data lines will be used to determine the level of shading in which the
                           data is displayed. The track will display in shades of gray unless the color
                           attribute is set to 100,50,0 (shades of brown) or 0,60,120 (shades of blue).
                           The default setting for useScore is "0".
                           
   -group <group> - Defines the annotation track group in which the custom track will display in the
                    Genome Browser window. By default, group is set to "user", which causes custom
                    tracks to display at the top of the window.

   -priority <priority> - When the group attribute is set, defines the display position of the track
                          relative to other tracks within the same group in the Genome Browser window. 
                          If group is not set, the priority attribute defines the track's order relative
                          to other custom tracks displayed in the default group, "user".

   -db <UCSC_assembly_name> - When set, indicates the specific genome assembly for which the annotation
                              data is intended; the custom track manager will display an error if a user
                              attempts to load the track onto a different assembly. Any valid UCSC assembly
                              ID may be used (eg. hg18, mm8, felCat1, etc.). The default setting is blank,
                              allowing the custom track to be displayed on any assembly.

   -offset <offset> - Defines a number to be added to all coordinates in the annotation track.
                      The default is "0".

   -url <external_url> - Defines a URL for an external link associated with this track. This URL will
                         be used in the details page for the track. Any '$$' in this string this will
                         be substituted with the item name. There is no default for this attribute.

   -htmlUrl <external_url> - Defines a URL for an HTML description page to be displayed with this track.
                             There is no default for this attribute. 

