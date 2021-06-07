#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/libfile.pl";
require "$ENV{PERL_HOME}/Lib/libstd.pl";
require "$ENV{PERL_HOME}/Lib/libstring.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-m', 'scalar',     1, undef]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose        = not($args{'-q'});
my $global_key_col = $args{'-k'} - 1;
my $delim          = $args{'-d'};
my $min            = $args{'-m'};
my @files          = @{$args{'--file'}};
my @extra          = @{$args{'--extra'}};

#(scalar(@files) >= 2) or die("Must supply 2 or more files");

my @cols = @{&parseColsFromArgs(\@extra)};

print STDERR "(", join(",", @cols), ")\n";

# The number of files the key appears in:
my %count;

# Keep track of the keys_in_order keys are found in.
my @keys_in_order;

my $num_files = scalar(@files);

for(my $j = 0; $j < $num_files; $j++)
{
   $verbose and print STDERR "(", $j+1, "/$num_files). ",
                             "Collecting every key from file '$files[$j]'...";

   my $file    = &openFile($files[$j]);

   my $key_col = defined($cols[$j]) ? $cols[$j] : $global_key_col;

   my %file_keys;

   my @file_keys;

   while(<$file>)
   {
      my @tuple = split($delim);

      chomp($tuple[$#tuple]);

      my $key = splice(@tuple, $key_col, 1);

      if(not(exists($file_keys{$key})))
      {
         $file_keys{$key} = 1;

         push(@file_keys, $key);
      }
   }
   close($file);

   foreach my $key (@file_keys)
   {
      if(not(exists($count{$key})))
      {
         $count{$key} = 1;

         push(@keys_in_order, $key);
      }
      else
      {
         $count{$key} += 1;
      }
   }
   $verbose and print STDERR " done.\n";
}

my $num_keys_total = scalar(keys(%count));

my %row;

my @data;

my $num_keys_kept = 0;

foreach my $key (@keys_in_order)
{
   if($count{$key} >= $min)
   {
      $data[$num_keys_kept][0] = $key;

      $row{$key} = $num_keys_kept;

      $num_keys_kept++;
   }
}

$verbose and print STDERR "$num_keys_kept keys present in $min or more files kept (out of $num_keys_total total found).\n";

my @blanks;

for(my $j = 0; $j < $num_files; $j++)
{
   $verbose and print STDERR "(", $j+1, "/$num_files). ",
                             "Collecting data from file '$files[$j]'...";


   my $file      = &openFile($files[$j]);

   $blanks[$j]   = undef;

   my $key_col   = defined($cols[$j]) ? $cols[$j] : $global_key_col;

   while(my $line = <$file>)
   {
      my @tuple = split($delim, $line);

      $blanks[$j] = defined($blanks[$j]) ? $blanks[$j] : &duplicate(scalar(@tuple) - 1);

      chomp($tuple[$#tuple]);

      my $key = splice(@tuple, $key_col, 1);

      if(exists($row{$key}))
      {
         my $i   = $row{$key};

         push(@{$data[$i]}, &pad(\@tuple, $blanks[$j]));
      }
   }

   $blanks[$j] = defined($blanks[$j]) ? $blanks[$j] : [];

   for(my $i = 0; $i < $num_keys_kept; $i++)
   {
      if(scalar(@{$data[$i]}) < $j + 2)
      {
         push(@{$data[$i]}, $blanks[$j]);
      }
   }

   close($file);

   $verbose and print STDERR " done.\n";
}

$verbose and print STDERR "Printing out the combined data...";

my $entry;

for(my $i = 0; $i < $num_keys_kept; $i++)
{
   $entry = defined($data[$i][0]) ? $data[$i][0] : '';

   print STDOUT $entry;

   for(my $j = 1; $j <= $num_files; $j++)
   {
      $entry = defined($data[$i][$j]) ? $data[$i][$j] : $blanks[$j-1];

      print STDOUT $delim, join($delim, @{$entry});
   }

   print STDOUT "\n";
}

$verbose and print STDERR " done.\n";

exit(0);

sub parseColsFromArgs
{
   my ($args) = @_;

   my @cols;

   my $fileno = undef;

   while(@{$args})
   {
      my $arg = shift @{$args};

      if($arg =~ /^-(\d+)/)
      {
         $fileno = int($1) - 1;

         $arg = shift @{$args};

         if($arg =~ /^\s*(\d+)\s*$/)
         {
            $cols[$fileno] = int($1) - 1;
         }
      }
   }
   return \@cols;
}

__DATA__
syntax: join_multi.pl [OPTIONS] FILE1 FILE2 [FILE3 FILE4 ...]


If only one file is given, then it is simply echoed to output.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-m MIN: Set the minimum number of files that an entry has to 
        exist in to MIN.  The default is 1 which means the entry
        has to appear in at least one file.

-# COL: Set the key column of file # to COL.  For example -1 2
        tells the script to read the first file's key from the
        second column.
