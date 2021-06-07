#!/usr/bin/perl
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $split = get_arg("s", 0, \%args);
my $overlap = get_arg("o", 0, \%args);

while (<STDIN>) {
  chomp $_;

  if ($split > 0) {
    my ($id, $values) = split("\t", $_);
    my @list = split(";", $values);
    my $size = scalar(@list);
    my $pos = 0;
    while ($pos < $size) {
      my $str = "$id:$pos\t";
      for (my $i = $pos; ($i < $pos+$split) and ($i < $size); $i++) {
	$str = $str."$list[$i];";
      }
      chop $str;
      print "$str\n";
      $pos = $pos + $split - $overlap;
    }
  }
  else {
    print "$_\n";
  }
}

