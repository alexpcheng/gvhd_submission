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

my $start_entity = get_arg("s", ">>", \%args);
my $delimiter = get_arg("d", ": ", \%args);
my $value_delimiter = get_arg("del", "\\|", \%args);

my @ids;
my %ids2ids;
my %ids2column_delimiter;
my $done = 0;
my $num_ids = 0;
while ($done == 0)
{
  my $id = get_arg($num_ids + 1, "", \%args);
  if (length($id) > 0)
  {
      print STDERR "PUSHING $id\n";
      push(@ids, $id);
      $ids2ids{$id} = $num_ids;

      my $id_column_delimiter = get_arg(($num_ids + 1) . "c", "0", \%args);
      $ids2column_delimiter{$id} = $id_column_delimiter;

      $num_ids++;
  }
  else
  {
      $done = 1;
  }
}

my @values;
my $id = "";
while(<$file_ref>)
{
  chop;

  if (/^${start_entity}(.*)/)
  {
      print "Printing!!\n";

      if (length($id) > 0) { &PrintEntity(); }

      $id = $1;
      print "$id";
  }
  else
  {
      if (/^([^ ]+)$delimiter(.*)/)
      {
	  my $tag = $1;
	  my $value = $2;
	  
	  print STDERR "delimiter=[$delimiter] tag=[$1] value=[$2]\n";

	  if (length($ids2ids{$tag}) > 0)
	  {
	      #my @row = split(/\|/, $value);
	      my @row = split(/$value_delimiter/, $value);

	      my $n = @row;
	      print "v=$value_delimiter N=$n\n";

	      if (length($values[$ids2ids{$tag}]) > 0) { $values[$ids2ids{$tag}] .= "|"; }
	      $values[$ids2ids{$tag}] .= "$row[$ids2column_delimiter{$tag}]";
		  
	      #print STDERR "$id values[".$ids2ids{$tag}."] = ".$values[$ids2ids{$tag}."]\n";
	  }  
      }
  }
}

sub PrintEntity
{
    for (my $i = 0; $i < $num_ids; $i++)
    {
	print "\t$values[$i]";
    }
    print "\n";
    @values = ();
}

__DATA__

parse_tab_value.pl <file>

   Takes in a tag-value type of file and extracts info

   -s <str>:   The string used to identify the beginning of an entity (default: '>>')

   -d <str>:   Delimiter between the tag and the value (default: ': ')

   -del <str>: Separator between entries in the value column (e.g., A|B|C should extract only A) (default: '|')

   -1 <str>:   <str> is the first tag to extract (e.g., str = PROT)
   -2 <str>:   <str> is the second tag to extract (specify as many identifiers as you like)
   .

   -1c <num>:  When separating values for the first tag, extract the <num> value (default: 0, e.g., set to '1' to get B from A|B|C)
   -2c <num>:  Same as above for the second tag (specify as many tags as you like)
   .

