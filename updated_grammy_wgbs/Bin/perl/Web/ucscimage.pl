#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $clade = get_arg("c", "", \%args);
my $organism = get_arg("o", "", \%args);
my $genome_version = get_arg("g", "dm2", \%args);
my $picture_width = get_arg("p", 620, \%args);
my $custom_tracks = get_arg("custom", "", \%args);
my $output_folder = get_arg("of", "", \%args);
my $margin = get_arg("m", 0, \%args);
my $print = get_arg("print", 0, \%args);

if (length($output_folder) > 0) { $output_folder .= "/"; }

# Read locations of all sequences for which images are to be retrieved.

while (<$file_ref>)
{
	chomp;
	if(/\S/)
	{
	
		(my $chr, my $id, my $seq_start, my $seq_end) = split("\t");
		
		my $view_start;
		my $view_end;
		
		if ($seq_start < $seq_end)
		{
			$view_start = $seq_start - $margin;
			$view_end = $seq_end + $margin;
		}
		else
		{
			$view_start = $seq_end - $margin;
			$view_end = $seq_start + $margin;		
		}
		
		print STDERR "Getting sequence $id... ";
		
		#system ("wget -q -O tmp_html \"http://genome.ucsc.edu/cgi-bin/hgTracks?clade=insect&org=D.+melanogaster&db=dm2&position=chr$chr%3A$view_start-$view_end&pix=620&hgsid=63261196&Submit=submit\"");

		my $system_command = "wget --load-cookies $ENV{HOME}/.mozilla/default/yiv7gpia.slt/cookies.txt -q -O tmp_html";
		my $url = "http://genome.ucsc.edu/cgi-bin/hgTracks?";
		if ($clade ne "") { $url   .= "clade=$clade&"; }
		if ($organism ne "") { $url   .= "org=$organism&"; }
		$url   .= "db=$genome_version&";
		$url   .= "position=chr$chr%3A$view_start-$view_end&";

		if (length($custom_tracks) > 0)
		{
		  my @custom = split(/\;/, $custom_tracks);
		  foreach my $c (@custom)
		  {
		    $url .= "hgt.customText=$c&";
		  }
		}

		$url   .= "pix=$picture_width";

		print "$_\t$url\n";
		
		if (not $print)
		{
			system ("$system_command \"$url\"");
		
			open(TMPHTML, "< tmp_html");
			my(@lines) = <TMPHTML>;    
			close (TMPHTML);
			
			my $lines = join " ", @lines;
			
			my $gifname ="";
			
			if ($lines =~ /hgt_genome(.*)gif/)
			{
				print STDERR "Getting GIF... ";
				
				$gifname = "http://genome.ucsc.edu/trash/hgt/hgt_genome$1gif";
				system ("wget -q -O $output_folder$id.gif $gifname");
				
				print STDERR "OK.\n";
			}
			else
			{
				print STDERR "Could not find GIF filename.\n";
			}
			
			system("rm tmp_html");
		}
	}
}


__DATA__

ucscimage.pl <file>

   Get an image from the UCSC genome browser. The input file contains lines 
   describing the images to get in the format
   <chr><tab><ID><tab><start><tab><end>

   Examples: yeast (clade=other organism=S.+cerevisiae sacCer1)

   -c <str>:      Clade (default: insect)
   -o <str>:      Organism (default: D.+melanogaster)
   -g <str>:      Genome version (default: dm2)

   -of <str>:     Output folder

   -custom <str>: List of full URLs to add as custom tracks, semi-colon separated

   -p <num>:      Picture width (Default: 620)

   -m <num>:      Margin before and after sequence to include in image.

   -print:        Do not fetch anything -- just print what would be fetched (URL)
   