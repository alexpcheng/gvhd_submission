#!/usr/bin/perl

use strict;

my $verbose = 1;
my $local_dir = "$ENV{DEVELOP_HOME}";
my $full = 1;

my $local_archive;
my $remote_archive;
my $target_dir;

while(@ARGV)
{
  my $arg = shift @ARGV;
  if ($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif ($arg eq '-full')
  {
    $full = 1;
  }
  elsif ($arg eq '-genie')
  {
    $local_archive = "$local_dir/genie/genie.zip";
    $target_dir = "$local_dir/genie";
  }
  elsif ($arg eq '-perl')
  {
    $local_archive = "$local_dir/perl/perl.zip";
    $target_dir = "$local_dir/perl";
  }
  elsif ($arg eq '-templates')
  {
    $local_archive = "$local_dir/Templates/templates.zip";
    $target_dir = "$local_dir/Templates";
  }
  elsif ($arg eq '-genexpress')
  {
    $local_archive = "$local_dir/Genomica/genomica.zip";
    $target_dir = "$local_dir/Genomica";
  }
  elsif ($arg eq '-genomica')
  {
    $local_archive = "$ENV{GENIE_HOME}/WWW/genomica/genomica.zip";
    $target_dir = "$local_dir/../www/genomica";
  }
}

#---------------------------------------------------------------------------------
# If doing full backup, remove the local archive.
#---------------------------------------------------------------------------------
if ($full and -f $local_archive)
{
  system("rm $local_archive");
}

#---------------------------------------------------------------------------------
# Get the original modification time of the archive:
#---------------------------------------------------------------------------------
my @stats;
my $old_time = 0;
if (-f $local_archive)
{
  @stats = stat($local_archive);
  $old_time = $stats[9];
}
else
{
  $verbose and print STDERR "Local archive does not exist! Performing full backup.\n";
}

#---------------------------------------------------------------------------------
# Zip up the files.
#---------------------------------------------------------------------------------
$verbose and print STDERR "Zipping files.\n";
my $cmd = "cd $target_dir; " . "zipcode.pl $local_archive *";
system("$cmd");
$verbose and print STDERR "Done zipping files.\n";

__DATA__

syntax: sys2cygwin.pl [OPTIONS]

OPTIONS are:

   -full:       zip up everything in the CygWin directory (do not check modification times)

   -perl:       zip up Perl sources
   -genie:      zip up genie sources
   -genexpress: zip up GeneXPress sources

