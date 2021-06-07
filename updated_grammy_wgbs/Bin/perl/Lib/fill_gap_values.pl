#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $max_gap = get_arg("maxgap", 5, \%args);
my $type = get_arg("type", "linear", \%args);

my $prev_chr;
my $prev_value;
my $prev_right;
my $prev_id;

while(my $row=<STDIN>){
  chomp $row;
  (my $chr,my $id,my $start, my $end, my $valuetype, my $value)=split /\t/,$row;
  my $right= $start<$end?$end:$start;
  my $left= $start<$end?$start:$end;
  if ($prev_chr ne ""){
    my $gap=$left-$prev_right-1;
    if ($gap<$max_gap and $chr eq $prev_chr){
      for (my $i=1;$i<=$gap;$i++){
	my $pos_value="";
	if ($type eq "linear") { $pos_value=$prev_value+($value-$prev_value)*$i/($gap+1) }
	print "$chr\t$prev_id;$id;$i\t",$prev_right+$i,"\t",$prev_right+$i,"\t$valuetype\t$pos_value\n";
      }
    }
  }
  print "$row\n";

  $prev_id=$id;
  $prev_chr=$chr;
  $prev_right=$right;
  $prev_value=$value;
}

__DATA__

fill_gap_values.pl

fills gaps between locations (chr format) by adding 1-bp locations with values that are
linear extensions of the values at both edges of the gap. assumes sorting by 1st column
and then by min(3rd,4th)


  parameters:

  -type <str>:   <str> can be linear/empty. default = linear
  -maxgap <num>: fill only gaps smaller than <num>. default = 5


