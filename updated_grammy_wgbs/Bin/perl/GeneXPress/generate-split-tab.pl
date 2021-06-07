#! /usr/bin/perl -w
use strict;

# Usage: generate-split-tab <split-info-file> [c]
# c - consider the whole split

my $file = $ARGV[0];
my $complete = "";
if ($ARGV[1]) { $complete = $ARGV[1]; }
if (@ARGV < 1) { die "Usage: generate-split-tab <split-info-file> [c]\nc - consider the whole split\n"; }
open (IN,"$file") || die "cannot open $file\n";

my $next;
my %main_hash;
my %splits;
my $count=1;

while ($next = <IN>)
{
    chomp $next;
    my @values = split("\t",$next);
    my @left = split(";",$values[3]);
    my @right = split(";",$values[4]);
    my @all = (@left,@right);

    if ($complete)
    {
	my $split_name = ("sp$count: $values[0]_$values[1]");
	update_hash($split_name, \@all);
	$splits{ $split_name } = 1;
    }
    else 
    { 
	my $split_name_l = ("sp$count: $values[0]_$values[1]_left");
	my $split_name_r = ("sp$count: $values[0]_$values[1]_right");
	update_hash($split_name_l, \@left);
	update_hash($split_name_r, \@right);
	$splits{ $split_name_l } = 1;
	$splits{ $split_name_r } = 1;
    }
    $count++;
}

my @spl = keys(%splits);
my $header = join("\t",@spl);
print "Name\tDesc\t$header\n";

while ( my ($n,$ref) = each (%main_hash) )
{

    print "$n\t$n";
    for (my $i=0;$i<=$#spl;$i++)
    {
	print "\t".find($ref,$spl[$i]);
    }
    print "\n";
} 


sub update_hash
{
    my $spl_name = shift;
    my $arr_ref = shift;
    my $t;
    
    foreach $t (@$arr_ref)
    {
	if ( !defined ($main_hash{ $t }) ) { $main_hash{ $t } = [ $spl_name ]; }
	else { 
	    my $ref = $main_hash{ $t };
	    push(@$ref,$spl_name);
	}
    }    
}

sub find
{
    my $arref = shift;
    my $query = shift;
    my @ar = @$arref;
    my $v;
    foreach $v (@ar)
    {
	if ($v eq $query) 
	{ return 1;}
    }
    return 0;
}
