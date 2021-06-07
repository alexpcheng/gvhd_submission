#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $keys = get_arg("k", 0, \%args);
my $sorted = get_arg("s", "", \%args);

if ($sorted eq ""){
  system("average_rows.pl @ARGV -k $keys -take_first");
}
else{
  my $file_ref;
  my $file = $ARGV[0];
  if (length($file) < 1 or $file =~ /^-/){
    $file_ref = \*STDIN;
  }
  else{
    open(FILE, $file) or die("Could not open file '$file'.\n");
    $file_ref = \*FILE;
  }
  
  
  my @prev_ln;
  
  my @k=split/,/,$keys;
  while (my $line=<$file_ref>){
    chomp $line;
    my @ln=split /\t/,$line;
    my $printed=0;
    for(@k){
      if ($printed==0 and $ln[$_] ne $prev_ln[$_]){
	print "$line\n";
	$printed=1;
	}
    }
    @prev_ln=@ln;
  }
}



__DATA__

uniq.pl <source file>

   Unique rows in <source file> that have the same key

   -k <num>: Row of the key (default is 0)
             NOTE: an index of multiple keys may be specified with commas (e.g., -k 1,4,5)

   -s:       file is sorted.

