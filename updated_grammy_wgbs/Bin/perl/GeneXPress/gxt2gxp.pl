#!/usr/bin/perl

use strict;

if (scalar(@ARGV)==0 or $ARGV[0] eq "--help") { die("gxt2gxp.pl\n\nRecieves a list of gxt files and combines them into a gxp file.\n\n") }

print"<?xml version='1.0' encoding='iso-8859-1'?>\n";

print '
<GeneXPress>
<TSCRawData NumExperiments="1">
GENE	NAME	DESCRIPTION	A	
G	N		1.0	
</TSCRawData>
<GeneXPressObjects>
<Objects  Type="Genes" >
<Gene Id="0" ORF="G">
</Gene>
</Objects>
<Objects Type="Experiments">
<Experiment Id="0" name="A">
</Experiment>
</Objects>
</GeneXPressObjects>
<TSCHierarchyClusterData NumClusters="1">
<Root ClusterNum="0" NumChildren="0" >
</Root>
</TSCHierarchyClusterData>
';

my @names;
my %name_check;

for my $i (@ARGV){
  open(IN,$i);
  my $header=<IN>;
  $header=~/Name=\"(.*)\" Organism=/;
  my $name=$1;
  my $suffix="";
  if (exists($name_check{$name})){
    $name_check{$name}++;
    $suffix="-".$name_check{$name};
  }
  else{
    $name_check{$name}=0;
  }
  my $new_name=$name.$suffix;
  push @names,$new_name;
  $name_check{$name}++;
  $header =~ s/Name=\".*\" Organism=/Name=\"$new_name\" Organism=/;
  print $header;
  while(<IN>){ print };
  print "\n";
  close(IN);
}

print '<ChromosomeDisplay ChromosomeTracks="';
print join(";",@names);
print '" DisplayLeadingTrackLocationNames="true" MaxChromosomePixelWidth="800" ChromosomeFont="SansSerif.bold,1,10" BackgroundColor="255,255,255,255" UserSelectedRegionBorderColor="255,0,0,255" LeftBorderWidth="300" UserSelectedRegionBorderSize="2" HorizontalPaddingColor="192,192,192,255" HorizontalPaddingWidth="0" VerticalPaddingColor="192,192,192,255" VerticalPaddingWidth="0" LeadingTrackLocationNamesHeight="200" LeadingTrackLocationWidth="10" LocationNamesDisplay="Description" >
</ChromosomeDisplay>

<GeneXPressClusterLists>
</GeneXPressClusterLists>
</GeneXPress>
';
