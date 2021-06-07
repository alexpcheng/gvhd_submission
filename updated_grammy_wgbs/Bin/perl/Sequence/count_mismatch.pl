#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

# =============================================================================
# Main part
# =============================================================================

# reading arguments
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}


my $file_ref = -1;
my $file_name = shift(@ARGV);
if (length($file_name) < 1 or $file_name =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  open(FILE, $file_name) or die("Could not open file '$file_name'.\n");
  $file_ref = \*FILE;
}

my $file_ref2 = -1;
if (scalar(@ARGV) > 0 and ( not ($ARGV[0] =~ m/^-(.+)/g))) {
  my $second_file_name = shift(@ARGV);
  open(FILE2, $second_file_name) or die("Could not open file '$file_name'.\n");
  $file_ref2 = \*FILE2;
}


my %args = load_args(\@ARGV);
my $no_cmp_same_name = get_arg("n", 0, \%args);
my $cmp_only_same_name = get_arg("corr", 0, \%args);
my $file1_prefix = get_arg("file1_prefix", "", \%args);
my $file2_prefix = get_arg("file2_prefix", "", \%args);

die "ERROR - cannot set both '-n' and '-corr' options.\n" if ( $no_cmp_same_name and $cmp_only_same_name );


if ($file_ref2 > 0) {

  # read first file
  my %sequences;
  while (<$file_ref>) {
    my $line = $_;
    chomp($line);
    my ($name, $seq) = split("\t", $line);
    $sequences{$name} = $seq;
  }

  close($file_ref);

  # reading second file
  my %sequences2;
  while (<$file_ref2>) {
    my $line = $_;
    chomp($line);
    my ($name, $seq) = split("\t", $line);
    $sequences2{$name} = $seq;
  }
  close($file_ref2);

  foreach my $k1 (keys(%sequences)) {
    foreach my $k2 (keys(%sequences2)) {
      if ( ($no_cmp_same_name and $k1 ne $k2) or ($cmp_only_same_name and $k1 eq $k2) or ($no_cmp_same_name == 0 and $cmp_only_same_name == 0) ) {
	my $d = distance($sequences{$k1}, $sequences2{$k2});
	print "$file1_prefix$k1\t$file2_prefix$k2\t$d\n";
      }
    }
  }
}
else {

  # read first file
  my @sequences;
  my @names;
  my $p = 0;
  while (<$file_ref>) {
    my $line = $_;
    chomp($line);
    my ($name, $seq) = split("\t", $line);
    $sequences[$p] = $seq;
    $names[$p] = $name;
    $p++;
  }

  close($file_ref);

  for (my $i = 0; $i < scalar(@sequences); $i++) {
    for (my $j = $i+1; $j < scalar(@sequences); $j++) {
      my $d = distance($sequences[$i], $sequences[$j]);
      print "$names[$i]\t$names[$j]\t$d\n";
    }
  }
}




# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# distance(motif1, motif2)
# ------------------------------------------------------------------------
sub distance($$) {
  my ($str1, $str2) = @_;

  my $length = length($str1);
  if (length($str2) != $length) {
    return -1;
  }

  my @str1_arr = split("", $str1);
  my @str2_arr = split("", $str2);
  my $count = 0;
  for (my $i = 0; $i < $length; $i++) {
    if ($str1_arr[$i] ne $str2_arr[$i]) {
      $count++;
    }
  }

  return $count;
}


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

count_mismatch.pl <file_name 1> <file_name 2> [options]

  Reads sequences from the given stab files, and count the number of mismatch positions
  between each sequence in the first file and each sequence in the second file.

  If only one file is given, compare it to itself. Each comparison is done only once.

  Input format: <name> <sequence>
  Note: Assume the sequences are of the same length.

  Options: (relevant when two files are given)
   -n:                  Does not compare sequences with the same name (assumed to be identical).
   -corr:               Compares only sequences with the same name ('corr' for corresponding).
   -file1_prefix <str>: Prefix to add to names of sequences from file 1.
   -file2_prefix <str>: Prefix to add to names of sequences from file 2.

