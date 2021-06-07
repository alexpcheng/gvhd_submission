#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/libfile.pl";
require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}
my %args = load_args(\@ARGV);
my $out_prefix = get_arg("op", "", \%args);
my $out_suffix = get_arg("os", "", \%args);
my $manual_names = get_arg("n", "", \%args);

my $h=<STDIN>;
chomp $h;
my @header=split/\t/,$h,-1;
my @names=split/;/,(shift @header);
if($manual_names ne ""){@names=split/;/,$manual_names}
my @file_handles;

for (my $i=0;$i<scalar(@names);$i++){
  open($file_handles[$i],">$out_prefix".$names[$i]."$out_suffix");
  print {$file_handles[$i]} $names[$i],"\t",join("\t",@header),"\n";
}
while(<STDIN>){
  chomp;
  my @line=split/\t/,$_,-1;
  my $line_name=shift @line;
  for (my $i=0;$i<scalar(@names);$i++){
    print {$file_handles[$i]} $line_name;
  }
  for my $cell (@line){
    my @entries=split/;/,$cell;
    for (my $i=0;$i<scalar(@names);$i++){
      print {$file_handles[$i]} "\t",$entries[$i];
    }
  }
  for (my $i=0;$i<scalar(@names);$i++){
    print {$file_handles[$i]} "\n";
  }
 
}
for (my $i=0;$i<scalar(@names);$i++){
  close($file_handles[$i]);
}



__DATA__

 mtab2tab.pl

 -op <str>    : prefix for names of output tab files (default: none)
 -os <str>    : suffix for names of output tab files (default: none)
  -n <str>    : give names of tabs manually, separated by semicolons (default: read from file)


