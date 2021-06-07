#!/usr/bin/perl

use strict;
use locale;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $filea = get_arg("A", "", \%args);
my $fileb = get_arg("B", "", \%args);
my $colsa_string = get_arg("1", 1, \%args);
my $colsb_string = get_arg("2", 1, \%args);
my $numeric_cols_string = get_arg("n", "", \%args);
my $outer_join = get_arg("o", 0, \%args);
my $outer_join_str = get_arg("os", "", \%args);
my $ignore_missing_file = get_arg("imf", "", \%args);

my $filea_ref;
my $fileb_ref;


my @colsa=split/\s*,\s*/,$colsa_string;
my @colsb=split/\s*,\s*/,$colsb_string;

my %numeric_cols;
my @numeric=split/\s*,\s*/,$numeric_cols_string;
for my $i (@numeric) {$numeric_cols{$i-1}=1;}

for (my $i=0;$i<scalar(@colsa);$i++){
  $colsa[$i]--;
  $colsb[$i]--;
}

if ($filea eq "STDIN"){
  $filea_ref=\*STDIN;
}
else{
  if (open FILEA,"$filea"){
    $filea_ref=\*FILEA;
  }
  else{
    if (!$ignore_missing_file) { die ("file A missing!\n") }
  }
}
if ($fileb eq "STDIN"){
  $fileb_ref=\*STDIN;
}
else{
  if (open FILEB,"$fileb"){
    $fileb_ref=\*FILEB;
  }
  else{
    if (!$ignore_missing_file) { die ("file B missing!\n") }
  }
}

if ($ignore_missing_file and !(-e $filea) and !(-e $fileb) and ($filea ne "STDIN") and ($fileb ne "STDIN")){
  die ("files missing!\n");
}
if ($ignore_missing_file and !(-e $filea) and ($filea ne "STDIN")){
  while(my $line=<$fileb_ref>){
	my %check;
	chomp $line;
	my @tmp=split /\t/,$line,-1;
	my @out;
	for my $i (@colsb){
	  push @out,$tmp[$i];
	  $check{$i}=1;
	}
	for (my $i=0;$i<scalar(@tmp);$i++){
	  if(!$check{$i}){push @out, $tmp[$i]}
	}
	print join("\t",@out),"\n";
      }
      exit;
}
if ($ignore_missing_file and !(-e $fileb) and ($fileb ne "STDIN")){
  while(my $line=<$filea_ref>){
	my %check;
	chomp $line;
	my @tmp=split /\t/,$line,-1;
	my @out;
	for my $i (@colsa){
	  push @out,$tmp[$i];
	  $check{$i}=1;
	}
	for (my $i=0;$i<scalar(@tmp);$i++){
	  if(!$check{$i}){push @out, $tmp[$i]}
	}
	print join("\t",@out),"\n";
      }
      exit;
}

my $tmp_a=<$filea_ref>;
chomp $tmp_a;
my @rowa=split /\t/,$tmp_a,-1;
my @a;
for (my $i=0;$i<scalar(@colsa);$i++){
  $a[$i] = $rowa[$colsa[$i]];
}

my $tmp_b=<$fileb_ref>;
chomp $tmp_b;
my @rowb=split /\t/,$tmp_b,-1;
my @b;
for (my $i=0;$i<scalar(@colsb);$i++){
  $b[$i] = $rowb[$colsb[$i]];
}

my $advance_a=0;
my $advance_b=0;
my $a_was_printed=0;
my $finished=0;

while(!$finished){
  my $cmp_ab=compare(\@a,\@b);
  if ($cmp_ab==0){
    print join("\t",@a);
    my @sorted_colsa=sort @colsa;
    my $j=0;
    for (my $i=0;$i<scalar(@rowa);$i++){
      if ($i==$sorted_colsa[$j]){
	$j++;
      }
      else{
	print "\t",$rowa[$i];
      }
    }
    my @sorted_colsb=sort @colsb;
    my $j=0;
    for (my $i=0;$i<scalar(@rowb);$i++){
      if ($i==$sorted_colsb[$j]){
	$j++;
      }
      else{
	print "\t",$rowb[$i];
      }
    }
    print "\n";
    $advance_a=1;
    $advance_b=1;
  }
  elsif ($cmp_ab==1){
    $advance_b=1;
    $advance_a=0;
  }
  elsif ($cmp_ab==-1){
    $advance_a=1;
    $advance_b=0;
  }
  if ($outer_join and ($cmp_ab==-1 or ($advance_b and eof($fileb_ref) and $cmp_ab!=0))){
    print join("\t",@a);
    my @sorted_colsa=sort @colsa;
    my $j=0;
    for (my $i=0;$i<scalar(@rowa);$i++){
      if ($i==$sorted_colsa[$j]){
	$j++;
      }
      else{
	print "\t",$rowa[$i];
      }
    }
    if ($outer_join_str ne "") { print "\t",$outer_join_str; }
    
    print "\n";
  }

  if ($advance_b and eof($fileb_ref)){
    $advance_a=1;
    $advance_b=0;
  }
  if ($advance_a and eof ($filea_ref)){ $finished=1 }

  if ($advance_a and !$finished){
    $tmp_a=<$filea_ref>;
    chomp $tmp_a;
    @rowa=split /\t/,$tmp_a,-1;
    for (my $i=0;$i<scalar(@colsa);$i++){
      $a[$i] = $rowa[$colsa[$i]];
    }
  }
  if ($advance_b and !$finished){
    $tmp_b=<$fileb_ref>;
    chomp $tmp_b;
    @rowb=split /\t/,$tmp_b,-1;
    for (my $i=0;$i<scalar(@colsb);$i++){
      $b[$i] = $rowb[$colsb[$i]];
    }
  }
}
if ($filea ne "STDIN"){close $filea_ref}
if ($fileb ne "STDIN"){close $fileb_ref}


sub compare{
  my $a=shift;
  my $b=shift;
  my @a=@{$a};
  my @b=@{$b};

  my $result;
  for (my $i=0;$i<scalar(@a);$i++){
    if ($numeric_cols{$i}){
      $result = $a[$i] <=> $b[$i];
    }
    else{
      $result = $a[$i] cmp $b[$i];
    }
    if ($result!=0) {return $result}
  }
  return 0;
}

__DATA__

sorted_join.pl

linear time join. IMPORTANT: input files must be sorted (otherwise the script won't stop).

  -A:           first file (specify STDIN for standard input)
  -B:           second file (specify STDIN for standard input)
  -1 <str>:     join columns in first file (1-based). default=1
  -2 <str>:     join columns in second file (1-based). default=1
  -n <str>:     columns that are sorted numerically (e.g if join is -1 3,6 -2 4,7 then
                -n 1 means that col 3 from file A and col 4 from file B are sorted
                numerically, and that col 6 from file A and col 7 from file B are
                sorted lexicographically)
  -o:           outer join (keeps all rows from first file).
  -os <str>:    in case of outer join, print all rows from first file and add <str>.
  -imf:         ignore missing file, i.e. if -A file doesnt exist output all -B entries, and vice versa.

