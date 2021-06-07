#!/usr/bin/perl

use strict;
use File::Copy;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $skip = get_arg("skip", 0, \%args);

if ($skip > 0)
  {
    $skip = $skip +1;
  }

my $i = 1;

while (-d $i)
{
	opendir(DIR, "$i/Output") or print STDERR "Warning: Can't open directory $i/Output\n";
	my @files = readdir(DIR);
	for my $file (@files)
	{
		$file eq '.'  and next;
        $file eq '..' and next;
		
		print STDERR "\nCollecting $i/Output/$file... ";

		if ($i == 1) 
		  {
		    system ("rm -f ../Output/$file");
		    system ("cat $i/Output/$file >> ../Output/$file");
		  }
		else
		  {
		    if ($skip > 0)
		      {
			system ("cat $i/Output/$file | body.pl $skip -1 >> ../Output/$file");
		      }
		    else
		      {
			system ("cat $i/Output/$file >> ../Output/$file");
		       }
		  }
		
	}
	closedir(DIR);
	$i++;
}

print STDERR "\nDone.\n";

		
__DATA__

parallel_collect.pl

	When run in the /Parallel directory, this script collectes all files in the
	/Output directories into a single large file in the /Output directory that's
	at the same level of /Parallel.
	
	For example, if the output directories contain a file called "data.tab":
	
	/Parallel
		/1/Output/data.tab
		/2/Output/data.tab
		/3/Output/data.tab
		
		
	Then the result will be the concatanation of those files created in:
	
	/Output/data.tab



-skip NUM: Skip the first NUM lines and do not join it (except for the first file)


   
   
  
