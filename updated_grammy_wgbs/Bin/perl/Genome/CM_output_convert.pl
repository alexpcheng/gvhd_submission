#!/usr/bin/perl
use strict;

# CMfinder Output motif format:
# Motifs in stored in Stockholm format, with slight changes in the mark-up 
# lines:
# #=GS <seqname> DE <start>..<end> <score>
# #=GS <seqname> WT <weight>
# to indicate the start/end position, alignment score, and weight of
# the motif.

# print help message
if ($ARGV[0] eq "--help") {
  print "CM_output_converter.pl <CMfinder.pl output file> \n";
  exit;
}

# output file
my $out_file = shift(@ARGV);
my FILE = open($out_file);
my %sequences;
my %structures;
my %scores;
my %weights;
my %starts;
my %ends;

while (<FILE>) {
    my $line = $_;

    if ($line =~ m/#=GS\t(\w+)\tWT\t(\w+)/g) {
	$weights{$1} = $2;
    }

    elsif ($line =~ m/#=GS\t(\w+)\tDE(\w+)\.\.(\w+)\t(\w+)/g) {
	$starts{$1} = $2;
	$ends{$1} = $3;
	$scores{$1} = $4;
    }

    elsif ($line =~ m/#=GR\t(\w+)\tSS([\.-><]+)/g) {
	$structures{$1} = $structures{$1}.$2;
    }

    elsif($line =~ m/(\w+)\t\t([AUGCaugc\.-]+)/g) {
	$sequences{$1} = $sequences{$1}.$2;
    }
}

foreach my $name (keys(%sequences)) {
    print "Name:   $name \n";
    print "Score:  %scores{$name} \n";
    print "Weight: %weights{$name} \n";
    print "Start:  %starts{$name} \n";
    print "End:    %ends{$name} \n";
    print "Sequence and Structure: \n";
    print "%sequences{$name}\n%structures{$name}\n";
    print "----------------------------------------------------------------\n";
}
