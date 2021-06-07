#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $bins = get_arg("b", 20, \%args);
my $skip = get_arg("skip", 0, \%args);
my $plot_type = get_arg("p", "surf", \%args);
my $column_string=get_arg("c", "0,1", \%args);
my $infile=get_arg("if", 0, \%args) or die "input file required!\n";
my $outfile=get_arg("of", 0, \%args) or die "output file required!\n";


$skip++;

my @columns=split /,/,$column_string;
my $sort_string="";
my $id=int(rand()*100000000);

for my $i (0..$#columns){ $sort_string.="-c$i $i -n$i " }

print `body.pl $skip -1 <$infile | modify_column.pl -bins $bins -c $column_string | cut.pl -f $column_string -0 | sed 's/\t/_/' | compute_column_stats.pl -skip 0 -skipc 0 -types 0 -c 0 -count | cut.pl -f 1 -i | sed 's/_/\t/' | sort.pl $sort_string > tmp_$id.tab`;


my $matlabPath = "matlab";

my $matlab_script="d=load('tmp_$id.tab');[X,Y]=meshgrid([min(d(:,1)):(max(d(:,1))-min(d(:,1)))/$bins:max(d(:,1))],[min(d(:,2)):(max(d(:,2))-min(d(:,2)))/$bins:max(d(:,2))]);Z=griddata(d(:,1),d(:,2),d(:,3),X,Y);$plot_type(X,Y,Z);saveas(gcf,'$outfile','fig');\n";

open MAT,">tmp_$id.m";
print MAT $matlab_script;
close MAT;

`$matlabPath -nodesktop -nojvm -nodisplay -nosplash -r \"tmp_$id; exit;\"`;

`rm tmp_$id.tab tmp_$id.m`;



__DATA__

plot_2d_histogram.pl

bins two dimensional data and counts the number of instances in each bin.
output is graphical (matlab).

  options:

  -b <num>:          number of bins in each dimension (default=20)
  -c <str>:          columns separated by comma (default = 0,1)
  -if <str>:         input file (required)
  -of <str>:         output file (required) (matlab fig format)
  -skip <num>:       number of rows to skip (default=0)
  -plot_type <str>:  surf/surfl/surfc/mesh/meshc/meshz/waterfall/contour/contour3/contourf

