#!/usr/bin/perl

use strict;


if ($ARGV[0] eq "--help" or $ARGV[0] eq "")
{
  print STDOUT <DATA>;
  exit;
}
if ($ARGV[0] eq "-f"){
  open(FILE,$ARGV[1]);
  while(my $command=<FILE>){
    chomp $command;
    system("$command &");
    print STDERR "running: $command\n";
  }
  close(FILE);
}
else{
  print system("$ARGV[0] &");
  print STDERR "running: $ARGV[0]\n";
}

__DATA__

run_bg.pl

runs a in job in background (for use in makefiles).

-f <name>:   run jobs listed in the file <name>.


