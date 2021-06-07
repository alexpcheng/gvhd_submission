#!/usr/bin/perl

# Computes some statistics for fasta file
# reads file from standard input, uses $ARGV[0] as optional prefix

use Getopt::Long;

my $help=0;
my $quality_shift=33+31;
my $prefix="";
my $min_length=0;
my $histogram="";
GetOptions  ("prefix=s"    	=>  \$prefix,
             "min-length=i"	=>  \$min_length,
             "histogram=s"	=>  \$histogram,
             "help" =>  \$help);

if ($help)
{
    print "\nfasta2stats.pl prints some basic stats about fasta files\n\n";
    print "Usage: cat my.fasta |fasta2stats.pl --prefix assembly --min-length=1000 \n";
    exit(1);
}
while (<STDIN>)
{


    if(/^>/)
    {
	push(@lst,$len) if $len>$min_length;
	$len=0;
    }
    else
    {
	chomp;
	$len+=length($_);
	
    }

}


push(@lst,$len) if $len;
@lst=sort {$b <=>$a} @lst;

$max=0;
foreach (@lst){$total+=$_; $max=$_ if $max < $_; }

print $prefix."total\t$total\n";
print $prefix."longest\t$max\n";
print $prefix."count\t".scalar(@lst)."\n";

#exit(0) unless $total;

print $prefix."average\t".int($total/scalar(@lst))."\n" if scalar (@lst);

$i=0;
#N50
$sum=$lst[$i];
while ($sum<$total*0.5)
{
$i++;
$sum+=$lst[$i];
}

print $prefix."N50\t".$lst[$i]."\n";


$i=0;
#N90
$sum=$lst[$i];
while ($sum<$total*0.9)
{
$i++;
$sum+=$lst[$i];
}

print $prefix."N90\t".$lst[$i]."\n";

if ($histogram)
{
    $tmp=`mktemp`;
    chomp($tmp);
    open(OUT,">$tmp");
    foreach (@lst)
    {	print OUT "$_\n";}
    close OUT;

    open(R,"|R --no-save");
    
    print R "png(file=\"$histogram\")\n";
    print R "cv<-read.table('$tmp')\n";
    while (<DATA>)
    {
    
    print R;
    }
    close R;
}


__DATA__
hist(cv[[1]], main="Sequence length distribution",xlab="length(bp)",breaks=25)
dev.off()
