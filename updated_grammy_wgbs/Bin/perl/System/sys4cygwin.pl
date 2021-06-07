#!/usr/bin/perl

use strict;

my $verbose = 1;
my $local_dir = "$ENV{HOME}/develop";
my $remote_dir = "Develop";

my $target_dir;
my $remote_archive;
my $local_archive;

my $remote_machine = "132.76.80.227";

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
  elsif ($arg eq '-remote')
  {
      $remote_machine = shift @ARGV;
  }
  elsif ($arg eq '-genie')
  {
    $local_archive = "$local_dir/genie/genie.zip";
    $remote_archive = "$remote_dir/genie/genie.zip";
    $target_dir = "$local_dir/genie";
  }
  elsif ($arg eq '-perl')
  {
    $local_archive = "$local_dir/perl/perl.zip";
    $remote_archive = "$remote_dir/perl/perl.zip";
    $target_dir = "$local_dir/perl";
  }
  elsif ($arg eq '-templates')
  {
    $local_archive = "$local_dir/Templates/templates.zip";
    $remote_archive = "$remote_dir/Templates/templates.zip";
    $target_dir = "$local_dir/Templates";
  }
  elsif ($arg eq '-genexpress')
  {
    $local_archive = "$local_dir/Genomica/genomica.zip";
    $remote_archive = "$remote_dir/Genomica/genomica.zip";
    $target_dir = "$local_dir/Genomica/src";
  }
  elsif ($arg eq '-genomica')
  {
    $local_archive = "$local_dir/../www/genomica.zip";
    $remote_archive = "$remote_dir/../www/genomica/genomica.zip";
    $target_dir = "$local_dir/../www/genomica";
  }
}

#---------------------------------------------------------------------------------
# Copy the local file
#---------------------------------------------------------------------------------
my $mv_cmd = "scp $ENV{USER}\@$remote_machine:$remote_archive $local_archive";
$verbose and print STDERR "Copying '$remote_archive' to '$local_archive'...\n";
print STDERR "$mv_cmd\n";
system("$mv_cmd");
$verbose and print STDERR " done.\n";

#---------------------------------------------------------------------------------
# Unzip the file
#---------------------------------------------------------------------------------
my $unzip_cmd = "cd $target_dir; unzip -o $local_archive";
$verbose and print STDERR "Installing $remote_machine sources under $target_dir.\n";
system($unzip_cmd);
$verbose and print STDERR "Done installing $remote_machine sources.\n";

__DATA__

syntax: sys4cygwin.pl [OPTIONS]

OPTIONS are:

   -q: quiet mode

   -remote <name>: name of remote machine (default: genie.rockefeller.edu)

   -perl:          Update Perl sources
   -genie:         Update Genie sources
   -genexpress:    Update GeneXPress sources

