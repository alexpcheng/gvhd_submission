#!/usr/bin/perl

use strict;

my $verbose = 1;
my $local_dir = "$ENV{DEVELOP_HOME}";
my $remote_dir = "Develop";
my $full = 0;

my $local_archive;
my $remote_archive;
my $target_dir;

my $remote_machine = "132.76.80.227";

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
    $local_archive = "$local_dir/Genomica/src/genomica.zip";
    $remote_archive = "$remote_dir/Genomica/genomica.zip";
    $target_dir = "$local_dir/Genomica/src/GeneXPressPackage";
  }
  elsif ($arg eq '-genomica')
  {
    $local_archive = "$local_dir/../www/genomica/genomica.zip";
    $remote_archive = "$remote_dir/../www/genomica/genomica.zip";
    $target_dir = "$local_dir/../www/genomica";
  }
}

#---------------------------------------------------------------------------------
# If doing full backup, remove the local archive.
#---------------------------------------------------------------------------------
if ($full and -f $local_archive)
{
  `rm $local_archive`;
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
$verbose and print STDERR "Zipping CygWin files.\n";
my $cmd = "cd $target_dir; " . "zipcode.pl $local_archive *";
system("$cmd");
$verbose and print STDERR "Done zipping CygWin files.\n";

#---------------------------------------------------------------------------------
# Get the new modification time of the archive:
#---------------------------------------------------------------------------------
@stats = stat($local_archive);
my $new_time = $stats[9];

#---------------------------------------------------------------------------------
# Copy them to remote machine only if the archive has been modified
#---------------------------------------------------------------------------------
if ($new_time > $old_time)
{
  $verbose and print STDERR "Copying to $remote_machine '$remote_archive'...";
  $cmd = "scp $local_archive $ENV{USER}\@$remote_machine:$remote_archive ";
  system("$cmd");
  $verbose and print STDERR " done.\n";
}
else
{
  $verbose and print STDERR "Nothing to copy to $remote_machine.\n";
}

__DATA__

syntax: cygwin2sys.pl [OPTIONS]

OPTIONS are:

   -full:          zip up everything in the CygWin directory (do not check modification times)

   -remote <name>: name of remote machine (default: genie.rockefeller.edu)

   -perl:          zip up Perl sources
   -genie:         zip up genie sources
   -genexpress:    zip up GeneXPress sources
   -templates:     zip up Templates sources

