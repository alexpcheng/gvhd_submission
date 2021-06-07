#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

#my $species = get_arg("s", "", \%args);


my $current_id;
my $new_TF_need_to_update_id = 0;


while(<$file_ref>)
{
  chop;
  
  # new TF
  if (/^[\/][\/]/)
  {
	$new_TF_need_to_update_id = 1;
  }
  elsif (/ID[ ]+[^ ]+[\$]([^ ]+)/)
  {
      $current_id = $1;
	  if ($new_TF_need_to_update_id == 1)
	  {
		$new_TF_need_to_update_id = 0;
	  }
	  else
	  {
		print STRERR "Got 2 names for the same TF:$current_id \n";
		$new_TF_need_to_update_id = 0
	  }
  }
  elsif (/BS[ ]+([^ ]+); ([^ ]+);/)
  {
	print STDERR "$_\n";
	print STDERR "first exp:$1|\n";
	print STDERR "second exp:$2|\n";
	
	print STDOUT "$current_id\t$2\t$1\n";
  }
  
}



__DATA__

parse_transfac_matrix_2_bs.pl <transfac matrix.dat file>

   Parses a transfac matrix.dat file



