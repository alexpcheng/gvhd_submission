#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";
require "$ENV{PERL_HOME}/Lib/vector_ops.pl";

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

my $column = get_arg("c", 1, \%args);


my $current_ID = "";
my $lowest = 1;
my $out="";

while (<STDIN>)
{
    my @a=split("\t");
    
	if ($current_ID ne $a[0])
	{
		print $out;
		$current_ID = $a[0];
		$lowest = 1;
	}    

    if ($a[10] < $lowest)
    {
		$lowest = $a[10];
		$out=$_;
    }
}

print $out;



__DATA__

keep_lowest.pl <source file>

   Only keep the row with the lowest number on column <c>.
   Assumes file is sorted by key (column 0)!
   
   -c <num>:          Column of the value to evaluate (default is 1)


