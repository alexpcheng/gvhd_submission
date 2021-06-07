#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

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
  open(FILE, $file_name) or die("Could not open $file_name.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $chv_file = get_arg("chv", 0, \%args);
if (not $chv_file) {
  print STDERR "You must specify a chv file\n";
  print STDERR <DATA>;
  exit;
}


# ---------
# Read input data
# ---------
my %data; # <chr> => [ <gene_start> => (gene_id, gene_end) ]
my %support; # <start> => [count of genes with this start]
while (<$file_ref>) {
  chomp $_;
  my @line = split("\t", $_); # <chr> <id> <start> <end>

  # convert opposite strand positions
  my $reverse = 0;
  if ($line[2] > $line[3]) {
    my $t = $line[2];
    $line[2] = $line[3];
    $line[3] = $t;
    $reverse = 1;
  }

  if (not defined $data{$line[0]}) {
    my %hash;
    $data{$line[0]} = \%hash;
  }
  my $hash_ref = $data{$line[0]};

  if (defined $$hash_ref{$line[2]}) {
    $support{$line[2]} += 2;
    my $support = 1-1/$support{$line[2]};
    $$hash_ref{$line[2]+$support} = [$line[1], $line[3], $reverse];
  }
  else {
    $$hash_ref{$line[2]} = [$line[1], $line[3], $reverse];
  }
}

#foreach my $t (keys %data) {
#  print "$t ==> {";
#  my $hash_ref = $data{$t};
#  foreach my $tt(keys %$hash_ref) {
#    my $array_ref = $$hash_ref{$tt};
#    print "$tt ==> ($$array_ref[0], $$array_ref[1]); ";
#  }
#  print "\n";
#}

# ---------
# Extract from chv
# ---------
open(CHV, $chv_file) or die("Cannot open $chv_file\n");

my $chr;
my $data_hash_ref;
my @starts;

my $prev_chv_end = 0;
while (<CHV>) {
  chomp $_;
  my @chv_line = split("\t", $_); # <chr> <id> <start> <end> <comment> <segment width> <length between segments> <values>
  if ((not defined $chr) or ($chr ne $chv_line[0])) {
    $chr = $chv_line[0];
    $data_hash_ref = $data{$chr};
    @starts = sort {$b <=> $a} (keys %$data_hash_ref); # first start is at the end of the list
  }

  my $p = scalar(@starts)-1;
  my @new_starts;
  my $re_sort = 0;

  while ($prev_chv_end <= $starts[$p] and $starts[$p] < $chv_line[2] and $p >= 0) { # prev. chv record end < gene start < chv record end

    $p = $p - 1;
    my $gene_start = pop(@starts);
    my $gene_data_ref = $$data_hash_ref{$gene_start};
    $gene_start = int($gene_start);
    my $gene_id = $$gene_data_ref[0];
    my $gene_end = $$gene_data_ref[1];
    my $gene_reverse = $$gene_data_ref[2];

    if ($p >= 0 and $gene_start < $chv_line[2] and $chv_line[2] < $gene_end) { # gene_start < chv record start < gene end
      $gene_start = $chv_line[2];
      my @v = split(";", $chv_line[7]);

      my $s = $gene_start - $chv_line[2];
      my $r = int($s/$chv_line[5]);

      if ($gene_end <= $chv_line[3]) { # gene ends <= chv record end
	my $e = $gene_end - $chv_line[2];
	if ($gene_reverse) {
	  my $values = $v[$r];
	  while ($r < scalar(@v) and $s < $e) {
	    $s = $s+$chv_line[6];
	    $r++;
	    $values = "$v[$r];".$values;
	  }
	  print "$chr\t$gene_id\t$gene_end\t$gene_start\t$chv_line[4]\t$chv_line[5]\t$chv_line[6]\t$values\n";
	}
	else {
	  my $values = $v[$r];
	  while ($r < scalar(@v) and $s < $e) {
	    $s = $s+$chv_line[6];
	    $r++;
	    $values = $values.";$v[$r]";
	  }
	  print "$chr\t$gene_id\t$gene_start\t$gene_end\t$chv_line[4]\t$chv_line[5]\t$chv_line[6]\t$values\n";
	}
      }
      else { # gene_end > chv record end
	my $e = $chv_line[3] - $chv_line[2];
	if ($gene_reverse) {
	  my $values = $v[$r];
	  while ($r < scalar(@v) and $s < $e) {
	    $s = $s+$chv_line[6];
	    $r++;
	    $values = "$v[$r];".$values;
	  }
	  print "$chr\t$gene_id\t$chv_line[3]\t$gene_start\t$chv_line[4]\t$chv_line[5]\t$chv_line[6]\t$values\n";
	}
	else {
	  my $values = $v[$r];
	  while ($r < scalar(@v) and $s < $e) {
	    $s = $s+$chv_line[6];
	    $r++;
	    $values = $values.";$v[$r]";
	  }
	  print "$chr\t$gene_id\t$gene_start\t$chv_line[3]\t$chv_line[4]\t$chv_line[5]\t$chv_line[6]\t$values\n";
	}

	$support{$chv_line[3]+1} += 2;
	my $support = 1-1/$support{$chv_line[3]+1};

	push (@new_starts, $chv_line[3]+1+$support);
	$$data_hash_ref{$chv_line[3]+1+$support} = [$gene_id, $gene_end, $gene_reverse];
	$re_sort = 1;
      }
    }
  }

  if ($chv_line[2] <= $starts[$p] and $starts[$p] < $chv_line[3]) { # chv record start < gene start < chv record end
    my @v = split(";", $chv_line[7]);

    while ($p >= 0 and $starts[$p] < $chv_line[3]) { # chv record start < gene start < chv record end
      $p = $p - 1;
      my $gene_start = pop(@starts);
      my $gene_data_ref = $$data_hash_ref{$gene_start};
      $gene_start = int($gene_start);
      my $gene_id = $$gene_data_ref[0];
      my $gene_end = $$gene_data_ref[1];
      my $gene_reverse = $$gene_data_ref[2];

      my $s = $gene_start - $chv_line[2];
      my $r = int($s/$chv_line[5]);

      if ($gene_end <= $chv_line[3]) { # gene ends <= chv record end
	my $e = $gene_end - $chv_line[2];
	if ($gene_reverse) {
	  my $values = $v[$r];
	  while ($r < scalar(@v) and $s < $e) {
	    $s = $s+$chv_line[6];
	    $r++;
	    $values = "$v[$r];".$values;
	  }
	  print "$chr\t$gene_id\t$gene_end\t$gene_start\t$chv_line[4]\t$chv_line[5]\t$chv_line[6]\t$values\n";
	}
	else {
	  my $values = $v[$r];
	  while ($r < scalar(@v) and $s < $e) {
	    $s = $s+$chv_line[6];
	    $r++;
	    $values = $values.";$v[$r]";
	  }
	  print "$chr\t$gene_id\t$gene_start\t$gene_end\t$chv_line[4]\t$chv_line[5]\t$chv_line[6]\t$values\n";
	}
      }
      else { # gene_end > chv record end
	my $e = $chv_line[3] - $chv_line[2];
	if ($gene_reverse) {
	  my $values = $v[$r];
	  while ($r < scalar(@v) and $s < $e) {
	    $s = $s+$chv_line[6];
	    $r++;
	    $values = "$v[$r];".$values;
	  }
	  print "$chr\t$gene_id\t$chv_line[3]\t$gene_start\t$chv_line[4]\t$chv_line[5]\t$chv_line[6]\t$values\n";
	}
	else {
	  my $values = $v[$r];
	  while ($r < scalar(@v) and $s < $e) {
	    $s = $s+$chv_line[6];
	    $r++;
	    $values = $values.";$v[$r]";
	  }
	  print "$chr\t$gene_id\t$gene_start\t$chv_line[3]\t$chv_line[4]\t$chv_line[5]\t$chv_line[6]\t$values\n";
	}

	$support{$chv_line[3]+1} += 2;
	my $support = 1-1/$support{$chv_line[3]+1};

	push (@new_starts, $chv_line[3]+1+$support);
	$$data_hash_ref{$chv_line[3]+1+$support} = [$gene_id, $gene_end, $gene_reverse];
	$re_sort = 1;
      }
    }
  }

  if ($re_sort) {
    push (@starts, @new_starts);
    @starts = sort {$b <=> $a} (@starts);
  }
  $prev_chv_end = $chv_line[3];
}

close(CHV);


# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

extract_from_chv.pl <chr_file> [options]

  Extract the given location values from a chv file.
  Input file is in chr format (<chr> <id> <start> <end> <comments>).

  Output file format:
   <chr> <id> <start> <end> <type> <seg. width> <seg. length> <values ...>

OPTIONS
  -chv <file>      The chv file to extract locations from.
