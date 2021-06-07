#! /usr/bin/perl -w
use strict;

die "Usage: parse-split-information.pl <GXP file>\nOutput list:\n<gene> <module> <split value> <left class samples> <right class samples>\n" if (scalar(@ARGV)<1);

my $in = $ARGV[0];
my %reg2exp;
my %regInd;
my @samples;
my $left = 0;
my $right = 1;
my $next;

open (GXP,"$in") || die "cannot open $in\n";

# ----------------- skip irrelevant rows -----------------

while ($next = <GXP>) 
{
    chomp $next;
    last if (open_tag($next) eq "GeneXPressAttributes");
}


# ----------------- parse list of regulators --------------------

my $count = 0;
while ($next = <GXP>)
{
    chomp $next;
    if ((open_tag($next) eq "Attribute") && !(attribute_value($next,"Name") eq "g_module"))
#(attribute_value($next,"Value") eq "Continuous"))
    {
	my $name = attribute_value($next,"Name");
	$reg2exp{ $name } = {};
	$regInd{ $count } = $name;
	$count++;
    }
    last if (close_tag($next) eq "GeneXPressAttributes");
}

while ($next = <GXP>)
{
    chomp $next;

    if ( (open_tag($next) eq "Objects"))
    { 
	last if (attribute_value($next,"Type") eq "Experiments");
    }
}

# -------------- parse expression of regulators ----------------

while ($next = <GXP>)
{
    chomp $next;
    if (open_tag($next) eq "Experiment")
    {
	
	my $sample = attribute_value($next,"Name");
#	print "processing experiment: $sample\n";
#	print "$next\n";
	push(@samples,$sample);
	$next = <GXP>;
	chomp $next;
	my $values = attribute_value($next,"Value");
	my @exp = split(";",$values);
	# expression values are saved in a hash { exp->sample_name } 
	for (my $i=0 ; $i<= $#exp ; $i++)
	{
	    my $ref = $reg2exp{ $regInd{ $i } }; 
	    $$ref{$sample} = $exp[$i];
	    my @vals = values(%$ref);
	}
    }
    
    last if (open_tag($next) eq "TSCHierarchyClusterData");
}

# ------------------ parse tree ---------------------

while ($next = <GXP>)
{
    chomp $next;
    my $att_val = attribute_value($next,"SplitAttribute"); 
    last if (!($att_val eq "g_module"));
}

do{  
    chomp $next;
    my $cluster = attribute_value($next,"ClusterNum");
    my $depth = 0;
    traverse_successors(\@samples,$cluster,$next, \$depth);
    
} while ($next = <GXP>);



# --------------------------- subroutines ---------------------------------


sub traverse_successors
{
    my $arr_ref = shift; # array of samples that are relevant to the split
    my $cluster = shift; #parent module
    my $read = shift; # current input row
    my $depth_ref = shift;
    my @split_samples = @$arr_ref;

    if ((open_tag($read) eq "Child") && (child_num($read)==0))
    {
	$read = <GXP>; # read close_tag
	return; 
    }
    if ( (open_tag($read) eq "Child") && (child_num($read)>0))
    {
	$$depth_ref++;
	my $reg = attribute_value($read,"SplitAttribute");
	my $spl = attribute_value($read,"SplitValue");

	my @left = get_split_values($reg, $arr_ref ,$spl, $left );
	my @right = get_split_values($reg, $arr_ref, $spl, $right );

	my $left_list = join (";",@left);
	my $right_list = join (";",@right);

	print "$reg\t$cluster\t$spl\t$left_list\t$right_list\n";
	
	$read = <GXP>;
	chomp $read;
	traverse_successors( \@left, $cluster, $read, $depth_ref );
	$read = <GXP>;
	chomp $read;
	traverse_successors( \@right, $cluster, $read, $depth_ref );
	$read = <GXP>; #read close_tag
	$$depth_ref--;
	return; 
   }
  
}


sub get_split_values
{
    my $reg = shift;
    my $arr_ref = shift;
    my $threshold = shift;
    my $dir = shift;
    my @samples_array = @$arr_ref;
    my @answer;
    my $t;
    my $ref = $reg2exp{$reg};
    my %hash = %$ref;

    foreach $t (@samples_array) 
    {
	if ( ($dir==$left) && ($hash{$t} < $threshold))
	{
	    push(@answer,$t);
	}
	elsif ( ($dir==$right) && ($hash{$t} >= $threshold))
	{
	    push(@answer,$t);
	}
    }
    return @answer;
}




sub attribute_value
{
    my $string = shift;
    my $att = shift;
    if (!($string)) { return ""; }
    my @tokens = split(" ",$string);
    my $t;

    foreach $t (@tokens)
    {
	if ($t =~ m/$att=\"(.*)\b/i) 
	{ 
	    my $answer = $1;
	    $answer =~ s/\"//;
	    return $answer; }
    }
    return "";
}

sub child_num
{
    my $string = shift;
    if (!($string)) { return ""; }
    my @tokens = split(" ",$string);
    my $t;

    foreach $t (@tokens)
    {
	if ($t =~ m/NumChildren=\"(.*)\"/i)
	{
	    return $1;
	}
    }
    return -1;
}

sub open_tag
{
    my $string = shift;
    if (!($string)) { return ""; }
    my @tokens = split(" ",$string);
    if ($tokens[0] =~ m/\<([a-z].*)\b/i)
    {
#	print "open tag: $1\n";
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
#	print "close_tag: $1\n";
	return $1;
    }
    else { return ""; }
}

