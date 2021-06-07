#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

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

my %args = load_args(\@ARGV);
my $skipc = get_arg("skipc", 0, \%args);
my $dist_file = get_arg("d", "", \%args);
my $mean_column = get_arg("m", "", \%args);
my $count_column = get_arg("c", 0, \%args);
my $dist_column = get_arg("dc", 0, \%args);
my $n = get_arg("n", 100, \%args);
my $precision = get_arg("p", 0, \%args);

if ($precision ne "0"){ $precision=10**(-$precision); }

my @dist;

open (DIST,$dist_file) or die ("file \"$dist_file\" wasnt found!\n");
while(<DIST>){
  chomp;
  my @row=split/\t/;
  push @dist,$row[$dist_column];
}
close(DIST);

my $dist_mean=0;
for (@dist){$dist_mean+=$_}
$dist_mean/=scalar(@dist);

for my $i (1..$skipc){print "Header\t"}
print "Counts\tDistCounts\t";
if ($mean_column ne ""){print "Mean\t"}
print "DistMean\tN\tRand Min\tRand Max";
if ($mean_column ne ""){print "\tRand<=Mean\tRand>=Mean"}
print "\n";

while(my $line=<$file_ref>){
  chomp $line;
  my @row=split/\t/,$line;
  my @headers;
  for my $i (1..$skipc){
    push @headers,$row[$i-1];
  }
  my $observed_mean;
  if ($mean_column ne ""){$observed_mean=$row[$mean_column]}
  my $count=$row[$count_column];
  my $max="";
  my $min="";
  my $counts_larger_than=0;
  my $counts_smaller_than=0;
  for my $i (1..$n){
    my $random_mean=sample_mean($count);
    if ($mean_column ne ""){
      if ($random_mean+$precision>=$observed_mean){$counts_larger_than++}
      if ($random_mean-$precision<=$observed_mean){$counts_smaller_than++}
    }
    if ($max eq "" or $random_mean>$max){$max=$random_mean}
    if ($min eq "" or $random_mean<$min){$min=$random_mean}
  }

  for (@headers){print "$_\t"}
  print "$count\t",scalar(@dist),"\t";
  if ($mean_column ne ""){print "$observed_mean\t"}
  print "$dist_mean\t$n\t$min\t$max";
  if ($mean_column ne ""){print "\t",$counts_smaller_than/$n, "\t",$counts_larger_than/$n}
  print "\n";
}

sub sample_mean{
  my $num=shift;

  my @a=@dist;
  my $sum=0;
  for my $j (1..$num){
    $sum+=splice @a,int(rand(scalar(@a))),1;
  }
  $sum/=$num;
}



__DATA__

compute_mean_empirical_pvalue.pl

given a distribution file, and a file specifying counts C and means M (from stdin),
calculates the mean of Ci randomly sampled instances, repeats n times, and outputs
relevant statistics, including what fractions of the samples had a mean that is
smaller/larger than Mi (i.e. empirical p-value).
If mean is unspecified, calculates the maximal and minimal sample means.

 flags:

 -d <file>        name of distribution file (REQUIRED)
 -dc <num>         number of relevant column in distrubtion file (default: 0)
 -skipc <num>     number of header columns to skip in counts file (default: 0)
 -m <num>         number of means column in counts file (default: mean is unspecified)
 -c <num>         number of counts column in counts file (default: 0)
 -n <num>         number of randomizations
 -p <num>         precision, i.e. if random_mean+10**(-num)>=mean then we consider random_mean
                  to be greater than mean. if num==0 simply compares random_mean>=mean (this
                  is the default behavior).

