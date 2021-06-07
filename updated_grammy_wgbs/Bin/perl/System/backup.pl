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
    push(@file_search_strings, "*.css");
    push(@file_search_strings, "*.h");
    push(@file_search_strings, "*.html");
    push(@file_search_strings, "*.center");
    push(@file_search_strings, "*.left");
    push(@file_search_strings, "*.right");
    push(@file_search_strings, "*.outside");
    push(@file_search_strings, "*.java");
    push(@file_search_strings, "*.jpr");
    push(@file_search_strings, "*.jws");
    push(@file_search_strings, "*.m");
    push(@file_search_strings, "Makefile*");
    push(@file_search_strings, "*.mak");
   # push(@file_search_strings, "*.map");
    push(@file_search_strings, "*.pl");
    push(@file_search_strings, "references_list.tab");
    push(@file_search_strings, "*.doc");
   # push(@file_search_strings, "*.xls");
}

my $backup_base = "$ENV{GENIE_HOME}/Backup";
my $links = "$backup_base/links.tab";
my $log = "$backup_base/log.tab";
#open(LINKS, ">$links");
open(LOG, ">$log");

(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) =	localtime(time);
$mon++;
$year %= 100;
system("mv $backup_base/Genie${file_suffix}.tar.gz $backup_base/Genie${file_suffix}"."_$mday-$mon-0$year"."_$hour:$min.tar.gz");
#system("rm $backup_base/develop$file_suffix.zip");
#system("rm $backup_base/www$file_suffix.zip");

my $start_time = time();
&traverse("$ENV{GENIE_HOME}", "$backup_base/Genie$file_suffix.tar");
#&traverse("/home/lubling/test/tar", "$backup_base/test.tar");

system ("gzip $backup_base/Genie$file_suffix.tar");

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
  #push(@excluded_dirs, "Map/Eval");  
   push (@excluded_dirs, "Runs/FeatureMatrix/Eilon06/first_synthetic_runs");
   push (@excluded_dirs, "Runs/FeatureMatrix/Eilon06/synthetic_runs");
   push (@excluded_dirs, "Runs/FeatureMatrix/Eilon06/MacIsaac06_feature");
   push (@excluded_dirs, "Runs/FeatureMatrix/Eilon06/MacIsaac06_feature_uniformBackground");
   push (@excluded_dirs, "Runs/FeatureMatrix/Eilon06/MacIsaac06_feature_yeastBackground");
   push (@excluded_dirs, "Runs/Folding/Rabani06/Model/GeneSets/tmp_GO");
   push (@excluded_dirs, "Runs/Folding/Rabani06/Model/GeneSets/tmp_NewExamples");
   push (@excluded_dirs, "Runs/Folding/Rabani06/Model/GeneSets/tmp_MoreNewExamples");
   push (@excluded_dirs, "Runs/Folding/Rabani06/Model/GeneSets/tmp_KnownExamples");
   push (@excluded_dirs, "Runs/Folding/Rabani06/Model/GeneSets/old");
   push (@excluded_dirs, "Runs/Lineage/Itzkovitz07/backups");
   push (@excluded_dirs, "Genie/Bin");
   push (@excluded_dirs, "Genie/Develop/perl/Help");
#   push (@excluded_dirs, "Genie/Lab");
}
