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

my %args = load_args(\@ARGV);

my $min_segment_length = get_arg("min", -1, \%args);
my $boundary_file = get_arg("f", "", \%args);
my $no_shuffle = get_arg("no_shuffle", "", \%args);



my @boundaries;

if ($boundary_file ne ""){
  open(BOUNDS,$boundary_file);
  while(<BOUNDS>){
    chomp;
    my @b=split /\t/;
    if($min_segment_length==-1 or $b[3]-$b[2]+1>=$min_segment_length){
      my %tmp;
      $tmp{chr}=$b[0];
      $tmp{start}=$b[2];
      $tmp{end}=$b[3];
      push @boundaries,\%tmp;
    }
  }
  close(BOUNDS);
}


my $finished=0;
my @locations;
my @distances;

my %boundary;
if ($boundary_file ne ""){
  %boundary=%{$boundaries[0]};
}

my $current_boundary=1;

while(!$finished){
  my $line=<$file_ref>;
  my @location;
  if ($line){
    chomp $line;
    @location=split /\t/,$line,5;
  }
  else{
    $finished=1;
  }


  if(scalar(@locations)>0 and ($finished or ($boundary_file eq "" and $location[0] ne $locations[$#locations][0]) or ($boundary_file ne "" and ($location[0] gt $boundary{chr} or ($location[0] eq $boundary{chr} and $location[3]>$boundary{end}))))){
    if ($min_segment_length==-1 or $locations[$#locations][3]-$locations[0][2]+1>$min_segment_length){
      if ($boundary_file ne ""){
	push @distances,($boundary{end}-$locations[$#locations][3]);
      }

      my $current_pos=$locations[0][2];
      if ($no_shuffle eq ""){
	shuffle(\@locations);
	shuffle(\@distances);
      }

      # print
      if ($boundary_file ne ""){
	$current_pos=$boundary{start}+$distances[0];
	shift @distances;
      }
      for (my $i=0;$i<scalar(@locations);$i++){
	print $locations[$i][0],"\t",$locations[$i][1],"\t",$current_pos,"\t";
	$current_pos+=$locations[$i][3]-$locations[$i][2];
	print $current_pos,"\t",$locations[$i][4],"\n";
	if ($i<scalar(@distances)){
	  $current_pos+=$distances[$i]+1;
	}
      }
    }

    if (!$finished){
      #restart
      @locations=();
      @distances=();
#      if ($boundary_file ne ""){
#	while($current_boundary<scalar(@boundaries) and ($boundary{chr} lt $location[0] or ($boundary{chr} eq $location[0] and $boundary{end}<$location[3]))){
#	  %boundary=%{$boundaries[$current_boundary]};
#	  $current_boundary++;
#	}
#	if ($current_boundary>=scalar(@boundaries)){
#	  last;
#	}
#     }
    }
  }

  if ($boundary_file ne ""){
    while($current_boundary<scalar(@boundaries) and ($boundary{chr} lt $location[0] or ($boundary{chr} eq $location[0] and $boundary{end}<$location[3]))){
      %boundary=%{$boundaries[$current_boundary]};
      $current_boundary++;
    }
  }


  if (!$finished and ($boundary_file eq "" or ($boundary{chr} eq $location[0] and $location[2]>=$boundary{start} and $location[3]<=$boundary{end}))){
    if(scalar(@locations)>0){
      push @distances,$location[2]-$locations[$#locations][3]-1;
    }
    else{
      if ($boundary_file ne ""){
	push @distances,($location[2]-$boundary{start});
      }
    }
    push @locations,\@location;
  }
}


sub shuffle{
  my $a=shift;

  my $n=scalar(@{$a});
  while($n>1){
    $n--;
    my $k=int(rand($n+1));

    my $tmp=$$a[$n];
    $$a[$n]=$$a[$k];
    $$a[$k]=$tmp;
  }
}




__DATA__

shuffle_locations.pl

Shuffles locations and distances between neighboring locations. Assumes files are sorted, locations are non-overlapping, and start<end.

  -f <str> :     boundary chr file (optional)
  -min <num>:    minimal segment length (default: none)
  -no_shuffle:   don't shuffle (useful for just filtering with -min)

