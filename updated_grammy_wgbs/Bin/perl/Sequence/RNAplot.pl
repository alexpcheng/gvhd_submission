#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAfold_EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs/";

if ($ARGV[0] eq "--help")
{
  print STDERR <DATA>;
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
  open(FILE, $file) or die ("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);

my $prefix = get_arg("prefix", "", \%args);
my $mark = get_arg ("m", 5, \%args);
my $special_figure = get_arg ("sf", 50, \%args);
my $annotate = get_arg ("annotate", 50, \%args);
my $thickline = get_arg ("thick", 0, \%args);
my $draw_pairs = get_arg ("dp", 0, \%args);
my $output_dir = get_arg("output", "", \%args);
my $format = get_arg("format", "", \%args);
my $debug = get_arg("debug", 0, \%args);

if ($output_dir ne "")
{
	$output_dir .= "/";
}

# First read all sequences while creating the input file for RNAplot

print STDERR "Plotting...\n";
my $r = int(rand(100000));

while (<$file_ref>)
{
	chop;
	if(/\S/)
	{
		(my $id, my $seq, my $fold, my $start, my $end, my $caption, my $circles, my $empty_circles) = split("\t");	

		my $shortID = substr ($id, 0, 10);

		open (SEQFILE, ">tmp_seqfile_$r") or die ("Could not open temporary sequence file.\n");
		print SEQFILE "> $shortID\n$seq\n$fold\n";
		close (SEQFILE);

		my $pre = "";
		my $post = "";
		
		if ($end ne "")
		{
			my @starts = split (",", $start);
			my @ends = split (",", $end);
			my $array_length = scalar @starts;
			
			for (my $cur_se = 0; $cur_se < $array_length; $cur_se++)
			{
				$pre .= "$starts[$cur_se] $ends[$cur_se] 5 0 1 0 omark ";
			
				if ($mark eq 5)
				{
					$post .= "$starts[$cur_se] cmark ";
				}
				else
				{
					$post .= "$ends[$cur_se] cmark ";
				}
			}
			
			if ($caption ne "")
			{
				$post .= " newpath /Helvetica findfont 28 scalefont setfont -216 ymax size ymin sub sub 2 div moveto ($caption) show";
			}
		}
		
		my $cmd = "$RNAfold_EXE_DIR/RNAplot --pre \"$pre\" --post \"$post\" < tmp_seqfile_$r";
		
		if ($debug)
		{
			print STDERR "Executing: $cmd\n";
		}
		
		my $prog_result = `$cmd`;

		print STDERR "     $prog_result";
		
		my $destination_fn = $output_dir . $prefix . $id;
		system ("mv $shortID" . "_ss.ps $destination_fn" . "_structure.ps");
		
		if ($format)
		{
			system ("convert $destination_fn" . "_structure.ps $destination_fn" . "_structure." . $format);
		}
		

		if ($annotate)
		{
			open(PSINPUT, "<$destination_fn" . "_structure.ps"); # open for input
			my (@lines) = <PSINPUT>; # read file into list
			open (PSOUTPUT, ">$destination_fn" . "_annotated.ps");

			foreach my $line (@lines)
			{
				$line =~ s/\%\%EndProlog\n/\/mymark \{ \% i mymark   draw circle around base i \nnewpath 1 sub coor exch get aload pop\nfsize 2 div 0 360 arc closepath\nsetrgbcolor fill\n\} bind def
\%\%EndProlog\n/;
				my @circ = split (/ *; */, $circles);
				my $drawcmd = "";
				foreach (@circ)
				{
					$drawcmd .= "$_ mymark\n";
				}

				if ($empty_circles)
				{
					$drawcmd .= "gsave\n2 setlinewidth\n0 0 0 setrgbcolor\n[] 0 setdash\n";
					my @empty_c = split (' *; *', $empty_circles);				
					foreach (@empty_c)
					{
						$drawcmd .= "$_ cmark\n";
					}
					$drawcmd .= "grestore\n";
				}
				
				$line =~ s/^drawbases/$drawcmd\ndrawbases\n/;
				
				print PSOUTPUT $line;
			}
			close (PSINPUT);
			close (PSOUTPUT);
			
			if ($format)
			{
				system ("convert $destination_fn" . "_annotated.ps $destination_fn" . "_annotated." . $format);
			}
		}
		
		
		if ($special_figure)
		{
			# if we're doing an annotated image, work on the annotated version
			my $sourcefn = $annotate ? "_annotated.ps" : "_structure.ps";
			
			open(PSINPUT, "<$destination_fn" . "$sourcefn"); # open for input
			my (@lines) = <PSINPUT>; # read file into list
			open (PSOUTPUT, ">$destination_fn" . "_skeleton.ps");

			foreach my $line (@lines)
			{
				$line =~ s/drawbases\n//g;
				if ($draw_pairs == 0) { $line =~ s/drawpairs\n//g; }
				$line =~ s/outlinecolor \{0\.2 setgray\}/outlinecolor \{0 setgray\}/g;
				$line =~ s/\[9 3\.01\] 9 setdash/\[\] 0 setdash/g;
				
				if ($thickline)
				{
					$line =~ s/ .* setlinewidth/ $thickline setlinewidth/g;			
				}
				
				print PSOUTPUT $line;
			}
			close (PSINPUT);
			close (PSOUTPUT);
			
			if ($format)
			{
				system ("convert $destination_fn" . "_skeleton.ps $destination_fn" . "_skeleton." . $format);
			}

		}

	}
}

print STDERR "Done.\n";
if (!$debug)
{
	system("rm tmp_seqfile_$r");
}

__DATA__

RNAplot.pl <folding file>

	RNAplot  reads RNA sequences and structures from a file in the format
	<name> <sequence> <folding> <start_annotation> <end_annotation> <caption> <circles> <empty_circles>
    produced by RNAfold and produces drawings of the secondary structure
    graph. 
    
    The bases at the positions i-j are highlighted. 
    Caption is added at the bottom of the figure.
    
    Generated files are named based on the sequence ID.
    
    Options:
    
    -m [3|5]:	    Mark the 3' or 5' end of the highlighted sequence with a circle
                    (default 5')
    				
    -sf:            Also create a skeleton figure (no bases). This creates another
                    postscript file for each plotted sequence with the "skeleton" suffix.

    -dp:            Draw pairs when drawing the skeleton.
    
    -output <dir>:  Put resulting graphics in the given directory
    
    -format <name>: In addition to creating ps files, convert them to the given
                    format (e.g. png, bmp, gif, jpg, tiff). Uses "convert".
                    
    -prefix <string>:     Add the string as a prefix to the output image files.
    
    -annotate:      Use the data found in the seventh column for determining which
    				bases should be circled and filled. The format of the <circles> list
    				is "r g b i;r g b i; ..." where r,g,b are the color (0-255) and i is
    				the base number.
    				
    				The eighth column in this case contains a list of bases to be circled
    			
    				
