#! /usr/bin/perl -w
#---------------------------------------------------------------------
# Calculates average pearson correlation between the regulator and 
# the target genes in each split. Enables to print out the expression
# matrices of the splits of a given regulator. 
#--------------------------------------------------------------------- 
use strict;
use ParseGene2Module;
use Correlation;
#
# Usage: claculate-splits-correlation.pl <gxp_file> <splits.info file> [regulator]
# 

my %Data;
my %SampleID;
my %Module2Genes;
my $print = 0;

die "Usage: claculate-splits-correlation.pl <gxp_file> <splits.info file> [regulator]\nregulator- print out the expression matrix of regulator splits\n" unless ($#ARGV > 0);
open (GXP,"$ARGV[0]") or die "cannot open $ARGV[0] file\n";
open (INFO,"$ARGV[1]") or die "cannot open $ARGV[1] file\n";

if ( defined($ARGV[2])) { $print = $ARGV[2]; }

parse_expression_matrix();

close GXP;

%Module2Genes = ParseGene2Module::gene2module($ARGV[0]);

my $input;

my $spl_count = 1;

while ($input = <INFO>)
{
    chomp $input;

    my ($regulator, $module, $split, $left, $right) = split("\t",$input);
    
    my %SplitData = build_expression_matrix($regulator,$module,$left,$right);

    if ($print && ($regulator == $print )) { print_output($regulator,$module,$spl_count,\%SplitData); }
    
    my $regulator_exp_ref = $SplitData{ $regulator };
    
    my $correlation_sum = 0;
    my $count = 0;
    print "$regulator\t$module\t";
    while (my ($gene,$ref) = each %SplitData)
    {

	unless (($gene eq $regulator) || ($gene eq "Name"))
	{
	    $count++;
	    my $corr = Correlation::pearson($regulator_exp_ref, $ref);
	    $correlation_sum += $corr;
	    
	}
    }
    
    my $avg_corr = $correlation_sum/$count;
    print "$avg_corr\n";
    $spl_count++;
}

close INFO;


sub print_output
{
 
    my $out_file = "$_[0]_$_[1]_$_[2]";
    my $hash_ref = $_[3];
    my %hash = %$hash_ref;
    open (OUT,">$out_file") || die "cannot open output file\n";
    while (my ($gene,$ref) = each %hash)
    {
	my $output = join "\t",($gene,@$ref);
	print OUT $output."\n";
    }
    close OUT;

}

sub parse_expression_matrix
{
    my $next;
    while ($next = <GXP>) { last if (open_tag($next) eq "TSCRawData"); }
    $next = <GXP>;
    chomp $next;
    my @header = split ("\t",$next);
    shift @header; #Gene
    shift @header; #Name
    shift @header; #Desc
    $Data{ "Name" } = \@header;

    for (my $i=0 ; $i <= $#header ; $i++)
    {
	$SampleID{ $header[$i] } = $i;
    }
    
    while ($next = <GXP>) 
    {
	chomp $next;
	last if (close_tag($next) eq "TSCRawData");
	my @row = split ("\t",$next);
	my $name = shift @row;
	shift @row; #Name
	shift @row; #Desc
	$Data{ $name } = \@row;
    }
}


sub build_expression_matrix
{ 
    my ($regulator,$module,$left,$right) = @_;
#    print STDERR "builing expression matrix: $regulator\t$module\n";
    my %local_hash;
    my $t;
    my $k;
    my @ids;
    my @keys = ("Name",$regulator,@{$Module2Genes{ $module }});

    my @experiments = (split(";",$left), split(";",$right));

    foreach $t (@experiments) { push(@ids, $SampleID{$t} ); }

    foreach $k (@keys)
    {
	my @all_vals = @{$Data{$k}}; 
	my @values = @all_vals[ @ids ];
	$local_hash{ $k } = \@values;
    }

    return %local_hash;
}


sub open_tag
{
    my $string = shift;
    chomp $string; 
    if (!($string)) { return ""; }
    my @tokens = split(" ",$string);
    if ($tokens[0] =~ m/\<([a-z].*)\b/i)
    {
	return $1;
    }
    else { return ""; }
}

sub close_tag
{
    my $string = shift;
    if (!($string)) { return ""; }
    my @tokens = split(" ",$string);
    if ($tokens[0] =~ m/\<\/([a-z].*)>/i)
    {
	return $1;
    }
    else { return ""; }
}
