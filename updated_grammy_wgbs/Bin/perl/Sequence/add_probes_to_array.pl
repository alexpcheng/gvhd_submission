#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help") {
   print STDOUT <DATA>;
   exit;
}

my %args = load_args(\@ARGV);

my $features_file = get_arg("features", "", \%args);
my $added_features = get_arg("added_features", "", \%args);
my $array_file = get_arg("array", "", \%args);
my $max_probes = get_arg("max_probes", -1, \%args);

if (length($features_file) == 0 or length($array_file) == 0 or length($added_features) == 0)
{
    die "Error: must specify features, array and added_features files.\n";
}

if ($max_probes < 0)
  {
    die "Error: must enter max number of probes.\n";
  }

open (FEATURES_FILE, "<$features_file") or die "Error: failed to open $features_file\n";
open (ADDED_FEATURES_FILE, ">>$added_features") or die "Error: failed to open $added_features\n";

open (ARRAY_FILE, "<$array_file") or die "Error: failed to open $array_file\n";

my %added_probes;
while (<ARRAY_FILE>)
  {
    chop;
    if ($added_probes{$_})
      {
	print STDERR "Warning: Probe list received is not unique. Replacing $added_probes{$_} with $_\n";
      }
    $added_probes{$_} = $_;
  }
close ARRAY_FILE;

my $n_probes = scalar keys %added_probes;
print STDERR "Current #probes: $n_probes can add ".($max_probes - $n_probes)."\n";

my $line;
while (($line = <FEATURES_FILE>) and ($n_probes < $max_probes))
  {
    chop $line;
    my @row = split (/\t/, $line);
    my $n_new_probes = 0;
    my @new_probes;
    for (my $i = 4; $i <= $#row; $i++)
      {
	if (!$added_probes{$row[$i]})
	  {
	    $n_new_probes++;
	    push (@new_probes, $row[$i]);
	    $added_probes{$row[$i]} = $row[$i];
	  }
      }
    if ($n_probes + $n_new_probes <= $max_probes)
      {
	print ADDED_FEATURES_FILE "$row[0]\t$row[1]\t$row[2]\t$row[3]\n";
	for (my $j = 0; $j < $n_new_probes; $j++)
	  {
	    print "$new_probes[$j]\n";
	  }
	$n_probes += $n_new_probes;
      }
  }

close FEATURES_FILE;
close ADDED_FEATURES_FILE;

__DATA__

add_probes_to_array.pl

 Input: 
    -features <file>:   Features file (chr file) with assigned probes per feature:
                     
                            chr   id   start   end   probe_id1   probe_id2 ...

    -array <file>:      Unique list of probes ids that were already added to the array.

                            probe_id1
                            probe_id2
                            ...
    
    -max_probes <num>:  Maximum number of probes that the array can hold.

  Output:
    
    Prints the new unique list of probes ids added to the array.

    -added_features <file>:   File name to print the features that their probes were added.
