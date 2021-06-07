#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $gx_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $genesplit = get_arg("genesplit", "g_module", \%args);

my @stack;
my @stack_branch;
my @stack_split_values;
my $stack_level = 0;
my $largest_module_num = 0;

my %modulenum2clusternum;

open(GX_FILE, "<$gx_file") or die "could not open genexpress file\n";
while(<GX_FILE>)
{
  chop;

  if (/^[ ]*[\<]Root[ ]ClusterNum=[\"]([0-9]+)[\"]/ or
      /^[ ]*[\<]Child[ ]ClusterNum=[\"]([0-9]+)[\"]/)
  {
    my $cluster_num = $1;

    if ($stack_level > 0)
    {
      if (length($stack_branch[$stack_level - 1]) == 0 or $stack_branch[$stack_level - 1] == 0) { $stack_branch[$stack_level - 1] = 1; }
      else { $stack_branch[$stack_level - 1]++; }

      #print "Clusternum=$cluster_num is branch $stack_branch[$stack_level - 1] of its parent ";
      #print "which splits on $stack[$stack_level - 1] with value=$stack_split_values[$stack_level - 1]\n";
    }

    if (/SplitAttribute/)
    {
      /SplitAttribute=[\"]([^\"]+)[\"]/;
      my $split_attribute = $1;

      /SplitValue=[\"]([^\"]+)[\"]/;
      my $split_value = $1;

      $stack[$stack_level] = $split_attribute;
      $stack_split_values[$stack_level] = $split_value;
    }

    if ($stack[$stack_level] eq $genesplit and $stack_split_values[$stack_level] > $largest_module_num)
    {
      $largest_module_num = $stack_split_values[$stack_level];
    }

    if ($stack_level > 0)
    {
      if ($stack[$stack_level] ne $genesplit and $stack[$stack_level - 1] eq $genesplit)
      {
	my $module_num = &get_module_num();
	#print STDERR "$cluster_num\t$module_num\n";
	$modulenum2clusternum{$module_num} = $cluster_num;
      }
    }

    $stack_level++;
  }
  elsif (/^[ ]*[\<][\/]Root[\>]/ or /^[ ]*[\<][\/]Child[\>]/)
  {
    $stack_level--;

    $stack_branch[$stack_level] = 0;
    $stack[$stack_level] = "";
    $stack_split_values[$stack_level] = "";
  }
}

my $genesplit_index = 0;
open(GX_FILE, "<$gx_file") or die "could not open genexpress file\n";
while(<GX_FILE>)
{
  chop;

  if (/<GeneXPressAttributes/)
  {
    my $line = <GX_FILE>;
    while (not($line =~ /<[\/]GeneXPressAttributes>/))
    {
      $line =~ /Attribute.*Name=[\"]([^\"]+)[\"].*Id=[\"]([^\"]+)[\"]/;
      my $split = $1;
      my $id = $2;

      if ($split eq $genesplit)
      {
	$genesplit_index = $id;
	#print "found at index $genesplit_index\n";
      }

      $line = <GX_FILE>;
    }
  }

  if (/^[ ]*[\<]Gene.*ORF=[\"]([^\"]+)[\"]/)
  {
    my $gene = $1;

    my $line = <GX_FILE>;
    chop $line;

    $line =~ /[\<]Attributes.*Value=[\"]([^\"]+)[\"]/;
    my $values = $1;

    my @row = split(/\;/, $values);
    my $modulenum = $row[$genesplit_index];

    my $value = $modulenum2clusternum{$modulenum};

    print "$gene\t$value\t$modulenum\n";
  }
}

sub get_module_num
{
  my $res = $largest_module_num + 1;

  for (my $i = 0; $i < $stack_level; $i++)
  {
    if ($stack[$i] eq $genesplit and $stack_branch[$i] == 2)
    {
      $res = $stack_split_values[$i];
    }
  }

  return $res;
}

__DATA__

gx2clusters.pl <gx file>

    Takes a GeneXPress file and extracts the regulators of each module.

   -genesplit <name>:   Name of the split on genes (default: g_module)

