#!/usr/bin/perl
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $WC_DIR = "wc";

if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $groups = get_arg("g", 10, \%args);
my $feature_name = get_arg("f", "1", \%args);

my @feature_list = split(/\+/, $feature_name);

$feature_list[0] =~ m/(\d+)/g;
my $len = `cat Features/$1.tab | wc -l`;
chomp $len;
my $group_size = int($len/$groups);
my $reminder = $len - ($group_size*$groups);
print STDERR "$len, $groups, $group_size, $reminder\n";

for (my $f = 0; $f < scalar(@feature_list); $f++) {
  $feature_list[$f] =~ m/(\d+)/g;
  $feature_list[$f] = $1;
  my $feature = $1;

  # read the feature
  my @list;
  open(FEATURE, "Features/$feature.tab") or die "Cannot read Features/$feature.tab\n";
  while (<FEATURE>) {
    push(@list, $_);
  }
  close(FEATURE);
  my @sorted_list = sort @list;

  # print comparison files : part $i with itself
  mkdir "Parallel_$feature_name";
  for (my $i = 0; $i < $groups; $i++) {
    mkdir "Parallel_$feature_name/part_$i";
    system("cd Parallel_$feature_name/part_$i; ln -s ../../Makefile .; cd ../../;");

    open(FILE, ">Parallel_$feature_name/part_$i/$feature.tab") or die "Cannot create feature file\n";
    my $add = $i < $reminder ? $i : $reminder;
    for (my $k = $group_size*$i+$add; $k < $group_size*($i+1)+$add+($i<$reminder); $k++) {
      print FILE "$sorted_list[$k]";
    }
    close(FILE);
  }

  # print comparison files : part $i with other parts
  for (my $i = 0; $i < $groups; $i++) {
    for (my $j = $i+1; $j < $groups; $j++) {
      mkdir "Parallel_$feature_name/part_$i"."_$j";
      system("cd Parallel_$feature_name/part_$i"."_$j; ln -s ../../Makefile .; cd ../../; ".
	     "cp Parallel_$feature_name/part_$i/$feature.tab Parallel_$feature_name/part_$i"."_$j/$feature.tab; ".
	     "cp Parallel_$feature_name/part_$j/$feature.tab Parallel_$feature_name/part_$i"."_$j/$feature.tab.co");
    }
  }
}

# print results
for (my $i = 0; $i < $groups; $i++) {

  # part $i with itself
  print "cd Parallel_$feature_name/part_$i; ".
        "q.pl make distances_$feature_name fpath=Parallel_$feature_name/part_$i/ dpath=Parallel_$feature_name/part_$i/dist_;\n";

  # part $i with other parts
  for (my $j = $i+1; $j < $groups; $j++) {
    my $str = "";
    for(my $f = 1; $f <= scalar(@feature_list); $f++) {
      $str = $str."-c$f Parallel_$feature_name/part_$i"."_$j/$feature_list[$f-1].tab.co ";
    }
    chop $str;
    print "cd Parallel_$feature_name/part_$i"."_$j; ".
          "q.pl make distances_$feature_name comp=\"$str\" fpath=Parallel_$feature_name/part_$i"."_$j/ dpath=Parallel_$feature_name/part_$i"."_$j/dist_;\n";
  }
}


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__
parallel_dist.pl

Take feature file and create comparison directories.

OPTIONS:
  -f <name>  Feature to use.
  -g <num>   Split ids into <num> groups [Default = 10].
             This means there will be 0.5*(<num>^2+<num>) sets
             [Default = 55]
