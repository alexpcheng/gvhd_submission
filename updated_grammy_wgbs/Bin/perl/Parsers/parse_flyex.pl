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

my $header_str = get_arg("h", "<D-V coordinate>", \%args);

my $inside_gene = 0;
my $gene = "";
while(<$file_ref>)
{
    chop;

    if (/^[\#][\<]Gene[\>] [\<]Channel[\>]/)
    {
	$gene = <$file_ref>;
	chop $gene;
    }
    elsif (/^[\#][\<]Nucleus number[\>]/ and not(/$header_str/))
    {
	$inside_gene = 1;
    }
    elsif (length($_) == 0)
    {
	$inside_gene = 0;
    }
    elsif ($inside_gene == 1)
    {
	my @row = split(/\s/);
	print "$gene\t$row[0]\t$row[2]\n";
    }
}


__DATA__

parse_flyex.pl <file>

   Parse FlyEx (Reinitz lab) files

   -nh <str>: Header row must *not* contain <str> (default: <D-V coordinate>)

