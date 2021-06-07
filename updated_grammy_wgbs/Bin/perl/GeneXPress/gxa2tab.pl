#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $gxa_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $object_type = get_arg("o", "Gene", \%args);

my @attributes;
my @objects;
my @values;

open(FILE, "<$gxa_file");
while(<FILE>)
{
  chop;

  if (/<Attribute[\s]Name=[\"]([^\"]+)[\"].*/) 
  {
    #print "Pushing $1\n";
    push(@attributes, $1);
  }
  elsif ($object_type eq "Gene" and /<Gene[\s]Id=.*ORF=[\"]([^\"]+)[\"]/)
  {
    push(@objects, $1);
  }
  elsif ($object_type eq "Experiment" and /<Experiment[\s]Id=.*name=[\"]([^\"]+)[\"]/)
  {
    push(@objects, $1);
  }
  elsif (/<Attributes[\s]AttributesGroupId.*Value=[\"]([^\"]+)[\"]/) 
  {
    push(@values, $1);
    #print "value $1\n";
  }
}

print "Attribute";
foreach my $attribute (@attributes)
{
    print "\t$attribute";
}
print "\n";

my $num_columns = @attributes;

for (my $i = 0; $i < @objects; $i++)
{
    print "$objects[$i]";

    my @row = split(/\;/, $values[$i]);

    for (my $i = 0; $i < $num_columns; $i++)
    {
	print "\t$row[$i]";
    }
    print "\n";
}

__DATA__

gxa2tab.pl <gxa file> 

    Takes a gxa file and converts it into a tab file

    -o <type>:    The type of object (Gene/Experiment default: Gene)

