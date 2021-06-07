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

my @selected_features;
my $counter=0;
my %chr_ind;
my $chr_count=0;

while(my $line=<$file_ref>){
  chomp $line;
  (my $chr,my $name,my $start,my $end,my $data)=split /\t/,$line,5;
  my $left=$start<$end?$start:$end;
  my $right=$start>$end?$start:$end;
  if (!exists($chr_ind{$chr})){
    $chr_ind{$chr}=$chr_count++;
  }
  my $intersects=0;
  foreach my $i (@{$selected_features[$chr_ind{$chr}]}){
    if($$i{left}<=$right and $$i{right}>=$left){
      $intersects=1;
      last;
    }
  }
  if($intersects==0){
    my %new_feature;
    $new_feature{chr}=$chr;
    $new_feature{name}=$name;
    $new_feature{start}=$start;
    $new_feature{end}=$end;
    $new_feature{left}=$left;
    $new_feature{right}=$right;
    $new_feature{data}=$data;
    push @{$selected_features[$chr_ind{$chr}]},\%new_feature;
  }
}

foreach my $c (values %chr_ind){
  foreach my $i (@{$selected_features[$c]}){
    print $$i{chr},"\t",$$i{name},"\t",$$i{start},"\t",$$i{end},"\t",$$i{data},"\n";
  }
}


__DATA__

aggregate_genomic_features.pl

greedy aggregation of features in a chr file. goes through a chr file and disposes any feature that
intersects with a previous feature (i.e. features at the beginning of the file will be the most "dominant").
NOTE: list of selected features is maintained in memory.

