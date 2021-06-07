#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $file =  get_arg("layout", "", \%args);
my $ref_str = get_arg("ref", "", \%args);
my $ref_type = get_arg("ref_type", "1", \%args);
my $include_all = get_arg("include_all", "1", \%args);
my $test;

if (length($file) < 1 )
{
    print "No layout file given!!!\n";
}
if (length($ref_str) < 1 )
{
    print "No reference was given. How am I supposed to make a reference file?!\n";
}

my $ref_wells ="";
my $data_wells="";
my $first_ref=1;
my $first_data=1;

open(FILE, $file) or die("Could not open file '$file'.\n");

my $first_line= <FILE>;
while (<FILE>)
{
    chomp;
    my @values = split(/\t/);
    if ($values[$ref_type] eq $ref_str)
    {
	if ($first_ref)
	{
	    $ref_wells= $values[0];
	    $first_ref =0;
	}
	else
	{
	    $ref_wells= $ref_wells . "," . $values[0];
	}
    }
    if (($values[$ref_type] ne $ref_str) || ($include_all))
     
    {
      if ($first_data)
  	{
  	   $data_wells= $values[0];
  	   $first_data= 0;
        }
      else
        {
	    $data_wells= $data_wells . "," . $values[0];
        }
  }
  
}
print "Matrices\tRef_wells\n";
print "$ref_wells\t$data_wells\n";


#--------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------
sub Exec
{
  my ($exec_str) = @_;
  
  print("Running: [$exec_str]\n");
  system("$exec_str");
}

__DATA__

make_platereader_reference_file.pl

   Creates simple reference files for the plate_reader_analyzer. For more complicated stuff, you'll have to do it yourself....

    -layout <Layout_file>:  The plate layout file.
    -ref <str>:             A string stating the well by which to normalize. For example: medium. This string has to appear in the plate layout file. 
    -ref_type <0-3>:        States the type of the reference:
                            0- Well
                            1- Id
                            2- Alias
                            3- Condition
                            Default is alias
    -include_all <0/1>:     If reference wells also appear as data wells (default = 1)

                            

  

