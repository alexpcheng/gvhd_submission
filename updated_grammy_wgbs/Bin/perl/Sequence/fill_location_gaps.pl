#!/usr/bin/perl

use strict;

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

my $fill_string = get_arg("s", "", \%args);
my $force_fill = get_arg("f", 0, \%args);
my $promoter_type = get_arg("p", 0, \%args);

my $previous_chr;
my $previous_name;
my $previous_left=0;
my $previous_right=0;
my $previous_orientation=1;

while(<$file_ref>)
{
    chomp;

    my @row = split /\t/;
    
    my $chr=$row[0];
    my $right = $row[2]>$row[3]?$row[2]:$row[3];
    my $left = $row[2]<$row[3]?$row[2]:$row[3];
    my $orientation = $row[2]<$row[3]?1:-1;
    my $name = $row[1];
    
    if ($chr ne $previous_chr) {
	$previous_right=$left;
    }
    if ($left>$previous_right+1 or ($force_fill==1 and $chr==$previous_chr)){
	print "$chr\t$previous_name...$name\t",$previous_right+1,"\t",$left-1;
	if ($fill_string ne "") { print "\t$fill_string" }
	if ($promoter_type == 1) {
	    if ($orientation==$previous_orientation) { print "\tUnique" } 
	    if ($orientation>$previous_orientation) { print "\tDivergent" } 
	    if ($orientation<$previous_orientation) { print "\tConvergent" } 
	}
	print "\n";
    }
    else{
	if ($previous_right>$right){
	    $right=$previous_right;
	    $name=$previous_name;
	    $orientation=$previous_orientation;
	}
    }
    print join("\t",@row),"\n";

    $previous_orientation=$orientation;
    $previous_right=$right;
    $previous_left=$left;
    $previous_name=$name;
    $previous_chr=$chr;
}

__DATA__

fill_location_gaps.pl <file>

   Fill gaps between successive locations with a specified string
   (Useful for placing '0' between nucleosome assignments in a zero-temperature model)

   NOTE 1: Assumes that the input locations are in the format chr\tname\tstart\tend
   NOTE 2: Assumes that the file has been sorted by chromosome and then by minimum of (start,end)

   -s <str>: String to insert after the filled in location

   -f:       Force a fill-in even when there is no gap to fill (works only with non-intersecting locations)

   -p:       Assuming fill-in is intergenic, report whether it is Unique/Divergent/Convergent

