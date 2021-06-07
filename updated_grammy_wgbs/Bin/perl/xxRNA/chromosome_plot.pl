#!/usr/bin/perl

use strict;
use GD::Simple;
use GD::Image;

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
my $no_names = get_arg("no_names", 0, \%args);
my $set_h_offset = get_arg("set_h_offset", 20, \%args);


my $n_chrs = 0;
my $max_len = 0;
my $total_chrom_load = 0;

### First read -- count lines and get maximal chromosome length

while (<$file_ref>)
{
	chomp;
	
	my ($chrom, $length, $chrom_load) = split("\t");
	
	if ($length > $max_len) { $max_len = $length; }
	$n_chrs++;
	
	$total_chrom_load += ($chrom_load - 1);
}

print STDERR "Found " . ($n_chrs) . " chromosomes. Longest is " . $max_len . " bases.\n";
seek (FILE, 0, 0);

my $image_height = 2 * $v_marg * $n_chrs + ($total_chrom_load * 10);
my $w_effective = $image_width - $l_marg - $r_marg;

print STDERR "Creating image $image_width x $image_height\n";

my $img = GD::Simple->new($image_width, $image_height);

### Second read -- create image

my $i=0;
my $h_offset = 0;

my $pix_per_bp = $w_effective / $max_len;

while (<$file_ref>)
{
	chomp;
	
	my @r = split("\t");
	
	my $chr = shift (@r);
	my $chr_len = shift (@r);
	my $n_tus = shift (@r);
	
	my $v_line = $v_marg * ((2 * $i)+1);
	
	$img->bgcolor('blue');
	$img->fgcolor('blue');

	$img->rectangle($l_marg, $v_line-1+$h_offset, $l_marg + $chr_len * $pix_per_bp, $v_line+1+$h_offset);
	
	# TU name and chromosome 
	
	$img->fgcolor('black');

	my $toprint = $chr;
	my $string_width = $img->stringWidth($toprint);
	
	$img->moveTo($l_marg - 10 - $string_width, $v_line+6+$h_offset);
	$img->string($toprint);

	# Start and end positions
	
	#$img->fgcolor('red');
	
	#$toprint = commify ($chr_len);
	#$string_width = $img->stringWidth($toprint);
		
	#$img->moveTo(($l_marg + $chr_len * $pix_per_bp) - $string_width, $v_line-6+$h_offset);
	#$img->string($toprint);

	# Draw TUs
	my $new_h_offset = 0;
	my $last_text_right = 0;
	my $max_h_offset = 0;
	
	for (my $j=0; $j < $n_tus; $j++)
	{
		my ($tu_name, $strand, $tu_start, $tu_end) = split (",", $r[$j]);
		
		my $drawcolor = ($strand eq "+" ? "green" : "red");
		
		$img->bgcolor($drawcolor);
		$img->fgcolor($drawcolor);
		
		$img->rectangle($l_marg + $tu_start * $pix_per_bp, $v_line-4+$h_offset, $l_marg + $tu_end * $pix_per_bp, $v_line+4+$h_offset);
		
		my $tu_center = ($tu_start + $tu_end) / 2;
		my $tu_center_pos = $l_marg + $tu_center * $pix_per_bp - 2;
		
		#print STDERR "$tu_center_pos -- $last_text_right\n";
		
		if (($tu_center_pos < $last_text_right + 10) && (!$no_names))
		{
			$new_h_offset += 10;
			$max_h_offset = ($max_h_offset < $new_h_offset ? $new_h_offset : $max_h_offset);
		}
		else
		{
			$new_h_offset = 0;
		}
		
		$last_text_right = $tu_center_pos + $img->stringWidth($tu_name);
		
		$img->moveTo($tu_center_pos, $v_line+$set_h_offset+$h_offset+$new_h_offset);

		if (!$no_names) {
		    $img->string($tu_name);
		}
	}
	
	$h_offset += $max_h_offset;
	
	$i++;
}

# Create an image that only uses as much space as we really reaquired

my $image_height_final =  2 * $v_marg * $n_chrs + $h_offset;
print STDERR "Final image size $image_width x $image_height_final\n";

my $final_img = GD::Simple->new($image_width, $image_height_final);
my $tmp_img = $img->clone;

$final_img->copy($tmp_img, 0, 0, 0, 0, $image_width, $image_height_final);


print $final_img->png;

##################

sub commify {
        my $input = shift;
        $input = reverse $input;
        $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
        my $output = reverse $input;
        
        return $output;
}


__DATA__

chromosome_plot.pl

    Takes a file containing TU locations on chromosomes and plots it. The input
    data format is
    
    <chr> <chr_length> <number_of_TUs> <TU_DATA>
    
    whre TU_DATA is comma delimited:
    <name>, <strand>, <start>, <end>

    -no_names         do *NOT* add tu name under location (default: add)
    -set_h_offset     set a fixed height offset between chromosomes (default: 20)
