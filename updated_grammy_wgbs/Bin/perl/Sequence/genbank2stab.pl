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

my $locus_id;
my $in_seq = 0;
my $line;
my $seq = "";

while(<$file_ref>)
{
    chop;
    $line = $_;
    $line =~ s/ +/\t/g;
    my @row = split(/\t/, $line);

    if ($line =~ /^LOCUS/)
    {
       $locus_id = $row[1];
    }
    elsif ($line =~ /^ORIGIN/)
    {
       $in_seq = 1;
    }
    elsif ($in_seq)
    {
       if ($line =~ /^\/\//)
       {
	  print "$locus_id\t$seq\n";
       }
       else
       {
	  $line = uc $line;
	  $line =~ s/[\s\d]//g;
	  $seq .= $line;
       }
    }
}

__DATA__

genbank2stab.pl <file>

   Takes in a genbank format file and extracts its sequence to a stab of this format: LOCUS_ID ORIGIN

