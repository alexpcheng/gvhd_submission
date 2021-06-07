#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my $rm_file_name_str = $ARGV[0];



my %args = load_args(\@ARGV);
my $print_files = get_arg("p", 0, \%args);
my $is_recursive = get_arg("R", 0, \%args);


## initial call ... $ARGV[0] is the first command line argument

&MyRm(".",$rm_file_name_str, $is_recursive,$print_files);


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub MyRm
{
  my ($path,$file_name_str, $is_recursive,$print_files) = @_;

  ## append a trailing / if it's not there
  $path .= '/' if($path !~ /\/$/);

  ## print the directory being searched
  print STDERR "Directory:$path\n";

  ## loop through the files contained in the directory
  
  my @cur_files = glob($path.'*');
  #print "DEBUG @cur_files\n";

  my $files_num = scalar(@cur_files);


	for (my $cur_file_num = 0; $cur_file_num < $files_num; ++$cur_file_num)
	{
	  
		my $eachFile = $cur_files[$cur_file_num];
		
		# print "DEBUG check file:$eachFile\n";
		
		## if the file is a directory
	    if( -d $eachFile && $is_recursive == 1)
		{
		  ## pass the directory to the routine ( recursion )
		  MyRm($eachFile,$file_name_str, $is_recursive,$print_files);
		}
	      else
		{
		#print "DEBUG match:$file_name_str\n";
		  if ($eachFile =~ m/$file_name_str/)
		    {
				#print "DEBUG find match:$eachFile, $file_name_str\n";
		      
			  if ($print_files > 0)
				{
				  print STDERR "Deleting File:$eachFile,\t";
				}
		      `rm $eachFile`;
		    }
		}
	}

	print STDERR "\n";
}





#-----------------------------------------------------------------------------------------
# --help 
#-----------------------------------------------------------------------------------------

__DATA__

 Syntax:         rm_many_files.pl <file_name_str = perl regular expression>
 
 Description:    Delete all tmpjob files in current directory

 Flags:
-p              print deleted file names to STDERR
-R              do recursively for each dir

for example for deleting all .m file use:
rm_many_files.pl '.*\.m$' -p -R



