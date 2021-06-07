#!/usr/bin/perl

use strict;

my $genie_dir = "$ENV{HOME}/develop/genie";
my $genie_release_dir = "$ENV{HOME}/develop/genie_release";

my $exec_str = "cd $genie_dir; ";
$exec_str   .= "sys2cygwin.pl -genie -full; ";
$exec_str   .= "cd $genie_release_dir; ";
$exec_str   .= "unzip -o $genie_dir/genie.zip; ";
$exec_str   .= "cp Makefile.common.bak Makefile.common; ";
$exec_str   .= "cd Programs; ";
$exec_str   .= "make depend; ";
$exec_str   .= "make; ";

system($exec_str);

__DATA__

syntax: make_genie_release.pl

