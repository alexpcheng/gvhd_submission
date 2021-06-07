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

my $append = get_arg("a", 0, \%args);

my @r;
my $fn="";
my $nrecords = 0;

while(<STDIN>)
{
	chop;
	if(/\S/)
	{	
		@r = split("\t");
		
		if ($r[0] =~ /^browser/)
		{
			next;
		}
		
		if ($r[0] =~ /track name=(\w*) /)
		{
			if ($fn ne "")
			{
				close TRACKFILE;
				print STDERR "$nrecords records.\n";
			}
			
			$fn = $1;
			print STDERR "Processing track $fn... ";
		
			if ($append)
			{
				open (TRACKFILE, ">>$fn.gff");
			}
			else
			{
				open (TRACKFILE, ">$fn.gff");
			}
			
			$nrecords = 0;
			next;
		}
		
		print TRACKFILE join ("\t", @r);
		print TRACKFILE "\n";
		
		$nrecords = $nrecords + 1;
	}		
}

if ($nrecords)
{
	close TRACKFILE;
	print STDERR "$nrecords records.\n";
}

exit(0);

__DATA__

syntax: gff2tracks.pl <file>

Given a gff file, extracts the different tracks into separate filenames, each having
the name of the track.

	-a	append to end of file (default: rewrite file).
	
