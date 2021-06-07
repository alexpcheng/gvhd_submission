#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $CONSERVATION_PATH = "$ENV{GENIE_HOME}/Data/Comparative/Conservation/";



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
my $organism = get_arg("organism", "Yeast", \%args);
my $file_name = get_arg("conservation", 0, \%args);




# reading conservation
if (not $file_name) {
  $file_name = `ls $CONSERVATION_PATH/$organism/Ucsc/data*.chv | tail -1`;
  if ($? != 0) {
    print STDERR "Cannot find conservation file for organism $organism\n";
    exit 1;
  }
}
open(CONS, "$file_name") or die "Cannot open conservation file $file_name\n";
my ($cons_chr, $cons_id, $cons_start, $cons_end, $cons_type, $cons_width, $cons_length, $cons_data) = split("\t", <CONS>);
my ($next_chr, $next_id, $next_start, $next_end, $next_type, $next_width, $next_length, $next_data) = split("\t", <CONS>);

# reading input
while (<$file_ref>) {
  chomp $_;
  my ($chr, $id, $start, $end, $value) = split("\t", $_);

  while (($chr ne $cons_chr) or ($start < $cons_start)) {
    ($cons_chr, $cons_id, $cons_start, $cons_end, $cons_type, $cons_width, $cons_length, $cons_data) = 
      ($next_chr, $next_id, $next_start, $next_end, $next_type, $next_width, $next_length, $next_data);
    ($next_chr, $next_id, $next_start, $next_end, $next_type, $next_width, $next_length, $next_data) = split("\t", <CONS>);
  }

  while (($end > $cons_end) and ($next_chr eq $cons_chr)) {
    my $str = "";
    for (my $i = $cons_end; $i < $next_start; $i++) {
      $str = $str."0;"
    }
    $cons_end = $next_end;
    $cons_data = $cons_data.$str.$next_data;

    ($next_chr, $next_id, $next_start, $next_end, $next_type, $next_width, $next_length, $next_data) = split("\t", <CONS>);
  }

  if (($end > $cons_end) or ($start < $cons_start) or ($chr ne $cons_chr)) {
    print "$chr\t$id\t$start\t$end\t-1\n";
    next;
  }

  my @conservation = split(";", $cons_data);
  my $avg_cons;

  for (my $i = $start - $cons_start; $i <= $end - $cons_start; $i++) {
    $avg_cons = $avg_cons + $conservation[$i];
  }
  $avg_cons = $avg_cons/($end - $start + 1);

  print "$chr\t$id\t$start\t$end\t$avg_cons\n";
}
close(CONS);




# =============================================================================
# Subroutines
# =============================================================================


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

compute_conservation.pl <file_name> [options]

Given as input a SORTED chr file, compute conservation for each
location of the chr file.
Sorting order: chr, then start and then end (from smallest to largest)

Options:
   -organism <name>      Organism name (Default = Yeast).
   -conservation <file>  Conservation chv file.
