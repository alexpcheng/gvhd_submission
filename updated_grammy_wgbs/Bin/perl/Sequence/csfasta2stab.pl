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


my @transform = ([["A",0],["C",1],["G",2],["T",3]],
                 [["C",1],["A",0],["T",3],["G",2]],
                 [["G",2],["T",3],["A",0],["C",1]],
                 [["T",3],["G",2],["C",1],["A",0]]);

my $state;

while(<$file_ref>)
{
  chomp;
  if(/\S/)
  {
      if(/^[ ]*#/)
      {
	  next;
      }
      if(/^[ ]*>/)
      {
	  s/^[ ]*>[ ]*//;
	  print "$_\t";
      }
      else
      {
	  my @chars = split(//);
	  if ($chars[0] eq "A") {$state = 0;}
	  elsif ($chars[0] eq "C") {$state = 1;}
	  elsif ($chars[0] eq "G") {$state = 2;}
	  else {$state = 3;}
	  #convert numbers to characters
	  for (my $i=1 ; $i<=$#chars ; $i++)
	  {
	      print "$transform[$state][$chars[$i]][0]";
	      $state = $transform[$state][$chars[$i]][1];
	  }
	  print "\n";
      }
  }
}




__DATA__

 csfasta2stab.pl  <csfasta file>

    convert color space (AB SOLiD sequencing) file format into a letter space file format




