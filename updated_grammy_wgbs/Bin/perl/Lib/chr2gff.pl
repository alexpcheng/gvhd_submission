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

my $gbrowse_gff  = get_arg("gbrowse", 0, \%args);
my $feature_name = get_arg("f", "my_feature", \%args);
my $source_name = get_arg("s", "Genomica", \%args);
my $nochr = get_arg("nochr", 0, \%args);

while(<$file_ref>)
{
  chop;

  my ($chr, $id, $start, $end, $type, $value) = split(/\t/);

  if ($gbrowse_gff == 0)
  {
     $type =~ s/\s/_/g;
     $id   =~ s/\s/_/g;
     
     if (length($type) == 0)
     {
	$type = '.';
     } 
     
     if (length($id) == 0)
     {
	$id = '.';
     } 
  }
 
  my $strand = '+';
  if ($start > $end)
  {
     my $tmp = $start; 
     $start = $end;
     $end = $tmp;
     $strand = '-';
  }

  if (length($value) == 0)
  {
     $value = '.';
  }

  if (length($chr) > 0 && length($start) > 0 && length($end) > 0)
  {
     if ($gbrowse_gff == 0)
     {
	 if ($nochr == 0) {print "chr"}
	print "$chr\t$type\t$id\t$start\t$end\t$value\t$strand\t.\n";
     }
     else
     {
	my $source = $source_name;
	if ($source_name eq "AuthorYY")
	{
	   if (index($type, "_") > -1)
	   {
	      $source = substr($type, 0, index($type, "_"));
	      $type   = substr($type, index($type, "_")+1);
	   }
	   else
	   {
	      $source = $type;
	      print STDERR "Type (col 5) has no value: $type\n";
	      $type = "";
	   }

	}
	   
	 if ($nochr == 0) {print "chr"}
	 print "$chr\t$source\t$feature_name\t$start\t$end\t$value\t$strand\t.\t$feature_name $type\n";
     }
  }
}

__DATA__

chr2gff.pl <file>

   Takes in a chr file and converts it to a gff file (using gff text fields arbitrary). White spaces in the <type> field will
   be converted to underscores, empty values will be converted to '.'.
   
   chr fields: <chr> <ID> <start> <end> <type> <value>
   will be mapped to the gff file like this:
             chr<chr> <type> <ID> <start> <end> <value> <strand> <dummy value>

   -gbrowse: Produce a GBrowse format gff file:
               chr<chr> Genomica my_features <start> <end> <value> <strand> my_feature <type>

   -f <STR>: Feature name will be STR (relevant only if -gbrowse is specified, default is "my_feature").
   -s <STR>: Source name will be STR, If STR is "AuthorYY" then the source name will be the prefix of the type column (5'th) and this prefix will be removed (relevant only if -gbrowse is specified, default is "Genomica").

