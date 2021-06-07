#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $mapfile = get_arg("m", "", \%args);

my @changes;

open(MAP,$mapfile) or die ("cant find map file!");
while(<MAP>){
  /^(\S+)\t(\S+)\t(\S+)/;
  my %tmp=("chr"=>$1,"pos"=>$2,"change"=>$3);
  push @changes, \%tmp;
}
close (MAP);

while(<STDIN>){
  chomp;
  my @line=split/\t/;
  my $erase_feature=0;
  my $direction=$line[2]<$line[3]?1:-1;
  my $left=$direction==1?$line[2]:$line[3];
  my $right=$direction==1?$line[3]:$line[2];

  for my $c (@changes) {
    if($line[0] eq $$c{chr}){
      if($left>=$$c{pos}){
	$left+=$$c{change};
	if($left<$$c{pos}){
	  $left=$$c{pos};
	}
      }
      if($right>=$$c{pos}){
	$right+=$$c{change};
	if($right<$$c{pos}){
	  $right=$$c{pos}-1;
	}
      }
      if ($right<$left){
	$erase_feature=1;
	last;
      }
    }
  }
  if ($direction==1){$line[2]=$left;$line[3]=$right}
  else{$line[3]=$left;$line[2]=$right}
  if (!$erase_feature){print join("\t",@line),"\n"}
}


__DATA__

translate_chr_genome_version.pl

convert a chr file from one coordinate set to another.
format of map file: <chromosome>\t<position>\t<change> , where <change> = 3 means
insertion of 3 bps at this position , <change> = -3 means deletion of 3 bps.

IMPORTANT: Changes in map file must should be in chronological order, since the
changes are applied incrementally.

  -m <str> :      map file
