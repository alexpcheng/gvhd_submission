#!/usr/bin/perl

use strict;
use Getopt::Long;

my $name   = "";
my $memory = "12G";
my $xlmemory = "";
my $verbose  = "";
my $priority  = "";
my $queue = "long.q";

GetOptions ("name=s" => \$name,
		    "mem=s"  => \$memory,
		    "xlmem=s" => \$xlmemory,
		    "p=s"    => \$priority,
		    "q=s"    => \$queue,
		    "v!"     => \$verbose );

my $cmd = join(" ", @ARGV);
$cmd =~ s/;+$//;

if ($name eq "")
{
	$name = $cmd;
	$name =~ s/^make //g;
	$name =~ s/^*.run //g;
	$name =~ s/^run.* //g;
	$name =~ s/\S*=//g;
	$name =~ s/[^\w]/_/g;
}

my $rs = sprintf ("%06d", int(rand(100000)));

my $namers = $name . "_" . $rs;

my $memorystr = "mem_token=$memory";

if ($xlmemory)
{
	$memorystr = "xlmem_token=$xlmemory";
}
	

my $outfn = "$ENV{SOUP_BASE}/SGE/output/$ENV{USER}" . "_" . "$namers.out";
my $errfn = "$ENV{SOUP_BASE}/SGE/output/$ENV{USER}" . "_" . "$namers.err";

open(OUTFILE, ">$ENV{SOUP_BASE}/SGE/jobs/$ENV{USER}_$namers.csh");
print OUTFILE <<EOF;
#!/bin/bash
#\$ -S /bin/bash
#\$ -N $namers
#\$ -o $outfn
#\$ -e $errfn
#\$ -cwd
#\$ -l $memorystr
echo ============================================================================ ;
echo ============================================================================ >&2 ;
echo Cmd: $cmd;
echo Host: `hostname`;
echo Pwd: `pwd`;
echo Date start: `date`;
echo ============================================================================;
/usr/bin/time -v $cmd;
echo ============================================================================;
echo Date end: `date`;
EOF
close OUTFILE;

my $priority_str = "";
if ($priority)
{
	$priority_str = "-p -$priority"
}

my $exec_str = "qsub -q $queue $priority_str -V -cwd $ENV{SOUP_BASE}/SGE/jobs/$ENV{USER}_$namers.csh" ;

if ($verbose){
    print STDERR "Executing: $exec_str...\n";
}

system($exec_str) == 0
        or die "system $exec_str failed: $?"