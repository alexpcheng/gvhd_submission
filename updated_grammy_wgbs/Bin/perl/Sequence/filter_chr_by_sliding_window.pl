#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help") {
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

my $window_size       = get_arg("window_size", 0, \%args);
my $threshold         = get_arg("threshold", 0, \%args);
my $report            = get_arg("report", 0, \%args);

if ($window_size < 2) {die "Error: Must specify window size (bigger then 1)."};
if ($threshold > $window_size or $threshold <= 0) {die "Error: Threshold must be positive and smaller than the window size"};

my %features_stats;
my %complete_features;
my @segment;

my $curr_segment = "";
my $start_pos;
my $curr_pos;
while (<$file_ref>)
{
   chop;
   my @row = split (/\t/);

   if ($row[0] ne $curr_segment)
   {
      print STDERR "Processing $curr_segment ...\n";
      &ProcessSegment();
      %features_stats = ();
      %complete_features = ();
      my @dummy_seg;
      @segment = @dummy_seg;
      $curr_segment = $row[0];
      $curr_pos = 0;
   }

   my $start_pos = $row[2] < $row[3] ? $row[2] : $row[3];

   $features_stats{$start_pos} = 0;
   $complete_features{$start_pos} = $_;

   while ($curr_pos < $start_pos)
   {
      push (@segment, 0);
      $curr_pos++;
   }
   push (@segment, 1);
   $curr_pos++;
}

&ProcessSegment();

sub ProcessSegment
{
   if ($#segment <= 0)
   {
      return;
   }

   my @features_in_curr_window;
   my $i;
   for ($i = 1; $i <= $window_size; $i++)
   {
      if ($segment[$i] == 1)
      {
	 push (@features_in_curr_window, $i);
	 for my $feat (@features_in_curr_window)
	 {
	    $features_stats{$feat} = $features_stats{$feat} < ($#features_in_curr_window + 1) ? ($#features_in_curr_window + 1) : $features_stats{$feat};
	 }
      }
      push (@segment, 0); # dummy values - to let window slide till the end of original segment
   }

   while ($i <= $#segment)
   {
      if ($segment[$i - $window_size] == 1)
      {
	 if ($report == 1)
	 {
	    print $complete_features{$i - $window_size}."\t".$features_stats{$i - $window_size}."\n";
	 }
	 elsif ($features_stats{$i - $window_size} >= $threshold)
	 {
	    print $complete_features{$i - $window_size}."\n";
	 }
	 
	 shift (@features_in_curr_window);
      }
      if ($segment[$i] == 1)
      {
	 push (@features_in_curr_window, $i);

	 for my $feat (@features_in_curr_window)
	 {
	    $features_stats{$feat} = $features_stats{$feat} < ($#features_in_curr_window + 1) ? ($#features_in_curr_window + 1) : $features_stats{$feat};
	 }
      }
      $i++;
   }
}
__DATA__

filter_chr_by_sliding_window.pl <chr file> 

   Filters a given chr file by the number of features that start in a given window size.

   -window_size <n>   : Size of window to slide over the file.
   -threshold <n>     : Threshold on the number of features in window size.

   -report            : Do not filter the file, only report for feature X the maximum number of features in a window that includes X.
