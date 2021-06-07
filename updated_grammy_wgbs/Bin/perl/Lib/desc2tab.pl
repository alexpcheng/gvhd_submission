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

my $start_entity = get_arg("s", "ID", \%args);
my $end_entity = get_arg("e", "//", \%args);

my @ids;
my %ids2ids;
my $done = 0;
my $num_ids = 0;
while ($done == 0)
{
  my $id = get_arg($num_ids + 1, "", \%args);
  if (length($id) > 0)
  {
      #print STDERR "PUSHING $id\n";
      push(@ids, $id);
      $ids2ids{$id} = $num_ids;
      $num_ids++;
  }
  else
  {
      $done = 1;
  }
}

my @values;
while(<$file_ref>)
{
  chop;

  /^([^ ]+)[ ]+(.*)/;

  my $id = $1;
  my $value = $2;

  if ($id eq $start_entity)
  {
      $value =~ /^([^ ]+)/;
      print "$1";
  }
  elsif ($_ eq $end_entity)
  {
      for (my $i = 0; $i < $num_ids; $i++)
      {
	  print "\t$values[$i]";
      }
      print "\n";
      @values = ();
  }
  elsif (length($ids2ids{$id}) > 0)
  {
      $values[$ids2ids{$id}] .= $value;
      #print STDERR "values[$ids2ids{$id}] = $value\n";
  }  
}

__DATA__

desc2tab.pl <file>

   Takes in a file with a format of identifiers in each line with 
   a predefined terminator for each entry

   -s <str>:   The string used to identify the beginning of an entity (default: ID)
   -e <str>:   The string used to identify the end of an entity (default: //)

   -1 <str>:   <str> is the first identifier to extract (e.g., str = OS)
   -2 <str>:   <str> is the second identifier to extract (specify as many identifiers as you like)
   .
   .
   .

