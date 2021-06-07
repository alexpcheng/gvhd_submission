#!/usr/bin/perl
use Getopt::Long;

my $min_length=0;
GetOptions  ("min-length=i"	=>  \$min_length);
                                       
                                       

while (<STDIN>)
{
    die unless /\@(\S+)[\s\n]/;
    $name=$1;
    $seq=<STDIN>; chomp($seq);
    $plus=<STDIN>;
    die unless $plus eq "+\n";
    $qual=<STDIN>; chomp($qual);
    print "$name\t$seq\t$qual\n" if length($seq)>=$min_length;

}
