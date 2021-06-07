#!/usr/bin/perl
use Getopt::Long;

my $tag="";
GetOptions  ("str=s"	=>  \$tag);

while (<STDIN>)
{
    die unless /\@(\S+)[\s\n]/;
    $name=$1;
    $seq=<STDIN>; chomp($seq);
    $plus=<STDIN>;
    die unless $plus eq "+\n";
    $qual=<STDIN>; chomp($qual);
    print "@" . $name . $tag . "\n$seq\n+\n$qual\n";
}
