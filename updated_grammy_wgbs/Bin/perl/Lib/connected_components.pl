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

my $print_max = get_arg("max", 0, \%args);
my $print_representative = get_arg("rep", 0, \%args);
my $print_component_size = get_arg("s", 0, \%args);

my %nodes2ids;
my @ids2nodes;
my $num_nodes = 0;

my @edges;

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $node1 = &add_node($row[0]);
  my $node2 = &add_node($row[1]);

  $edges[$node1][$node2] = 1;
  $edges[$node2][$node1] = 1;
}

my %handled_nodes;
my @component_sizes;
my $num_connected_components = 0;

for (my $i = 0; $i < $num_nodes; $i++)
{
  if (length($handled_nodes{$i}) == 0)
  {
    if ($print_max == 0)
    {
	print "Connected Component $num_connected_components";

	if ($print_representative == 1)
	{
	    print "\t$ids2nodes[$i]";
	}

	print "\n";
    }
    $num_connected_components++;
    &expand_node($i);
  }
}

my $max = 0;
for (my $i = 0; $i < @component_sizes; $i++)
{
  if ($print_max == 0 and $print_component_size == 1) { print "Component $i size: $component_sizes[$i]\n"; }
  if ($component_sizes[$i] > $max) { $max = $component_sizes[$i]; }
}

if ($print_max == 1) { print "$max\n"; }

sub expand_node
{
  my ($node_id) = @_;

  if (length($handled_nodes{$node_id}) == 0)
  {
    $handled_nodes{$node_id} = "1";

    if ($print_max == 0) { print "$node_id\t$ids2nodes[$node_id]\t" . ($num_connected_components - 1) . "\n"; }

    $component_sizes[$num_connected_components - 1]++;

    for (my $i = 0; $i < $num_nodes; $i++)
    {
      if ($edges[$node_id][$i] == 1)
      {
	expand_node($i);
      }
    }
  }
}

sub add_node
{
  my ($node_name) = @_;

  my $node_id = $nodes2ids{$node_name};

  if (length($node_id) == 0)
  {
    $nodes2ids{$node_name} = $num_nodes;
    $ids2nodes[$num_nodes] = $node_name;
    $num_nodes++;
  }

  $node_id = $nodes2ids{$node_name};

  return $node_id;
}


__DATA__

connected_components.pl <data file>

   Computes the connected components of the data file.
   Each line in the data file corresponds to an edge 
   between the keys in the first two columns of the data file.

  -max: Just prints the size of the largest component

  -rep: Print a representative from each connected component 

  -s:   Print the size of each component
