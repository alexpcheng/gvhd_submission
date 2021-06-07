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

my $insertion_character = get_arg("c", "-", \%args);
my $alignment_name = get_arg("n", "SimpleAlignment", \%args);
my $alignment_type = get_arg("at", "GaplessAlignment", \%args);
my $do_not_print_headers = get_arg("no_header", 0, \%args);

if ($do_not_print_headers == 0)
{
    print "<SequenceAlignment Name=\"$alignment_name\" Type=\"$alignment_type\">\n";
}

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    my $string_length = length($row[1]);
    my $alignment_start = 0;
    for ($alignment_start = 0; $alignment_start < $string_length; $alignment_start++)
    {
	if (substr($row[1], $alignment_start, 1) ne $insertion_character)
	{
	    last;
	}
    }

    print "<Sequence Name=\"$row[0]\" AlignmentStart=\"$alignment_start\" SequenceStart=\"0\" SequenceEnd=\"-1\">";
    print "</Sequence>\n";
}

if ($do_not_print_headers == 0)
{
    print "</SequenceAlignment>\n";
}

__DATA__

tab2alignment.pl <file>

   Takes in a stab sequence file and creates an alignment file out of it

   -c <str>:   Character that designates an insertion (default: '-')

   -at <str>:  Alignment type (GaplessAlignment/GappedAlignment) (default: GaplessAlignment)

   -n <str>:   Alignment name (default: SimpleAlignment)

   -no_header: Do not print the sequence alignment headers

