#!/usr/bin/perl

use strict;
use GD::Simple;

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
  die ("Cannot work on STDIN.\n");
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}


my %args = load_args(\@ARGV);
my $image_width = get_arg("iw", 640, \%args);
my $l_marg = get_arg("lm", 100, \%args);
my $r_marg = get_arg("rm", 20, \%args);
my $v_marg = get_arg("vm", 30, \%args);

my $n_tus = 0;
my $max_len = 0;

### First read -- count lines and get maximal TU length

while (<$file_ref>)
{
	chomp;
	
	my ($chrom, $strand, $name, $tstart, $tend, $AccCount, $exstarts, $exends, $exoccurrence) = split("\t");
	
	my $tlength = abs ($tend - $tstart) + 1;
	
	if ($tlength > $max_len) { $max_len = $tlength; }
	$n_tus++;
}

print STDERR "Found " . ($n_tus+1) . " transcripts. Longest is " . $max_len . " bases.\n";
seek (FILE, 0, 0);

my $image_height = 2 * $v_marg * $n_tus;
my $w_effective = $image_width - $l_marg - $r_marg;

print STDERR "Creating image $image_width x $image_height\n";

my $img = GD::Simple->new($image_width, $image_height);

### Second read -- create image

my $i=0;

my $pix_per_bp = $w_effective / $max_len;

while (<$file_ref>)
{
	chomp;
	
	my ($chrom, $strand, $name, $tstart, $tend, $AccCount, $exstarts, $exends, $exoccurrence) = split("\t");
	
	my $tlength = abs ($tend - $tstart) + 1;
	
	my @exonS = split (",", $exstarts);			@exonS = grep /\S/, @exonS;
	my @exonE = split (",", $exends);			@exonE = grep /\S/, @exonE;
	my $nExons = scalar @exonS;

	my $v_line = $v_marg * ((2 * $i)+1);
	
	$img->bgcolor('red');
    $img->fgcolor('red');

	$img->rectangle($l_marg, $v_line-1, $l_marg + $tlength * $pix_per_bp, $v_line+1);
	
	# TU name and chromosome 
	
    $img->fgcolor('black');

	$img->moveTo(10, $v_line+6);
    $img->string($name);

	my $toprint = $chrom . $strand;
	my $string_width = $img->stringWidth($toprint);
	
	$img->moveTo($l_marg - 10 - $string_width, $v_line+6);
    $img->string($toprint);

	# Start and end positions
	
	$img->fgcolor('red');
	
	$toprint = commify ($tstart);
	$string_width = $img->stringWidth($toprint);

	if ($string_width * 2.3 > $tlength * $pix_per_bp)
	{
		# print both start and end
		$img->moveTo($l_marg, $v_line+20);
		$img->string($toprint . " - " . commify ($tend));		
	}
	else
	{
		$img->moveTo($l_marg, $v_line+20);
    	$img->string($toprint);
    	
    	$toprint = commify ($tend);
		$string_width = $img->stringWidth($toprint);
			
		$img->moveTo(($l_marg + $tlength * $pix_per_bp) - $string_width, $v_line+20);
		$img->string($toprint);
    }

	$img->bgcolor('blue');
    $img->fgcolor('blue');

	# Size info
	$img->moveTo($l_marg, $v_line-6);
	$img->string(commify ($tlength) . "bp, " . $nExons . " exon" . (($nExons > 1 ? "s" : "")));

	# Draw exons
	
	for (my $j=0; $j < $nExons; $j++)
	{
		my $draw_s = ($exonS[$j] - $tstart) * $pix_per_bp;
		my $draw_e = ($exonE[$j] - $tstart) * $pix_per_bp;
				
		$img->rectangle($l_marg + $draw_s, $v_line-4, $l_marg + $draw_e, $v_line+4);
	}
	
	$i++;
}

print $img->png;

##################

sub commify {
        my $input = shift;
        $input = reverse $input;
        $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
        my $output = reverse $input;
        
        return $output;
}


__DATA__

est_plot.pl

    Take an EST file and create a splice pattern image containing the TUs
    described in the file.
    


