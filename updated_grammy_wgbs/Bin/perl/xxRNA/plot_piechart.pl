#!/usr/bin/perl

use strict;
use GD::Simple;
use GD::Graph::pie;

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
my $image_width = get_arg("iw", 640, \%args);
my $l_marg = get_arg("lm", 100, \%args);
my $r_marg = get_arg("rm", 20, \%args);
my $v_marg = get_arg("vm", 30, \%args);

my $n_tus = 0;
my $max_len = 0;

print STDERR "Processing sample91\n";

my @data = ( 
    ["1st","2nd","3rd","4th","5th","6th"],
    [    4,    2,    3,    4,    3,  3.5]
);

my $my_graph = new GD::Graph::pie( 250, 200 );

$my_graph->set( 
	title => 'A Pie Chart',
	label => 'Label',
	axislabelclr => 'black',
	pie_height => 36,

	l_margin => 15,
	r_margin => 15,

	start_angle => 235,

	transparent => 0,
);

$my_graph->plot(\@data);

save_chart($my_graph, 'sample91');


sub save_chart
{
	my $chart = shift or die "Need a chart!";
	my $name = shift or die "Need a name!";
	local(*OUT);

	my $ext = $chart->export_format;

	open(OUT, ">$name.$ext") or 
		die "Cannot open $name.$ext for write: $!";
	binmode OUT;
	print OUT $chart->gd->$ext();
	close OUT;
}


__DATA__

est_plot.pl

    Take an EST file and create a splice pattern image containing the TUs
    described in the file.
    


