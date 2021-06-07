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

my $plate_layout_file = get_arg("layout", "", \%args);

my %id2name;

open(PLATE_LAYOUT, "<$plate_layout_file") or die "Could not find plate layout file $plate_layout_file\n";
while(<PLATE_LAYOUT>)
{
  chomp;

  my @row = split(/\t/);

	$id2name{$row[0]} = "$row[1]__$row[2]__$row[3]";
}

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

	&Replace($row[0]);
	print "\t";
	&Replace($row[1]);
	print "\n";
}

sub Replace
{
	my ($str) = @_;
	
	my @row = split(/\,/, $str);
	
	for (my $i = 0; $i < @row; $i++)
	{
		if ($i > 0) { print ","; }

		my $name = $id2name{$row[$i]};

		if (length($name) > 0)
		{
			print $name;
		}
		else
		{
			print $row[$i];
		}
	}
}

__DATA__

well_ids2well_names.pl <file>

   Converts well ids given in a file into their well names given in a plate layout file

   -layout <str>:                    Plate layout file

