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
my $type = get_arg("t", "", \%args);
my $feature = get_arg("f", "", \%args);
my $empty = get_arg("e", 0, \%args);
my $n_param = get_arg("n", "", \%args);
my $filler = get_arg("l", "0.000", \%args);
my $debug  = get_arg("debug", 0, \%args);
my $minplus = get_arg("mp", 0, \%args);



# ------------------------------------------------
# Step 1 -- turn refseq into temporary chr
# ------------------------------------------------
print STDERR "Building coordinate lists... ";

my $r = int(rand(10000));
open COORDINATES, "> tmp_chr_$r" or die "Can't open tmp_chr_$r : $!";

while (<$file_ref>)
{
	chomp;

	my ($chrom, $strand, $name, $tstart, $tend, $AccCount, $exstarts, $exends, $exoccurrence) = split("\t");
	
	$chrom =~ s/chr//g;
	
	my @exonS = split (",", $exstarts);
	@exonS = grep /\S/, @exonS;
	my @exonE = split (",", $exends);
	@exonE = grep /\S/, @exonE;
	my $nExons = scalar @exonS;
	
	my $outputline = "";
	
	for (my $i=0; $i< $nExons; $i++)
	{
		my $curline = "$chrom\t$name" . "_" . $strand . ($i+1) . "\t" . SE ($exonS[$i], $exonE[$i], $strand);
		
		if ($minplus)
		{
			$curline .= "\t" . $strand;
		}
		
		$curline .= "\n";

		if ($strand eq "+")
		{
			$outputline = $outputline . $curline;
		}
		else
		{
			$outputline = $curline . $outputline;		
		}
	}
	
	print COORDINATES $outputline;
}

close COORDINATES;
print STDERR "OK\n";

# ------------------------------------------------
# Step 2 -- extract sequence
# ------------------------------------------------
if ($type eq "sequence")
{
	print STDERR "Extracting sequence... ";
	
	my $mp = $minplus ? "-mp" : "";
	
	system ("extract_sequence.pl -f -dn -f tmp_chr_$r $mp < $feature > tmp_seq_$r");
	
	print STDERR "OK.\nMerging exons... ";
	system ("cat tmp_seq_$r | modify_column.pl -c 0 -splt_d \"_\" | cut -f 1,3 | average_rows.pl -list -delim \",\" -n |".
		" modify_column.pl -c 2 -rmre \",\" | cut.pl -f 2,3 > tmp_mer_$r");
	
	print STDERR "OK.\nConstructing output... ";
	system ("cat tmp_mer_$r");
        print STDERR "OK.\n";
}

# ------------------------------------------------
# Step 2 -- extract conservation
# ------------------------------------------------
elsif ($type eq "conservation")
{
  print STDERR "Extracting conservation ... ";
  system ("cat tmp_chr_$r | extract_from_chv.pl -chv $feature > tmp_con_$r");

  print STDERR "OK.\nMerging segments... ";
  merge_segments($r, $debug);

  print STDERR "OK.\nMerging exons... ";
  system ("cat tmp_com_$r | modify_column.pl -c 0 -splt_d \"_\" | cut -f 1,3 |".
	  " average_rows.pl -list -delim \";\" -n | cut.pl -f 2,3 > tmp_mer_$r");
	
  print STDERR "OK.\nConstructing output... ";
  system ("cat tmp_mer_$r");
  print STDERR "OK.\n";
}

if ($debug == 0)
{
  system ("rm -rf tmp_???_$r");
}



##################################################################

# ------------------------------------------------
#
# ------------------------------------------------
sub SE {

	my ($start, $end, $strand) = @_;

	if ($strand eq "+")
	{
		return ($start + 1) . "\t" . ($end + 1);	
	}
	else
	{
		return ($end + 1) . "\t" . ($start + 1);
	}
}

# ------------------------------------------------
#
# ------------------------------------------------
sub merge_segments($$) {
  my ($r, $debug) = @_;

  # read chr data
  my %data;
  open (CHR, "tmp_chr_$r") or die "Cannot read chr \n";
  while (<CHR>) {
    chomp $_;
    my ($chr, $id, $start, $end) = split ("\t", $_);
    $data{$id} = [$start, $end, $end-$start>0, ""];
  }
  close(CHR);

  # read conservation data
  open (CHV, "tmp_con_$r") or die "Cannot read conservation \n";
  my @prev_line;
  while (<CHV>) {
    chomp $_;
    my ($chr, $id, $start, $end, $type, $width, $length, $values) = split ("\t", $_);

    my $ref = $data{$id};

    if ($$ref[2]) { # plus strand
      my $diff = $start - $$ref[0];
      for (my $i = 0; $i < $diff; $i++) {
	$$ref[3] = $$ref[3].";$filler";
      }
      $$ref[3] = $$ref[3].";$values";
      $$ref[0] = $end+1;
    }
    else { # minus strand
      my $diff = $end - $$ref[1];
      for (my $i = 0; $i < $diff; $i++) {
	$$ref[3] = "$filler;".$$ref[3];
      }
      $$ref[3] = "$values;".$$ref[3];
      $$ref[1] = $start+1;
    }
  }
  close(CHV);

  # create output file
  open (OUTFILE, ">tmp_com_$r") or die "Cannot write conservation \n";
  foreach my $id (keys %data) {
    my $ref = $data{$id};
    if ($$ref[2] and $$ref[0] <= $$ref[1]) { # plus strand
      my $diff = $$ref[1] - $$ref[0] + 1;
      for (my $i = 0; $i < $diff; $i++) {
	$$ref[3] = $$ref[3].";$filler";
      }
    }
    elsif ((not $$ref[2]) and $$ref[0] >= $$ref[1]) { # minus strand
      my $diff = $$ref[0] - $$ref[1] + 1;
      for (my $i = 0; $i < $diff; $i++) {
	$$ref[3] = "$filler;".$$ref[3];
      }
    }

    if (substr($$ref[3], length($$ref[3])-1, 1) eq ";") {
      chop $$ref[3];
    }
    if (substr($$ref[3], 0, 1) eq ";") {
      $$ref[3] = substr($$ref[3], 1, length($$ref[3])-1);
    }

    print OUTFILE "$id\t$$ref[3]\n";
  }
  close(OUTFILE);
}

# ------------------------------------------------
#
# ------------------------------------------------
__DATA__

extract_features.pl


   Options:
     -t      Type (sequence, conservation ...)
     -f      Feature file (sequence stab, conservation chv ...)
     -e      Empty
     -n      Parameter number
     -l      Filler (for empty values)
     -debug  Keep temporary files, print debug messages
     
     -mp     Minus-plus -- use the mp flag with extact_sequence.pl so that strand information
             is correctly interpreted in case of segments of length 1 (start=end).

