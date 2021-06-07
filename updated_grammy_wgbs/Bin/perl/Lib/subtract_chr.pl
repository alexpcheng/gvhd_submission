#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my %args = load_args(\@ARGV);
my $infile = get_arg("f", "", \%args);

my @loclist1;
my @loclist2;

while(<STDIN>){
  chomp;
  my @a=split/\t/,$_,5;
  my %tmp_feat=("chr"=>$a[0],"name"=>$a[1],"start"=>$a[2],"end"=>$a[3],"rest"=>$a[4]);
  push @loclist1, \%tmp_feat;
}

open (IN,$infile) or die "cant open -f file\n";
while(<IN>){
  chomp;
  my @a=split/\t/;
  my %tmp_feat=("chr"=>$a[0],"name"=>$a[1],"start"=>$a[2],"end"=>$a[3]);
  push @loclist2, \%tmp_feat;
}



for my $a (0..$#loclist1){
  for my $b (0..$#loclist2){
    my $aleft=$loclist1[$a]{start}<$loclist1[$a]{end}?$loclist1[$a]{start}:$loclist1[$a]{end};
    my $aright=$loclist1[$a]{start}<$loclist1[$a]{end}?$loclist1[$a]{end}:$loclist1[$a]{start};
    my $bleft=$loclist2[$b]{start}<$loclist2[$b]{end}?$loclist2[$b]{start}:$loclist2[$b]{end};
    my $bright=$loclist2[$b]{start}<$loclist2[$b]{end}?$loclist2[$b]{end}:$loclist2[$b]{start};
    my $dispose=0;
    my $divide=0;
    if ($loclist1[$a]{chr} eq $loclist2[$b]{chr} and !$loclist1[$a]{dispose}){
      if ($aleft<=$bright and $aleft>=$bleft and $aright>$bright){
	$aleft=$bright+1;
      }
      elsif ($aleft<$bleft and $aright>=$bleft and $aright<=$bright){
	$aright=$bleft-1;
      }
      elsif ($aleft<$bleft and $aright>$bright){
	$divide=1;
	$dispose=1;
	print STDERR "WARNING: a feature was divided! \n";
	print STDERR "features were:\n", $loclist1[$a]{chr}, "\t", $loclist1[$a]{name}, "\t", $loclist1[$a]{start}, "\t", $loclist1[$a]{end}, "\t\n";
	print STDERR $loclist2[$b]{chr}, "\t", $loclist2[$b]{name}, "\t", $loclist2[$b]{start}, "\t", $loclist2[$b]{end}, "\t\n";
	
      }
      elsif ($aleft>=$bleft and $aright<=$bright){
	$dispose=1;
      }
    }
    if($dispose){ $loclist1[$a]{dispose}=1 }
    if($loclist1[$a]{start}<$loclist1[$a]{end}){
      $loclist1[$a]{start}=$aleft;
      $loclist1[$a]{end}=$aright;
    }
    else{
      $loclist1[$a]{start}=$aright;
      $loclist1[$a]{end}=$aleft;
    }
  }
}

for my $a (@loclist1){
  if (!$$a{dispose}){
    print $$a{chr},"\t",$$a{name},"\t",$$a{start},"\t",$$a{end},"\t",$$a{rest},"\n";
  }
}


__DATA__

subtract_chr.pl

subtracts chr locations (-f file) from chr standard input file.

  parameters:

-f :   chr file to subtract



