#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $database_file = get_arg("d", "", \%args);
my $query_file = get_arg("q", "", \%args);
my $kmer = get_arg("k", 40, \%args);
my $max_hits = get_arg("max", 1, \%args);
my $print_sequences = get_arg("seq", 0, \%args);
my $reverse_complement = get_arg("rc", 0, \%args);
my $query_start_position = get_arg("qs", 0, \%args);

my $MAX_DATABASE_HASH_SIZE = 1000000;
my $MAX_QUERY_INDICES = 1000000;
my $unique_counter = 1;

my @database_row;
my %database_hash;
my $database_hash_size = 0;

my %query_active_indices;
my @query_row;
my $query_length;
my $rc_query;

open(QUERY, "<$query_file") or die "Could not open query file $query_file\n";
while(<QUERY>)
{
  chomp;

  @query_row = split(/\t/);

  if ($reverse_complement == 1)
  {
    $rc_query = &ReverseComplement($query_row[1]);
  }

  $query_length = length($query_row[1]);
  for (my $i = $query_start_position; $i < $query_length - $kmer + 1;)
  {
    my $start = $i;
    %query_active_indices = ();
    my $query_active_indices_size = 0;
    while ($query_active_indices_size < $MAX_QUERY_INDICES and ($i < $query_length - $kmer + 1))
    {
      if (not(substr($query_row[1], $i, $kmer) =~ /N/))
      {
	$query_active_indices{$i} = 0;
	$query_active_indices_size++;
      }

      $i++;
    }

    print STDERR "Processing query $query_row[0] $start..$i\n";

    open(DATABASE, "<$database_file") or die "Could not open database file $database_file\n";
    while(<DATABASE>)
    {
      chomp;

      @database_row = split(/\t/);

      my $database_length = length($database_row[1]);
      for (my $j = 0; $j < $database_length; $j++)
      {
	if ($j > 0 and $j % 1000000 == 0) { print STDERR "Database index is $database_row[0] $j\n"; }

	my $hash_seq = substr($database_row[1], $j, $kmer);

	if (not($hash_seq =~ /N/))
	{
	  my $item_count = $database_hash{$hash_seq}++;
	  if ($item_count == 0)
	  {
	    $database_hash_size++;

	    if ($database_hash_size == $MAX_DATABASE_HASH_SIZE)
	    {
	      &CompareQuery();
	    }
	  }
	}
      }
    }

    &CompareQuery();

    &PrintActiveQueries();
  }
}

sub CompareQuery
{
  #print STDERR "ComparingQuery\n";

  my %new_query_active_indices = ();
  foreach my $q (keys %query_active_indices)
  {
    my $query_sequence = substr($query_row[1], $q, $kmer);
    $query_active_indices{$q} += $database_hash{$query_sequence};

    if ($reverse_complement == 1)
    {
      my $rc_query_sequence = substr($rc_query, $query_length - ($q + $kmer), $kmer);
      if ($query_sequence ne $rc_query_sequence)
      {
	$query_active_indices{$q} += $database_hash{$rc_query_sequence};
      }
    }

    if ($query_active_indices{$q} <= $max_hits)
    {
      $new_query_active_indices{$q} = $query_active_indices{$q};
    }
  }
  %query_active_indices = %new_query_active_indices;

  %database_hash = ();
  $database_hash_size = 0;
}

sub PrintActiveQueries
{
  my @query_active_indices_array;
  foreach my $q (keys %query_active_indices)
  {
    push(@query_active_indices_array, $q);
  }
  @query_active_indices_array = sort { $a <=> $b } @query_active_indices_array;

  foreach my $q (@query_active_indices_array)
  {
    print "$query_row[0]\t$unique_counter\t$q\t";
    print ($q + $kmer - 1);

    if ($print_sequences == 1)
    {
      print "\t";
      print substr($query_row[1], $q, $kmer);
    }

    print "\n";

    $unique_counter++;
  }
}

__DATA__

find_unique_kmers.pl

   Given a query and a database stab file, output all kmers in the query
   file that appear more than a specified number of times in the database

   -d <str>:   Database stab file
   -q <str>:   Query stab file
   -qs <num>:  Query start position in bp (default: 0)

   -k <num>:   Kmer length to search for (default: 40)
   -rc:        Consider reverse complement hits as well

   -max <num>: Maximum number of times that the kmer is allowed to appear in the database (default: 1)

   -seq:       Output the sequences that are not unique (default: actual sequences are not printed)

