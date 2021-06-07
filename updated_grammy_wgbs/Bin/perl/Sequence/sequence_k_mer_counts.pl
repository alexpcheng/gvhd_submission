#!/usr/bin/perl

use strict;
use File::Path;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

my $pid = `hostname`;
chomp $pid;
$pid .= $$;

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
my $k_mer = get_arg("k", 10, \%args);
my $prefix_size = get_arg("p", 6, \%args);
my $create_dirs = get_arg("cd", 0, \%args);
my $dump_len = get_arg("dump", 1500000, \%args);
my $rc = get_arg("rc", 0, \%args);

my $actual_kmer = $k_mer - $prefix_size;

if ($create_dirs == 1)
{
	my @dirs = ();
	
	for (my $i = 0; $i < 4**($prefix_size); $i++)
	{
		my $pref = &int2seq ($i, $prefix_size);
		push (@dirs, substr ($pref, 0, 3) . "/" . substr ($pref, 3, 3) . "/");
	}

	mkpath (\@dirs, 1, 0777);
	
	exit;
}

my %prefix = ();
my $total_len = 0;

while (<$file_ref>)
{
	chomp;
	
	my ($id, $sequence) = split("\t");
	print STDERR "Processing $id ... ";

	my $seq_len = length ($sequence) - $k_mer;
	$total_len += $seq_len;
	
	for (my $i=0; $i < $seq_len; $i++)
	{
		my $pre  = substr ($sequence, $i, $prefix_size);
		my $post = substr ($sequence, $i + $prefix_size, $actual_kmer);
		
#		$prefix{$pre} .= &seq2int ($post) . "\n"; 
		$prefix{$pre} .= $post . "\n"; 

		if ($rc)
		{
			my $rc_sequence = &ReverseComplement($sequence);
			my $rc_pre  = substr ($rc_sequence, $i, $prefix_size);
			my $rc_post = substr ($rc_sequence, $i + $prefix_size, $actual_kmer);
			
	#		$prefix{$rc_pre} .= &seq2int ($rc_post) . "\n"; 
			$prefix{$rc_pre} .= $rc_post . "\n"; 
		}
	}

	if ($total_len > $dump_len)
	{
		print STDERR "Writing " . keys(%prefix) . " files... ";
		
		foreach my $cur_pre (keys %prefix)
		{
			# Write to file
			open (MYOUTFILE, ">>" . substr ($cur_pre, 0, 3) . "/" . substr ($cur_pre, 3, 3) . "/data.tab_" . $pid);
			print MYOUTFILE $prefix{$cur_pre};
			close (MYOUTFILE);
		}
	
		
		%prefix = ();
		$total_len = 0;
	}
	
	print STDERR "   OK.\n";

}	

print STDERR "Writing " . keys(%prefix) . " files... ";

foreach my $cur_pre (keys %prefix)
{
	# Write to file
	open (MYOUTFILE, ">>" . substr ($cur_pre, 0, 3) . "/" . substr ($cur_pre, 3, 3) . "/data.tab_" . $pid);
	print MYOUTFILE $prefix{$cur_pre};
	close (MYOUTFILE);
}

print STDERR "   OK.\n";


################################
sub seq2int {

	my ($seq) = @_;
	my $int = 0;
	
	$seq =~ tr /ATGC/0123/;
	
	
	for (my $i=length ($seq); $i > 0; $i--)
	{
		$int = $int * 4 + substr ($seq, $i-1, 1);
	}
	
	return $int;
}

################################
sub int2seq {

	my ($int, $len) = @_;
	my $seq = "";
	
	for (my $i=0; $i < $len; $i++)
	{
		$seq = ($int % 4) . $seq;
		$int = int ($int / 4);
	}
	
	$seq =~ tr /0123/ATGC/;
	return $seq;
}


__DATA__

sequence_k_mer_counts.pl


