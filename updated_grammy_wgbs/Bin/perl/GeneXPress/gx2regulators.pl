#!/usr/bin/perl

use strict;

require "$ENV{DEVELOP_HOME}/perl/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $gx_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $genesplit = get_arg("genesplit", "g_module", \%args);

my @stack;
my @stack_split_values;
my $stack_level = 0;
my $last_module = -1;
my $last_module_stack_level;
my $num_module_changes = 0;

open(GX_FILE, "<$gx_file") or die "could not open genexpress file\n";
while(<GX_FILE>)
{
  chop;

  if (/^[ ]*[\<]Root[ ]ClusterNum=[\"]([0-9]+)[\"]/ or /^[ ]*[\<]Child[ ]ClusterNum=[\"]([0-9]+)[\"]/)
  {
    my $cluster_num = $1;

    if (/SplitAttribute/)
    {
      /SplitAttribute=[\"]([^\"]+)[\"]/;
      my $split_attribute = $1;

      /SplitValue=[\"]([^\"]+)[\"]/;
      my $split_value = $1;

      if ($split_attribute ne $genesplit and $stack[$stack_level - 1] eq $genesplit)
      {
	$last_module = $cluster_num;
	$last_module_stack_level = $stack_level;

	$num_module_changes++;
      }

      if ($split_attribute ne $genesplit)
      {
	my $depth = $stack_level - $last_module_stack_level + 1;
	my $module_split_value = $stack_split_values[$last_module_stack_level - 1];

	if ($num_module_changes == 1)
	{
	  $module_split_value++;
	}

	print "$module_split_value\t$last_module\t$split_attribute\t$depth\n";
      }

      $stack[$stack_level] = $split_attribute;
      $stack_split_values[$stack_level] = $split_value;
    }

    $stack_level++;
  }
  elsif (/^[ ]+[\<][\/]Root[\>]/ or /^[ ]+[\<][\/]Child[\>]/)
  {
    $stack_level--;
  }
}

__DATA__

gx2regulators.pl <gx file>

    Takes a GeneXPress file and extracts the regulators of each module.

   -genesplit <name>:   Name of the split on genes (default: g_module)

