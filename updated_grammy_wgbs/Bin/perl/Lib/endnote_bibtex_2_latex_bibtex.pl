#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref1;
my $file_ref2;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) 
{
  die("no file name given (- not allowed) Could not open file '$file'.\n");
}
else
{
  `dos2unix $file`;
  open(FILE1, $file) or die("Could not open file '$file' (1) .\n");
  $file_ref1 = \*FILE1;
  open(FILE2, $file) or die("Could not open file '$file' (2) .\n");
  $file_ref2 = \*FILE2;
}

my %args = load_args(\@ARGV); 

my $start_entry_line;
my $line1;
my $line2;
my $author;
my $journal;
my $year;

my $found_cur_item = 0;

while(<$file_ref1>)
{
    chomp;
	$line1 = $_;
	
	if ($line1 =~ m/^@/)
	{
		$start_entry_line = $line1;
		
		#print STDERR "DEBUG CUR ITEM 1: $line1\n"; 
		
		$found_cur_item = 0;
		while(<$file_ref2>)
		{
			chomp;
			$line2 = $_;
			
			if ($line2 =~ m/^@/)
			{
				if ($line2 ne $line1)
				{
					die("$line2 ne $line1  - BUG");
				}
				
				#print STDERR "DEBUG CUR ITEM 2: $line2\n"; 
				
				$found_cur_item = 1;
				
				while(<$file_ref2>)
				{
					chomp;
					$line2 = $_;
					
					#print STDERR "DEBUG line 2 |$line2|\n";
				
					if ($line2 =~ m/^\s+Author\s=\s{(\w+)[,}]*/)
					{
						$author = $1;
						#print STDERR "DEBUG author:$author\n"; 
					}
					
					if ($line2 =~ m/^\s+Journal\s=\s{([\w\s]+)}*/)
					{
						$journal = $1;
						$journal =~ s/\s//g;
						#print STDERR "DEBUG journal:$journal\n"; 
					}
					
					if ($line2 =~ m/^\s+Year\s=\s{\d\d(\d\d)*/)
					{
						$year = $1;
						#print STDERR "DEBUG year:$year\n"; 
					}
					
					if ($line2 eq "")
					{
						#print STDERR "DEBUG break since empty line\n"; 
						last;
					}
				}
				
				last;
			}
		}
		
		if ($found_cur_item == 0)
		{
			die("BUG - didn't find cur item");
		}
		print "$start_entry_line $author$year:$journal,\n"
	}
	else
	{
		print "$line1\n";
	}
	
}

__DATA__

endnot_bibtex_2_latex_bibtex.pl.pl <latex bib file created by endnote>

adds a short reference for the article in a latex bib style - author[year in two digits]:journal

