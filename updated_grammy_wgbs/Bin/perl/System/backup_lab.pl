#!/usr/bin/perl

use strict;
use File::Basename;

my @excluded_dirs;
&fill_excluded_dirs;

my $exclude_time = 0;
my $all_time = 0;
my $copy_time = 0;
my $zip_time = 0;

my $exclude_prefix = "tmp";

my @file_search_strings;
my @dir_search_strings;
my $file_suffix = "";

if ($ARGV[0] eq "-data")
{
    $file_suffix = "_data";
    push(@file_search_strings, "*.pdf");
    push(@dir_search_strings, "Local/*");
}
else
{
    push(@file_search_strings, "*.c");
    push(@file_search_strings, "*.cpp");
    push(@file_search_strings, "*.cgi");
    push(@file_search_strings, "*.js");
    push(@file_search_strings, "*.h");
    push(@file_search_strings, "*.java");
    push(@file_search_strings, "*.m");
    push(@file_search_strings, "Makefile*");
    push(@file_search_strings, "*.mak");
    push(@file_search_strings, "*.pl");
    push(@file_search_strings, "*.doc");
    push(@file_search_strings, "*.xls");
    push(@file_search_strings, "*.SPF");
    push(@file_search_strings, "*.txt");
    push(@file_search_strings, "*.TXT");
    push(@file_search_strings, "*.tab");
    push(@file_search_strings, "*.xml");
    push(@file_search_strings, "*.fig");
    push(@file_search_strings, "*.sbd");
    push(@file_search_strings, "*.ppt");
    push(@file_search_strings, "*.csv");
    push(@file_search_strings, "*.ewt");
    push(@file_search_strings, "*.DOC");
    push(@file_search_strings, "*.gbk");
    push(@file_search_strings, "*.conf");
    push(@file_search_strings, "*.esc");
    push(@file_search_strings, "*.lst");
    push(@file_search_strings, "*.rtf");
    push(@file_search_strings, "*.mat");
    push(@file_search_strings, "*.checklist");
    push(@file_search_strings, "*.chr");
    push(@file_search_strings, "*.tpb");
    push(@file_search_strings, "*.xsl");
    push(@file_search_strings, "*.mlt");
    push(@file_search_strings, "*.asv");
    push(@file_search_strings, "*.private");
    push(@file_search_strings, "*.rec");
    push(@file_search_strings, "*.mdfx");
    push(@file_search_strings, "*.gel");
    push(@file_search_strings, "*.docx");
    push(@file_search_strings, "*.eds");
    push(@file_search_strings, "*.params");
    push(@file_search_strings, "*.psd");
    push(@file_search_strings, "*.ds");
    push(@file_search_strings, "*.Extra");
    push(@file_search_strings, "*.gxt");
    push(@file_search_strings, "*.MYI");
    push(@file_search_strings, "*.MYD");
    push(@file_search_strings, "*.frm");
    push(@file_search_strings, "*.cys");
    push(@file_search_strings, "*.mht");
    push(@file_search_strings, "*-");
    push(@file_search_strings, "*.zip");
    push(@file_search_strings, "*.gz");
    push(@file_search_strings, "*.xlsx");
    push(@file_search_strings, "*.pptx");
}

my $backup_base = "$ENV{GENIE_HOME}/Backup";
my $links = "$backup_base/lab_links.tab";
my $log = "$backup_base/lab_log.tab";
#open(LINKS, ">$links");
open(LOG, ">$log");

(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =	localtime(time);
$mon++;
$year %= 100;
system("mv $backup_base/Lab${file_suffix}.tar.gz $backup_base/Lab${file_suffix}"."_$mday-$mon-0$year"."_$hour:$min.tar.gz");
#system("rm $backup_base/develop$file_suffix.zip");
#system("rm $backup_base/www$file_suffix.zip");

my $start_time = time();
&traverse("$ENV{GENIE_HOME}/Lab", "$backup_base/Lab${file_suffix}.tar");
#&traverse("/home/lubling/test/tar", "$backup_base/test.tar");

system ("gzip $backup_base/Lab${file_suffix}.tar");

$all_time += time() - $start_time;

print LOG "Timing\n============\nZip\t$zip_time\nExclude\t$exclude_time\nCopy\t$copy_time\nAll\t$all_time\n";

#&traverse("$ENV{DEVELOP_HOME}", "$backup_base/develop$file_suffix.zip");
#&traverse("$ENV{WWW_HOME}", "$backup_base/www$file_suffix.zip");
#&traverse("$ENV{CGI_HOME}", "$backup_base/www$file_suffix.zip");

close (LOG);

sub traverse
{
  my ($current_directory, $zip_file) = @_;

  #print STDERR "In: $current_directory\n";

  &copy_dir_files($current_directory, $zip_file);

  my $dirs_str = `find '$current_directory/.' -type d -maxdepth 1`;
  my @dirs = split(/\n/, $dirs_str);

  foreach my $dir (@dirs)
  {
    my $stripped_dir = "";
    if ($dir =~ /[\.][\/](.*)/) { $stripped_dir = $1; }

    if (&exclude_dir($dir) == 0 and not($stripped_dir =~ /[\.]/) and length($stripped_dir) > 0)
    {
      &traverse("$current_directory/$stripped_dir", "$zip_file");
    }
  }
}

sub copy_dir_files
{
  my ($current_directory, $zip_file) = @_;

  my $start_time = time();

  foreach my $file_search (@file_search_strings)
  {
    #print STDERR "find $current_directory/. -name \"$file_search\" -maxdepth 1\n";
    my $files_str = `find '$current_directory/.' -type f -name "$file_search" -maxdepth 1`;

    &zip_dir_files($files_str, $zip_file);
  }


  foreach my $dir_search (@dir_search_strings)
  {
      my @row = split(/\//, $dir_search);
      
      #print STDERR "find $current_directory/$row[0]/. -name \"$row[1]\" -maxdepth 1\n";
      my $files_str = `find '$current_directory/$row[0]/.' -type f -name "$row[1]" -maxdepth 1`;

      &zip_dir_files($files_str, $zip_file);
  }

  $copy_time += time() - $start_time;

}

sub zip_dir_files
{
    my ($files_str, $zip_file) = @_;
    
    my $start_time = time();

    my @files = split(/\n/, $files_str);

    foreach my $file (@files)
    {
      if (-f $file and not (-l $file) and index (basename($file), $exclude_prefix) != 0)
      {
	print LOG "$file\n";
	system("tar uvf $zip_file '$file'");
      }
      elsif (-l $file)
      {
#	  print LINKS "$file\t" . readlink($file) . "\n";
      }
    }

    $zip_time += time() - $start_time;
}

sub exclude_dir
{
  my ($dir) = @_;

  my $start_time = time();

  $dir =~ s/[\.][\/]//g;

  foreach my $excluded_dir (@excluded_dirs)
  {
    #print STDERR "RRRRRRRRR $dir <-> $excluded_dir <-> " . index($dir, $excluded_dir) . "\n";
    if (index($dir, $excluded_dir) >= 0) 
    {  
       $exclude_time += time() - $start_time; 
       return 1; 
    }
  }
  
  $exclude_time += time() - $start_time;
  return 0;
}

sub fill_excluded_dirs
{
  push(@excluded_dirs, "RobotBackup");  
}
