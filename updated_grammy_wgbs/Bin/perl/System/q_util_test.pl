#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "q_util.pl";


print "Q util test\n";

my @arr1;

$arr1[0] = "ls;";
#$arr1[1] = "ls;";
#$arr1[2] = "ls;";
 

&run_parallel_q_processes(\@arr1, 1, 1, 0, 6,40,1);
