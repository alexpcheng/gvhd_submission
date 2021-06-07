#!/usr/bin/perl
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $cmean = get_arg("m", 0, \%args);
my $cstd = get_arg("std", 0, \%args);
my $cmax = get_arg("max", 0, \%args);
my $cmin = get_arg("min", 0, \%args);
my $ccount = get_arg("count", 0, \%args);
my $discrete = get_arg ("discrete", "", \%args);

my $disc_min;
my $disc_max;

if ($discrete ne "") {
  ($disc_min, $disc_max) = split (",", $discrete);
}

while (<STDIN>) {
  chomp $_;
  my ($id, $values) = split("\t", $_);
  my @list = split(";", $values);
  my $size = scalar(@list);

  print "$id";

  if ($cmean) {
    my $mean = 0;
    foreach my $i (@list) {
      $mean += $i;
    }
    $mean = $mean/$size;
    printf("\t%.15f",$mean);

    if ($cstd) {
      my $std = 0;
      foreach my $i (@list) {
	$std = $std + ($mean-$i)*($mean-$i);
      }
      $std = sqrt($std/$size);
      printf("\t%.15f",$std);
    }
  }

  if ($cmax) {
    my $max = $list[0];
    foreach my $i (@list) {
      if ($max < $i) {
	$max = $i;
      }
    }
    printf("\t%.15f",$max);
  }

  if ($cmin) {
    my $min = $list[0];
    foreach my $i (@list) {
      if ($min > $i) {
	$min = $i;
      }
    }
    printf("\t%.15f",$min);
  }

  if ($ccount) {
    my @keys = split(",", $ccount);

    my %counts;
    foreach my $i (@list) {
      $counts{$i}++;
    }
    my $t = 0;
    foreach my $k (@keys) {
      $t += $counts{$k};
    }

    if ($t > 0) {
      foreach my $k (@keys) {
	my $v = $counts{$k}/$t;
	printf("\t%.15f", $v);
      }
    }
    else {
      foreach my $k (@keys) {
	my $v = $counts{$k};
	printf("\t%.15f", $v);
      }
    }
  }

  if ($discrete ne "")
  {
    my @disc_list;

    foreach my $i (@list)
	{
    	if ($i < $disc_min)
    	{
			push (@disc_list, "A");
		}
		elsif ($i > $disc_max)
		{
			push (@disc_list, "C");
		}
		else
		{
			push (@disc_list, "B");
		}
	}
	
	print "\t" . join (";", @disc_list);
  }

  print "\n";
}

