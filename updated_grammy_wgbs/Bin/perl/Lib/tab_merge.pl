#!/usr/bin/perl

#use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $names= get_arg("n","", \%args);


my @files;
for (my $i=0;$i<scalar(@ARGV);$i++){
  if ($ARGV[$i]=~/^-/){$i++}
  else{push @files,$ARGV[$i]}
}

my @header;
for (my $i=0;$i<scalar(@files);$i++){
  my $fh="FILE$i";
  open ($fh,$files[$i]) ;
  my $x=<$fh>;
  chomp $x;
  my @a=split/\t/,$x,-1;
  if ($#header==-1){
    @header=@a;
  }
  else{
    $header[0]=$header[0].";".$a[0];
  }
}
if ($names ne ""){$header[0]=$names}
print join("\t",@header),"\n";

while(!eof(FILE1)){
  my @lines;
  for (my $i=0;$i<scalar(@files);$i++){
    my $fh="FILE$i";
    my $x=<$fh>;
    chomp $x;
    @{$lines[$i]}=split/\t/,$x,-1;
  }
  print $lines[0][0];
  for (my $i=1;$i<scalar(@header);$i++){
    print "\t";
    print $lines[0][$i];
    for (my $j=1;$j<scalar(@files);$j++){
      print ";",$lines[$j][$i];
    }
  }
  print"\n";
}

for (my $i=0;$i<scalar(@files);$i++){
  my $fh="FILE$i";
  close ($fh) ;
}


#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         tab_merge.pl [flags] <matrix1.tab> <matrix2.tab> ... <matrixN.tab>

 Description:    Given matrices in tab file format (assume one row header + one column header, same in each of the
                 files except the header (0,0) cell), merge them into one multiple tab file (mtab format). the value
                 at each cell (ij) is v1;v2;...;vN (vk is the value from matrix k at cell ij).

 Flags:

  -n <str>       The name of the new (merged) tab, i.e. the header cell at (0,0) (default: merge of header (0,0) cells).


