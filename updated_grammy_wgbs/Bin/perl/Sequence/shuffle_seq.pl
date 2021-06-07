#!/usr/bin/perl
use strict;

use List::Util qw[shuffle min max];

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $fix = get_arg("fix", "0", \%args);
my $fe = get_arg("fe", "", \%args);
my $fs = get_arg("fs", "", \%args);


while(<$file_ref>)
{
	chomp;
	my @row = split(/\t/);
	my $name = $row[0];
	my $seq  = $row[1];
	
	my @seq_let = split (undef, $seq);
	my @shuffled_let;
	my $shuffled = "";

	my $fix_start;
	my $fix_length;
	
	if ($fix or ($fe ne ""))
	{
		if ($fe eq "")
		{
			$fix_start = $row[2]-1;
			$fix_length = $row[3]-$row[2]+1;
		}
		else
		{
			$fix_start = $fs-1;
			if ($fe > 0)
			{
				$fix_length = $fe - $fs + 1;
			}
			else
			{
				$fix_length = length($seq) - $fs + 1;
			}
		}
		
		my @removed = splice (@seq_let, $fix_start, $fix_length);
		@shuffled_let = shuffle @seq_let;
		
		my @upstream_seq = splice (@shuffled_let, 0, $fix_start);
	
		$shuffled = join ("", @upstream_seq) . join ("", @removed) . join ("", @shuffled_let);	
	}
	else
	{
		@shuffled_let = shuffle @seq_let;
		$shuffled = join ("", @shuffled_let);
	}
	
	print "$name\t$shuffled\n";
}

exit(0);

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------

__DATA__

shuffle_seq.pl <file_name> 

     shuffle_seq.pl reads a stab file from stdin and shuffles the sequences randomly.

     -fix:    The third and forth column of the stab file are regarded as the start
              and end positions of the sequence which should be fixed (not shuffled).
              
     -fs
     -fe      The fix start and end position to be used for the whole stab file. Use -fe 0
              to fix everything from -fs to the end of the sequence.

