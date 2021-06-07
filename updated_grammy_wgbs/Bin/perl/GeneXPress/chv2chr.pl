#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $unique_ids = get_arg("u", "", \%args);
my $no_feature_name = get_arg("nfn", "", \%args);
my $buffer_size = get_arg("b", 0, \%args);

if ($buffer_size){
  my $buffer="";
  my $chr;
  my $id;
  my $offset;
  my $start;
  my $end;
  my $feature;
  my $width;
  my $val;
  my $pos;
  my $finished=0;
  my $n=0;
  while(!$finished){
    while (!($buffer=~/;/) and !$finished){
      if(!(read STDIN,$buffer,$buffer_size,length($buffer))){
	$finished=1;
      }
    }
    my @x=split /;/,$buffer,-1;
    $buffer=$x[$#x];
    for (my $i=0;$i<$#x+$finished;$i++) {
      if($x[$i]=~/^(\S+)\n*$/){
	print $chr,"\t",$id,($unique_ids ne ""?"_$n":""),"\t",$start+$pos,"\t",$start+$width-1+$pos,"\t",$feature,"\t",$1,"\n";
	$n++;
	$pos+=$offset;
      }
      else{
	my @rows=split /\n/,$x[$i];
	for (@rows){
	  if(/^(\S+)$/){
	    print $chr,"\t",$id,($unique_ids ne ""?"_$n":""),"\t",$start+$pos,"\t",$start+$width-1+$pos,"\t",$feature,"\t",$1,"\n";
	    $n++;
	    $pos+=$offset;
	  }
	  else{
	    ($chr,$id,$start,$end,$feature,$width,$offset,$val)=split /\t/;

	    if ($no_feature_name ne ""){
	      $val=$offset;
	      $offset=$width;
	      $width=$feature;
	      $feature=$no_feature_name;
	    }
	    
	    $pos=0;
	    if ($val ne ""){
	      print $chr,"\t",$id,($unique_ids ne ""?"_$n":""),"\t",$start+$pos,"\t",$start+$width-1+$pos,"\t",$feature,"\t",$val,"\n";
	      $n++;
	      $pos+=$offset;
	    }
	  }
	}
      }
    }
  }
}

else{
  while (<STDIN>){
    chomp;
    (my $chr, my $id, my $start, my $end, my $feature, my $width, my $offset, my $val)=split /\t/;
    if ($no_feature_name ne ""){
      $val=$offset;
      $offset=$width;
      $width=$feature;
      $feature=$no_feature_name;
    }
    my @values=split /;/,$val;
    my $i=0;
    my $n=0;
    my $uniqid="";
    for my $v (@values){
      if ($unique_ids ne ""){
	$uniqid="_$n";
      }
      print "$chr\t$id",$uniqid,"\t",$start+$i,"\t",$start+$i+$width-1,"\t$feature\t$v\n";
      $i+=$offset;
      $n++;
    }
  }
}


__DATA__

chv2chr.pl

  converts standard input from chv format to chr format

  options:

    -b <num>:        read file using a buffer of size <num> (default: read one line at a time)
    -u:              create unique id for each feature
    -nfn <string>:   no feature name is specified in input file (i.e. the feature name
                     field is missing). feature name will be specified as <string> in the
                     output chr file (default string = 1 if this option is chosen)


