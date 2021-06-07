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

my $platform_ids = get_arg("p", "GB_ACC", \%args);
my $delim        = get_arg("d", "::", \%args);

my @platform_id = split(/,/, $platform_ids);

my $inside_platform = 0;
my $current_platform = "";
my @value_column;

my %data;
my %id_refs;
my @id_refs_vec;
my %sample_ids;
my @sample_ids_vec;
my %sample_ids2names;
while (<$file_ref>)
{
   chop;
   
   if (/^\^platform = (GPL[0-9]+)/i)
   {
      while ($#value_column >= 0)
      {
	 pop(@value_column);
      }

      $inside_platform = 0;
      $current_platform = $1;
      
      if (length($sample_ids{$current_platform}) == 0)
      {
	 $sample_ids{$current_platform} = "1";
	 push(@sample_ids_vec, $current_platform);
      }
   }
   elsif (/^\^sample = (GSM[0-9]+)/i)
   {
      $inside_platform = 0;
   }
   elsif (/^\!Platform_title = (.*)/i)
   {
      $sample_ids2names{$current_platform} = $1;
   }
   elsif (/^ID	/i)
   {
      my $found = 1;
      for (my $i = 0; $i <= $#platform_id; $i++)
      {
	 #print STDERR "Searching platform $platform_id[$i]\n";
	 if (/$platform_id[$i]/i and $found == 1)
	 {
	    $found = 1;
	 }
	 else
	 {
	    $found = 0;
	 }
      }
      if ($found == 1)
      {
	 $inside_platform = 1;
	 
	 my @row = split(/\t/);
	 my $n_id = 0;

	 for (my $i = 0; $i < @row; $i++)
	 {
	    if ($row[$i] eq "$platform_id[$n_id]") 
	    { 
	       push(@value_column, $i); 
	       print STDERR "Found column $platform_id[$n_id] [$value_column[$n_id]]\n";
	       $n_id++;
	    }
	 }
      }
   }
   elsif ($inside_platform == 1)
   {
      my @row = split(/\t/);
      
      my @values_list;
      for (my $i = 0; $i <= $#platform_id; $i++)
      {
	 push(@values_list, $row[$value_column[$i]]);
      }

      $data{"$row[0]"}{"$current_platform"} = join ($delim, @values_list);
      
      if (length($id_refs{$row[0]}) == 0)
      {
	 $id_refs{$row[0]} = "1";
	 push(@id_refs_vec, $row[0]);
      }
   }
}

print "ID";
foreach my $sample_id (@sample_ids_vec)
{
   print "\t";
   
   #print "$sample_ids2names{$sample_id}";
   print "$sample_id";
}
print "\n";

foreach my $id_ref (@id_refs_vec)
{
   print "$id_ref";
   
   foreach my $sample_id (@sample_ids_vec)
   {
      print "\t" . $data{"$id_ref"}{"$sample_id"};
   }
    
   print "\n";
}

__DATA__
    
   parse_gse_platform.pl <source file>

   Parse a GSE file and extract a mapping from its ID to a platform ID

   -p <str>: The platform ID to extract (default: GB_ACC)
             Multiple columns ID can be specified (comma seperated)

   -d: The delimiter to join the multi-columns values (default: "::").
       
