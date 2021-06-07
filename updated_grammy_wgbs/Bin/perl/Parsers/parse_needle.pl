#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
    print STDOUT <DATA>;
    exit;
}

my $file_ref;
my $file = $ARGV[0];

open(FILE, $file) or die("Could not open file '$file'.\n");
$file_ref = \*FILE;

my %args = load_args(\@ARGV);

my $output_file = get_arg("o", "", \%args);
my $append =  get_arg("ap", 0, \%args);
my $print_termination = get_arg("tl", 1, \%args);
my $print_chroutput = get_arg("chroutput", 0, \%args);

if ($append)
{
    open(OUT, ">>$output_file") or die ("Could not open file $output_file\n");
}
else
{
    open(OUT, ">$output_file") or die ("Could not open output file $output_file\n");
}
my $TERMINATOR = "======================================================================================";
my $seq1 = "";
my $seq2 = "";
my $seq1_name = "";
my $seq2_name = "";
my $alignment_started = 0;
my $seq1_name_short = "";
my $seq2_name_short = "";
my $short_name_length = 13;

while (<$file_ref>)
{
	chomp;
  if ($_ =~m/\=+ ([\w\.\-]+),([\w\.\-]+):/)
  {
		if ($alignment_started)
		{
			if ($print_chroutput)
			{
				&PrintChrOutput($seq1_name, $seq1, $seq2_name, $seq2);
			}
			else
			{
		    print OUT "$seq1_name\t$seq1\n";
		    print OUT "$seq2_name\t$seq2\n";
	  	  if ($print_termination)
	    	{
					print OUT "$TERMINATOR\n";
	    	}
	   	}
		}
		$seq1_name = $1;
		$seq2_name = $2;
		$seq1 = "";
		$seq2 = "";
		$alignment_started = 1;
		$seq1_name_short = substr($seq1_name, 0, $short_name_length);
		$seq2_name_short = substr($seq2_name, 0, $short_name_length);
  }
  elsif ($_ =~m/^$seq1_name_short *[0-9]+ *([\w-]+) *[0-9]+/)
  {
		$seq1 = $seq1.$1;
  }
  elsif ($_ =~m/^$seq2_name_short *[0-9]+ *([\w-]+) *[0-9]+/)
  {
		$seq2 = $seq2.$1;
  }    
}

if ($alignment_started)
{
	if ($print_chroutput)
	{
		&PrintChrOutput($seq1_name, $seq1, $seq2_name, $seq2);
	}
	else
	{
	  print OUT "$seq1_name\t$seq1\n";
  	print OUT "$seq2_name\t$seq2\n";
	  if ($print_termination)
  	{
			print OUT "$TERMINATOR\n";
	  }
	}
}

sub PrintChrOutput
{
	my ($seq1_name, $seq1, $seq2_name, $seq2) = @_;

	#print OUT "$seq1_name\t$seq1\n";
 	#print OUT "$seq2_name\t$seq2\n";

	my $current_type1 = "";
	my $current_start1 = 1;
	my $current_end1 = 0;

	my $current_type2 = "";
	my $current_start2 = 1;
	my $current_end2 = 0;

	my $seq_length = length($seq1);
	for (my $i = 0; $i < $seq_length; $i++)
	{
		my $s1 = substr($seq1, $i, 1);
		my $s2 = substr($seq2, $i, 1);

		my $type1 = $s1 eq $s2 ? "M" : ($s1 eq "-" ? "D" : ($s2 eq "-" ? "I" : "m"));
		my $type2 = $s1 eq $s2 ? "M" : ($s2 eq "-" ? "D" : ($s1 eq "-" ? "I" : "m"));

		$type1 .= $s1 eq "-" ? $s2 : $s1;
		$type2 .= $s2 eq "-" ? $s1 : $s2;

		if (length($current_type1) == 0 || $current_type1 eq $type1)
		{
			$current_end1++;
		}
		else
		{
			print OUT "$seq1_name\t$seq1_name $current_start1\t$current_start1\t$current_end1\t" . substr($current_type1, 0, 1) . "\t" . &Char2Value(substr($current_type1, 1, 1)) . "\n";

			$current_start1 = $i + 1;
			$current_end1 = $i + 1;
		}

		if (length($current_type2) == 0 || $current_type2 eq $type2)
		{
			$current_end2++;
		}
		else
		{
			print OUT "$seq2_name\t$seq2_name $current_start2\t$current_start2\t$current_end2\t" . substr($current_type2, 0, 1) . "\t" . &Char2Value(substr($current_type2, 1, 1)) . "\n";

			$current_start2 = $i + 1;
			$current_end2 = $i + 1;
		}

		$current_type1 = $type1;
		$current_type2 = $type2;
	}

	if (length($current_type1) > 0)
	{
		print OUT "$seq1_name\t$seq1_name $current_start1\t$current_start1\t$current_end1\t" . substr($current_type1, 0, 1) . "\t" . &Char2Value(substr($current_type1, 1, 1)) . "\n";
	}

	if (length($current_type2) > 0)
	{
		print OUT "$seq2_name\t$seq2_name $current_start2\t$current_start2\t$current_end2\t" . substr($current_type2, 0, 1) . "\t" . &Char2Value(substr($current_type2, 1, 1)) . "\n";
	}

}

sub Char2Value
{
	my ($seq) = @_;

	return $seq eq "-" ? 0 : ($seq eq "A" ? 1 : ($seq eq "C" ? 2 : ($seq eq "G" ? 3 : 4)));
}

__DATA__
    
    parse_needle.pl <file>
    
    Takes in a needle global alignment output file and creates a parsed file of the format:

    seq1 aligned seq
    seq2 aligned seq
    =================
    
    -o <string>: output file name
    -chroutput:  Print the result in chr format
    
    -ap <bool>:  append to output file (default: false)

    -tl <bool>:  print terminating line (===) (default: true)

