#!/usr/bin/perl

use strict;

my $verbose = 1;
my $local_dir = "$ENV{DEVELOP_HOME}";

my $local_archive;
my $target_dir;

while(@ARGV)
{
  my $arg = shift @ARGV;
  if ($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
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
# Make the genie archive more current than anything we modified
#---------------------------------------------------------------------------------
my $unzip_cmd = "cd $target_dir; unzip -o $local_archive";
$verbose and print STDERR "Installing CygWin sources under $target_dir.\n";
system($unzip_cmd);
$verbose and print STDERR "Done installing CygWin sources.\n";

__DATA__

syntax: cygwin4sys.pl

OPTIONS are:

   -q: quiet mode

   -perl:        Update Perl sources
   -genie:       Update Genie sources
   -genexpress:  Update GeneXPress sources

