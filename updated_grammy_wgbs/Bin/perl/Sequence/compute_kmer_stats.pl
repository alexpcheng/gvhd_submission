#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my %args = load_args(\@ARGV);
my $sequence = get_arg("f", "", \%args);
my $reverse_complement = get_arg("rc", "", \%args);
my $zero_based = get_arg("0", 0, \%args);
my $k = get_arg("k", 5, \%args);
my $print_count = get_arg("n", "", \%args);
my $dump = get_arg("dump", 0, \%args);
my $dump_also_location = get_arg("dump_also_location", 0, \%args);

my $one_based=1;
if($zero_based){
  $one_based=0;
}

my @seq=("","");
my @current_kmer_values;
my $current_kmer;
my %sum;
my %count;
my $prev_position;
my $cur_start_for_print;
my $cur_end_for_print;

open(SEQ,"$sequence") or die ("sequence file $sequence not found!\n");
while(<STDIN>){
  chomp;
  my @row=split/\t/;
  if ($row[0] ne $seq[0]){
    my $x=<SEQ>;
    chomp $x;
    @seq=split /\t/,$x;
    $prev_position=-100;
  }
  if($row[0] ne $seq[0] or $row[2]!=$prev_position+1){
    @current_kmer_values=();
    $current_kmer="";
  }
  if(length($current_kmer)==$k){
    $current_kmer=substr($current_kmer,1,$k-1);
    shift @current_kmer_values;
  }
  $current_kmer.=substr($seq[1],$row[2]-$one_based,1);
  push @current_kmer_values,$row[5];
  $prev_position=$row[2];
  if (length($current_kmer)==$k){
   my $current_kmer_mean=0;
   for my $i (@current_kmer_values){
     $current_kmer_mean+=$i;
   }
   $current_kmer_mean/=$k;
   $sum{$current_kmer}+=$current_kmer_mean;
   $count{$current_kmer}++;
   if($dump){
     if ($dump_also_location)
       {
	 $cur_start_for_print = $row[2]-$k+1;
	 $cur_end_for_print = $cur_start_for_print+$k-1-$k+1;

	 print "$row[0]\t$current_kmer\t$cur_start_for_print\t$cur_end_for_print\t$current_kmer_mean\n";
       }
     else
       {
	 print "$current_kmer\t$current_kmer_mean\n";
     }
   }
  }
}
close(SEQ);

if (!$dump){
  for my $i (keys %sum){
    print $i,"\t",($sum{$i}+$sum{rc($i)})/($count{$i}+$count{rc($i)});
    if ($print_count){
      print "\t",($count{$i}+$count{rc($i)});
    }
    print "\n";
  }
}


sub rc{
    my $s=shift;
    if ($reverse_complement){
	$s=reverse($s);
	$s=~y/A/1/;
	$s=~y/T/A/;
	$s=~y/1/T/;
	$s=~y/C/1/;
	$s=~y/G/C/;
	$s=~y/1/G/;
    }
    return $s;
}

__DATA__

compute_kmer_stats.pl

given an extended chr file (STDIN) and a sequence file (-f), computes the mean value per kmer.
IMPORTANT: both files should be sorted, chr features should be 1 bp width (you can use
expand_locations.pl to get this from any chr file).

 -f <str> :     sequence file in stab format (required)
 -k <num> :     k of kmer (default: 5)
 -n :           print number of appearances of kmer (default off)
 -0 :           file is zero based (default: one based)
 -dump:         for each kmer instance print its coverage.
 -dump_also_location:         if -dump is active, prints for each kmer instance also its coordinates.
 -rc:           count each kmer together with its reverse complement (default off)


