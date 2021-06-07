#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

my $MAXDOUBLE = 1.79769e+308;
my $EPS = 0.00000001;



# =============================================================================
# Main part
# =============================================================================

# reading arguments
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file_name = $ARGV[0];
if (length($file_name) < 1 or $file_name =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  shift(@ARGV);
  open(FILE, $file_name) or die("Could not open file '$file_name'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $column = get_arg("c", 0, \%args);
my $key = get_arg("k", -1, \%args);
my $inclease_ranks = get_arg("m", 0, \%args);

my @lines = ();
my %values = ();
my $curr_key_value = "";
my $i = 0;

while (<$file_ref>) {
  my $line = $_;
  chomp $line;
  my @line_values = split("\t", $line);

  # same key value
  if (($key < 0) or ($curr_key_value eq $line_values[$key])) {

    if (defined $values{$line_values[$column]}) {
      my $ref = $values{$line_values[$column]};
      push(@$ref, $i);
    }
    else {
      my @array;
      push(@array, $i);
      $values{$line_values[$column]} = \@array;
    }

    push(@lines, $line);
    $i++;
  }

  # new key value
  else {

    # sort and print the current batch of lines
    if (scalar(@lines) > 0) {

      my @sorted_keys = sort {$a <=> $b} keys(%values);
      my $rank = 1;

      foreach my $k (@sorted_keys) {
	my $pos = $values{$k};

	foreach my $p (@$pos) {
	  my $str = $lines[$p];

	  my @v = split("\t", $str);
	  for (my $r = 0; $r <= $column; $r++) {
	    print "$v[$r]\t";
	  }
	  print "$rank";
	  for (my $r = $column + 1; $r < scalar(@v); $r++) {
	    print "\t$v[$r]";
	  }
	  print "\n";

	  if ($inclease_ranks) {
	    $rank++;
	  }
	}

	if (not $inclease_ranks) {
	  $rank += scalar(@$pos);
	}	
      }
    }

    # continue
    @lines = ();
    push(@lines, $line);

    %values = ();
    my @array;
    push(@array, 0);
    $values{$line_values[$column]} = \@array;

    $curr_key_value = $line_values[$key];
    $i = 1;
  }
}

# last key value
if (scalar(@lines) > 0) {
  my @sorted_keys = sort {$a <=> $b} keys(%values);
  my $rank = 1;

  foreach my $k (@sorted_keys) {
    my $pos = $values{$k};

    foreach my $p (@$pos) {
      my $str = $lines[$p];

      my @v = split("\t", $str);
      for (my $r = 0; $r <= $column; $r++) {
	print "$v[$r]\t";
      }
      print "$rank";
      for (my $r = $column + 1; $r < scalar(@v); $r++) {
	print "\t$v[$r]";
      }
      print "\n";

      if ($inclease_ranks) {
	$rank++;
      }
    }

    if (not $inclease_ranks) {
      $rank += scalar(@$pos);
    }
  }
}



# =============================================================================
# Subroutines
# =============================================================================


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

add_ranks.pl <file_name> [options]

Add ranks to a specific column.

OPTIONS:
   -c <num>     The column to add ranks to (default = 0)
   -k <num>     A column to be used as a key, i.e., whenever the value of the key column
                changes, start ranking from the beginning.
   -m           Rank similar values with increasing ranks
