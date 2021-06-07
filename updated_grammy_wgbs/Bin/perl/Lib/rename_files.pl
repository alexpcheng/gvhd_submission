#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) 
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);

my $rename_files = get_arg("f", 0, \%args);
my $rename_directories = get_arg("d", 0, \%args);
my $remove_str = get_arg("r", "", \%args);
my $start_directory = get_arg("dir", ".", \%args);

my $files_str = `find $start_directory -name "*"`;
my @files = split(/\n/, $files_str);
foreach my $file (@files)
{
  if (($rename_files == 1 and -f $file) or ($rename_directories == 1 and -d $file))
  {
    if (length($remove_str) > 0 and $file =~ /$remove_str/)
    {
      my $original_file = $file;
      $file =~ s/$remove_str//g;

      print "Renaming $original_file --> $file\n";
      my $exec_str = "mv \"$original_file\" \"$file\"";
      #print "$exec_str\n";
      system($exec_str);
    }
  }
}

__DATA__

rename_files.pl

   Renames files and/or directories according to specified rules
   Example: rename_files.pl -d -r "[\)]"
            renames directories to remove the sign ) from their name

   -f:         Rename files 
   -d:         Rename directories 

   -r <str>:   Remove <str> from the name of the file/directory

   -dir <str>: Directory to start from (default: .)

