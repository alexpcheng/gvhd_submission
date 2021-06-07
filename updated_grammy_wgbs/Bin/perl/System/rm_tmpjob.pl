#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my %args = load_args(\@ARGV);
my $print_files = get_arg("p", 0, \%args);
my $amin = get_arg("amin", "", \%args);

my @tmpjob_files_list;

if ($amin ne "")
{
   @tmpjob_files_list = `find -name 'tmpjob*' -amin $amin`;
}
else
{
    @tmpjob_files_list = `ls -1 |  grep tmpjob`;
}

my $tmpjob_files_num = scalar(@tmpjob_files_list);


for (my $cur_tmpjob_num = 0; $cur_tmpjob_num < $tmpjob_files_num; ++$cur_tmpjob_num)
{
  my $cur_tmpjob_file = $tmpjob_files_list[$cur_tmpjob_num];
  if ($print_files > 0)
  {
    print STDERR "Deleting File:$cur_tmpjob_file ";
  }
  `rm $cur_tmpjob_file`;
}




#-----------------------------------------------------------------------------------------
# --help 
#-----------------------------------------------------------------------------------------

__DATA__

 Syntax:         rm_tmpjob.pl 

 Description:    Delete all tmpjob files in current directory

 Flags:
-p              print deleted file names to STDERR

-amin  <str>     Like amin of find. use -amin '+180' to delete all tmpjob file older than 180 minutes



