#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAHYBRID_EXE_DIR = "$ENV{GENIE_HOME}/Bin/RNAHybrid/RNAhybrid-2.1/src";

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

my $targetfile = get_arg("t", "", \%args);
my $print_structure = get_arg("ps", 0, \%args);
my $ecutoff = "-" . get_arg("e", 20, \%args);
my $utrparams = get_arg("s", "3utr_fly", \%args);
my $fasta = get_arg("fasta", 0, \%args);
my $query_file = get_arg("q", "", \%args);

my $echoed_args = 	echo_arg("b", \%args) . 
					echo_arg("d", \%args) . 
					echo_arg("f", \%args) . 
					echo_arg("u", \%args) . 
					echo_arg("v", \%args) . 
					echo_arg("p", \%args);

my %query_ids;
my $name;
my $seq;
my $query_id;

my $target_id;
my $target_seq;
my @prog_result;
my @result;
my $nresults;
my $resultline;

if ($fasta) 
{
	print STDERR "Hybridizing across fasta files. May take a while... ";
		
	system ("$RNAHYBRID_EXE_DIR/RNAhybrid -m 100000 -c -e $ecutoff -s $utrparams $echoed_args -t $targetfile -q $query_file > tmp_hybrid");

	open(FILE, "tmp_hybrid");
	while (<FILE>)
	{
		chop;	
		@result = split (/:/);
		print "$result[0]\t$result[2]\t$result[4]\t$result[5]\t$result[6]";
		if ($print_structure == 1) {
		
			print "\t$result[7]\t$result[8]\t$result[9]\t$result[10]";
		
			# Print size of binding site
			
			my $count1;
			my $count2;
			
			$_ = $result[7]; $count1 = tr/A-Z//;
			$_ = $result[8]; $count2 = tr/A-Z//;
			
			my $totalcount = $count1 + $count2;
			
			while (chop ($result[9]) eq ' ')
			{
				if (chop ($result[10]) eq ' ')
				{
					$totalcount--;
				}
			}
			
			print "\t$totalcount";
		}
		
		print "\n";
	}
	
	system("rm tmp_hybrid");
	
	exit;
}	

# Read query sequences
while(<$file_ref>)
{
  chop;
  if(/\S/)
  {
    ($name,$seq) = split("\t");
    $query_ids{$name} = $seq;
  }
}

# Step through target sequences and call RNAHybrid for each pair of query - target

open(FILE, $targetfile) or die("Could not open target sequences file '$file'.\n");
$file_ref = \*FILE;

while (<$file_ref>)
{
	chop;
	if(/\S/)
	{
		($target_id,$target_seq) = split("\t");	

		foreach $query_id (keys %query_ids)
		{
			print STDERR "Hybridizing $target_id with $query_id: ";

			@prog_result = split (/\n/, `$RNAHYBRID_EXE_DIR/RNAhybrid -c -e $ecutoff -s $utrparams $echoed_args $target_seq $query_ids{$query_id}`);
			
			$nresults = @prog_result;
			print STDERR "$nresults results.\n";
			
			foreach $resultline (@prog_result)
			{
				@result = split (/:/, $resultline);
				print "$target_id\t$query_id\t$result[4]\t$result[5]\t$result[6]";
				if ($print_structure == 1) {
				
					print "\t$result[7]\t$result[8]\t$result[9]\t$result[10]";
				
					# Print size of binding site
					
					my $count1;
					my $count2;
					
					$_ = $result[7]; $count1 = tr/A-Z//;
					$_ = $result[8]; $count2 = tr/A-Z//;
					
					my $totalcount = $count1 + $count2;

					while (chop ($result[9]) eq ' ')
					{
						if (chop ($result[10]) eq ' ')
						{
							$totalcount--;
						}
					}					

					print "\t$totalcount";
				}
				
				print "\n";
			}
		}
	}
}

__DATA__

rnahybrid.pl <query file> [options]

	Find the minimum free energy hybridisation of a long (target) and a
	short (query) RNA. Both query and target sequence files are stab files.
	
	The result is a tab delimited file containing the target ID, query ID,
	mfe, p-value and position of begining of alignment on target.
	
	In case the -ps option is given, the structure is printed in four lines
	(top two lines represent the target, bottom the query) plus the length
	of the target binding site.

	options:
	
	  -t <target file>
	  -ps	add four columns to each line describing the hybridization structure.
	  -b <number of hits per target>
	  -d <xi>,<theta>
	  -f helix constraint
	  -u <max internal loop size (per side)>
	  -v <max bulge loop size>
	  -e <energy cut-off>
	  -p <p-value cut-off>
	  -s (3utr_fly|3utr_worm|3utr_human)


