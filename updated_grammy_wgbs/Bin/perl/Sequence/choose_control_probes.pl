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

my $N_BINS = 100;

my %args = load_args(\@ARGV);

my $n_probes       = get_arg("n_probes", 0, \%args);
my $n_orgs         = get_arg("n_orgs", 0, \%args);
my $n_lengths      = get_arg("n_lengths", 0, \%args);

if ($n_probes <= 0) { die "Error: Number of probes must be positive.\n"; }
if ($n_orgs <= 0) { die "Error: Number of organisms must be positive.\n"; }
if ($n_lengths <= 0) { die "Error: Number of lengths must be positive.\n"; }
if ($n_orgs * $n_lengths > $n_probes) { die "Error: n_orgs * n_lengths > n_probes\n"; }

my $n_org_left = $n_orgs;
my $n_len_left = $n_lengths;

my $curr_probes = 0;

my $total_probes_for_org = int($n_probes / $n_orgs);
my $curr_probes_for_org = 0;

my $total_probes_for_len;
my $curr_probes_for_len = 0;

my %gc_bins;
my ($curr_id, $curr_org, $curr_gc, $curr_len, $curr_seq);
while (<$file_ref>)
{
   chop;
   if (length($_) == 0) 
   { 
      next; 
   }
   my @row  = split (/\t/);
   if ($row[1] ne $curr_org) # Switch org (and implicitly also len)
   {
      &ProcessOrg();
      %gc_bins = ();
      
      $curr_probes += $curr_probes_for_org + $curr_probes_for_len;
      print STDERR "$curr_probes_for_org probes for $curr_org\n";

      $total_probes_for_org = int(($n_probes - $curr_probes) / $n_org_left);
      $n_len_left = $n_lengths;
      $total_probes_for_len = int($total_probes_for_org / $n_len_left);
      
      $curr_probes_for_len = 0;
      $curr_probes_for_org = 0;
      
      print STDERR "Curr org: $row[1] (${n_org_left}/${n_orgs}). Total probes: ${curr_probes}/${n_probes}.\nProbes for org: ${curr_probes_for_org}/${total_probes_for_org}\nProbes for len ${n_len_left}/${n_lengths}: ${curr_probes_for_len}/${total_probes_for_len}\n\n";
      $n_len_left--;
      $n_org_left--;
   }
   elsif ($row[3] ne $curr_len) # Switch len
   {
      &ProcessOrg();
      %gc_bins = ();

      $curr_probes_for_org += $curr_probes_for_len;
      $total_probes_for_len = int(($total_probes_for_org - $curr_probes_for_org) / $n_len_left);
      $curr_probes_for_len = 0;
      print STDERR "Probes for next len ${n_len_left}/${n_lengths}: ${curr_probes_for_len}/${total_probes_for_len}\n\n";
      $n_len_left--;
   }

   ($curr_id, $curr_org, $curr_gc, $curr_len, $curr_seq) = @row;
   if ($curr_gc < 0 or $curr_gc > 1)
   {
      print STDERR "Warning: Skipping entry due to illegal GC content: $_\n";
      next;
   }
   if ($curr_len < 0)
   {
      print STDERR "Warning: Skipping entry due to illegal length: $_\n";
      next;
   }

   my $n_bin = int($curr_gc * $N_BINS);
   if (!$gc_bins{$n_bin})
   {
      $gc_bins{$n_bin} = $curr_id;
   }
   else
   {
      my $temp_str = $gc_bins{$n_bin};
      $temp_str .= "_SEP_".$curr_id;
      $gc_bins{$n_bin} = $temp_str;
   }
}

&ProcessOrg();

sub ProcessOrg
{

   # shuffle probes
   for (my $i = 0; $i <= $N_BINS; $i++)
   {
      if ($gc_bins{$i})
      {
	 my @ids_arr = split (/_SEP_/, $gc_bins{$i % $N_BINS});
	 for (my $iter = 0; $iter < 5; $iter++)
	 {
	    my $temp;
	    my $rand_cell;
	    for (my $j = 0; $j <= $#ids_arr; $j++)
	    {
	       $rand_cell = int(rand($#ids_arr));
	       $temp = $ids_arr[$j];
	       $ids_arr[$j] = $ids_arr[$rand_cell];
	       $ids_arr[$rand_cell] = $temp;
	    }
	 }
	 $gc_bins{$i} = join ('_SEP_', @ids_arr);
      }
   }

   my $probes_left = 1;

   while ($curr_probes_for_len < $total_probes_for_len and $curr_probes + $curr_probes_for_org + $curr_probes_for_len < $n_probes and $probes_left == 1)
   {
      my $found = 0;
      my $reached_max = 0;
      for (my $i = 0; $i <= $N_BINS and $reached_max == 0; $i++)
      {
	 if ($gc_bins{$i % $N_BINS})
	 {
	    $found = 1;
	    my @id_array = split (/_SEP_/, $gc_bins{$i % $N_BINS});
	    my $id = pop (@id_array);
	    if ($id)
	    {
	       print "$id\n";
	       $curr_probes_for_len++;
	       if ($curr_probes_for_len >= $total_probes_for_len or $curr_probes + $curr_probes_for_org + $curr_probes_for_len >= $n_probes)
	       {
		  $reached_max = 1;
	       }
	    }
	    if ($#id_array >= 0)
	    {
	       $gc_bins{$i % $N_BINS} = join ('_SEP_', @id_array);
	    }
	    else
	    {
	       delete $gc_bins{$i % $N_BINS};
	    }
	 }
      }
      if ($found == 0)
      {
	 $probes_left = 0;
      }
   }

   print STDERR "For $curr_org, $curr_len: ${curr_probes_for_len}/${total_probes_for_len}\n";

}

__DATA__

choose_control_probes.pl

    Chooses control sequences from the input file in as uniform way as possible (uniform over probe length and GC content).

    Input file format:   <probe_id> \t <org_id> \t <GC content> \t <probe_length> \t <probe_sequence>

    === Important === 
    Expecting input file to be sorted by org_id + probe_length (Recommendation: To maximize leftovers, sort the org_id's 
    from the one with the least probes to the one with the most.)

   -n_orgs <n>       : Number different of organisms in the file.
   -n_probes <n>     : Total number of probes to choose (will try to insert n_probes / #organisms per organism while using leftovers if exist).
   -n_lengths <n>    : Total number of different probes lengths.
