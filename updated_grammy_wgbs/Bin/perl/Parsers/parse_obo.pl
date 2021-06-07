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

my $item_start = get_arg("s", "[Term]", \%args);
my $item_end = get_arg("e", "", \%args);
my $ignore_value = get_arg("e", "", \%args);

my $ignore_item = 0;
my $id = "";
my $name = "";
my $namespace = "";
my %id2parents;
my %id2names;
my %id2namespaces;
my @ids;
while(<$file_ref>)
{
  chop;

  if ($_ eq $item_end)
  {
      if (length($id) > 0 and $ignore_item == 0)
      {
	  $id2names{$id} = "$name";
	  $id2namespaces{$id} = "$namespace";
	  push(@ids, $id);
      }

      $id = "";
      $name = "";
      $ignore_item = 0;
  }
  elsif (/^([^:]+): (.*)/)
  {
      my $term = $1;
      my $value = $2;

      if ($value =~ /(.*) [\!] /)
      {
	  $value = $1;
      }

      if ($term eq "id")
      {
	  $id = $value;
      }
      elsif ($term eq "name")
      {
	  $name = $value;
      }
      elsif ($term eq "namespace")
      {
	  $namespace = $value;
      }
      elsif ($term eq "is_a")
      {
	  $id2parents{$id} .= "$value\t";
      }
      elsif ($term eq "relationship")
      {
	if ($value =~ /^part_of (.*)/)
	{
	  $id2parents{$id} .= "$1\t";
	}
      }
      elsif ($term eq "is_obsolete" and $value eq "true")
      {
	  $ignore_item = 1;
      }
  }
}

my %used_parents;
foreach my $i (@ids)
{
    print "$i\t$id2names{$i}\t$id2namespaces{$i}";

    %used_parents = ();
    
    &PrintParents($i);

    print "\n";
}

sub PrintParents
{
    my ($parent) = @_;

    my @parents = split(/\t/, $id2parents{$parent});
    foreach my $parent (@parents)
    {
	if (length($used_parents{$parent}) == 0)
	{
	    $used_parents{$parent} = 1;
	    print "\t$parent";
	    &PrintParents($parent);
	}
    }
}

__DATA__

parse_obo.pl <file>

   Parses an obo file into a flat hierarchy (e.g., for GO)

   -s <str>: This string starts a new item (default: '[Term]')
   -e <str>: This string ends an item (default: '')

   -i <str>: Items with this string are ignored (default: is_obsolete)

