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

my %args_sort = load_args(\@ARGV);

my @data;

my $block_size = get_arg("b", 1000000, \%args_sort);

my $finished=0;
my $buffer;

while (my $line=<$file_ref>){
  (my $chr,my $id,my $start,my $end,my $feature,my $values)=($line=~/^(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t1\t1\t(\S+)/);
  my $prev_ind=0;
  my $c=0;
  if ($end-$start+1>$block_size){
    for (my $i=$start;$i<$end;$i+=$block_size){
      print "$chr\t$id","_$c\t$i\t",$i+$block_size<$end?$i+$block_size-1:$end,"\t$feature\t1\t1\t";
      $c++;
      my $ind=$prev_ind;
      for (1..$block_size) {
	$ind=index $values,";",$ind+1;
	if ($ind==-1) { last }
      }
      if ($ind<0){
	print substr $values,$prev_ind;
      }
      else{
	print substr $values,$prev_ind,$ind-$prev_ind;
      }
      print "\n";
      $prev_ind=$ind+1;
    }
  }
  else{
    print $line;
  }
}


__DATA__

expand_chv.pl

breaks down chv to smaller rows. assumes sixth and seventh columns are 1.

  -b:   block size. default = 1000000.


