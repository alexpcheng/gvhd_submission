#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my $arg_command = get_full_arg_command(\@ARGV);
open OUTFILE, ">>merge_commands.tab";
print OUTFILE "$0 " . get_full_arg_command(\@ARGV) . "\n";
close(OUTFILE);

my %args = load_args(\@ARGV);

my $outlier_paths = get_arg("p", "", \%args);
my $outlier_file_name = get_arg("outlier_filename", "", \%args);
my $output_path = get_arg("output_path", "", \%args);
my $output_filename = get_arg("output_filename", "", \%args);

my $full_output_path = $output_path."/".$output_filename;
#Exec("rm -f $full_output_path");
Exec("touch $full_output_path");
my @paths = split(/\,/, $outlier_paths);
my $identifier = 0;

#my $cur_dir = `pwd`;
#$cur_dir =~ s/^\s+//;

for (my $i = 0; $i < @paths; $i++)
{
  
    my $cur_outlier_file = $paths[$i]."/".$outlier_file_name;
       $cur_outlier_file =~ s/^\s+//;
       $cur_outlier_file =~ s/\s+$//;

    if (-e "$cur_outlier_file")
      {
	$identifier = $identifier+1;
	#die "concat_platereader_outliers.pl ERROR file does not exist:$cur_outlier_file" unless (-e $cur_outlier_file);
	
	print STDERR "concating $cur_outlier_file with id:$identifier. \n";
	Exec("modify_column.pl $cur_outlier_file -astr \"\;$identifier\">>$full_output_path");
   }
    else
      {
	print STDERR "Warnning:$cur_outlier_file does NOT EXIST.\n";
      }
}

#--------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------
    
sub Exec
{
  my ($exec_str) = @_;
  
  #print("Running: [$exec_str]\n");
  system("$exec_str");
}










__DATA__

concat_platereader_outliers.pl <file>

   concats several plate layouts files

   -p <paths>: A comma-seprated list of directories containing the outlier list files. 
   -outlier_filename <filename>: the name of outlier list file (should be identical in all of the above specified directories)
   -output_path <path>: the directory under which the concatenated outlier files will be created
    -output_filename <filename>: the file name for the concatenated outlier file. A suffix of ";$i" will be added to the outlier file in each given path $i.


