#!/usr/bin/perl
use strict;

my $id;
my $chr;
my @list;
my $p = 0;

my $list_item;
my @starts;
my @ends;
my $top = 1;

while (<STDIN>) {
  chomp $_;

  if ($_ =~ m/<Gene-track_geneid>(\d+)</g) {
    $id = $1;
  }
  elsif ($_ =~ m/Maps_display-str>(\d+)[pq]/g){
    $chr = "chr".$1;
  }

  elsif ($_ =~ m/<Entrezgene_locus>/g) {
    $p = 1;
  }
  elsif ($_ =~ m/<\/Entrezgene_locus>/g) {
    $p = 0;
  }

  elsif ($_ =~ m/<Gene-commentary_products>/g) {
    $top = 0;
  }
  elsif ($_ =~ m/<\/Gene-commentary_products>/g) {
    $top = 1;

    if ($p) {
      my $count = scalar(@starts);

      if ($count > 0) {
	$list_item = $list_item."\t$count\t";
	for (my $i = 0; $i < $count; $i++) {
	  $list_item = $list_item."$starts[$i],";
	}
	chop $list_item;
	$list_item = $list_item."\t";
	for (my $i = 0; $i < $count; $i++) {
	  $list_item = $list_item."$ends[$i],";
	}
	chop $list_item;
	$list_item = $list_item."\t";
	for (my $i = 0; $i < $count; $i++) {
	  $list_item = $list_item."1,";
	}
	chop $list_item;
	$list_item = $list_item."\t";
	push(@list, $list_item);
      }
      else {
	push(@list, "($list_item)");
      }
    }
    $list_item = "";
    @starts = ();
    @ends = ();
  }

  elsif ($_ =~ m/<Seq-interval_from>(\d+)</g) {
    if ($top) {
      $list_item = $list_item."$1\t";
    }
    else {
      push(@starts, $1);
    }
  }
  elsif ($_ =~ m/<Seq-interval_to>(\d+)</g) {
    if ($top) {
      $list_item = $list_item."$1\t";
    }
    else {
      push(@ends, $1);
    }
  }
  elsif(($_ =~ m/Na-strand value="(.+)"/g) and $top) {
    if ($1 eq "plus") {
      $list_item = $list_item."+";
    }
    elsif ($1 eq "minus") {
      $list_item = $list_item."-";
    }
    else {
      $list_item = $list_item."$1";
    }
  }

  elsif ($_ =~ m/<\/Entrezgene>/g) {
    my $size = scalar(@list);
    if ($size == 0) {
      print "$chr\t$id\n";
    }
    else {
      print "$chr\t$id\t$list[0]\n";
    }
    @list = ();
    $chr = "";
    $id = "";
    $list_item = "";
    $top = 1;
    @starts = ();
    @ends = ();
    $p = 1;
  }
}
