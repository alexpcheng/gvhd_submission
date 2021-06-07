#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $in_delim1 = get_arg("id1", "\t", \%args);
my $in_delim2 = get_arg("id2", "\n", \%args);
my $out_delim1 = get_arg("od1", "\t", \%args);
my $out_delim2 = get_arg("od2", "\n", \%args);
my $newline = get_arg("n", "", \%args);

my $c=0;
my @sets;
my $input;

while(my $line=<STDIN>){
  $input.=$line;
}
chomp $input;


my @input_sets=split /$in_delim2/,$input;
my $product_size=1;
for (my $i=0;$i<scalar(@input_sets);$i++){
  my @tmp=split /$in_delim1/,$input_sets[$i];
  $sets[$i]=\@tmp;
  $product_size*=scalar(@tmp);
}
my @out;
my $count=0;
cartesian_product(0);
if ($newline ne ""){print "\n";}

sub cartesian_product{
  my $i=shift;
  if ($i<scalar(@sets)){
    for (my $j=0;$j<scalar(@{$sets[$i]});$j++){
      $out[$i]=$sets[$i][$j];
      cartesian_product($i+1);
    }
  }
  else{
    print join($out_delim1,@out);
    $count++;
    if ($count<$product_size){
      print "$out_delim2";
    }
  }
}


__DATA__


cartesian_product.pl


Recieves a list of sets and returns their cartesian product.

  parameters:

  -id1 <str>   delimiter between objects in each set in input (default \t)
  -id2 <str>   delimiter between sets in input (default \n)
  -od1 <str>   delimiter between objects in each set in output (default \t)
  -od2 <str>   delimiter between sets in input (default \n)
  -n           print \n at the end
