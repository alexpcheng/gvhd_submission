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

my $start_entity = get_arg("s", "FT", \%args);
my @tags = get_extended_arg("f", \%args);
my @tags_start_sequences = get_extended_arg("fs", \%args);

my %tags_to_start_sequences;
for (my $i = 0; $i < @tags; $i++)
{
    if (length($tags_start_sequences[$i]) > 0)
    {
	$tags_to_start_sequences{$tags[$i]} = $tags_start_sequences[$i];
	#print STDERR "tags_to_start_sequences{$tags[$i]} = $tags_start_sequences[$i]\n";
    }
}

&PrintHeader();

my $feature_name;
my $feature_start;
my $feature_end;
my %tag_values;
my $current_tag;
my $current_region;
while(<$file_ref>)
{
    chop;

    if (/${start_entity}   ([^ ]+)[ ]+(.*)/)
    {
	&PrintEntity();

	/${start_entity}   ([^ ]+)[ ]+(.*)/;
	$feature_name = $1;
	$current_region = $2;

	$current_tag = "START_FEATURE";
    }
    elsif (/${start_entity}[ ]+[\/]([^\=]+)[\=](.*)/)
    {
	$current_tag = $1;
	my $tag_value = $2;
	$tag_value =~ s/\"//g;

	my $required_start_sequence = $tags_to_start_sequences{$current_tag};

	#print STDERR "DISSECTING: $_\n";
	#print STDERR "[$current_tag] = [$tag_value]\n";
	#print STDERR "required start = [$required_start_sequence]\n";

	if (length($required_start_sequence) == 0 or $tag_value =~ /^$required_start_sequence/)
	{
	    if (length($tag_values{$current_tag}) > 0) { $tag_values{$current_tag} .= ";;;"; }
	    $tag_values{$current_tag} .= $tag_value;
	}
    }
    elsif (/${start_entity}[ ]+([^ ]+.*)/)
    {
	my $tag_value = $1;

	if ($tag_value =~ /^[^\/]/)
	{
	    $tag_value =~ s/\"//g;

	    #print STDERR "DISSECTING: $_\n";

	    if ($current_tag eq "START_FEATURE")
	    {
		$current_region .= "$tag_value";

		#print STDERR "REGION: $current_region\n";
	    }
	    else
	    {
		if (length($tags_to_start_sequences{$current_tag}) == 0 or $tag_value =~ /^$tags_to_start_sequences{$current_tag}/)
		{
		    $tag_values{$current_tag} .= ";;;$tag_value";

		    #print STDERR "[$current_tag] = [$tag_value]\n";
		}
	    }
	}
    }
}

&PrintEntity();

sub ParseCurrentRegion
{
    my $complement = 0;
    if ($current_region =~ /^complement[\(](.*)[\)]$/)
    {
	$current_region = $1;
	$complement = 1;

	#print STDERR "COMPLEMENT: $_\n";
	#print STDERR "REGION: $current_region\n";
    }

    my $start_region;
    my $end_region;

    if ($current_region =~ /^join[\(](.*)[\)]$/)
    {
	my @row = split(/\,/, $1);

	$start_region = $row[0];
	$end_region = $row[@row - 1];

	#print STDERR "JOIN: $current_region\n";
	#print STDERR "START: $start_region\n";
	#print STDERR "END: $end_region\n";
    }
    else
    {
	$start_region = $current_region;
	$end_region = $current_region;
    }
    
    $start_region =~ /([0-9]+)[\.][\.]/;
    $feature_start = $1;

    $end_region =~ /[\.][\.]([0-9]+)/;
    $feature_end = $1;

    if ($complement == 1)
    {
	my $tmp = $feature_start;
	$feature_start = $feature_end;
	$feature_end = $tmp;
    }
}

sub PrintHeader
{
    print "Feature\tStart\tEnd";

    foreach my $tag (@tags)
    {
	print "\t$tag";
    }
	
    print "\n";
}

sub PrintEntity
{
    if (length($feature_name) > 0)
    {
	&ParseCurrentRegion();

	print "$feature_name\t$feature_start\t$feature_end";

	foreach my $tag (@tags)
	{
	    print "\t$tag_values{$tag}";
	}
	
	print "\n";
    }
    
    $feature_name = "";
    $feature_start = "";
    $feature_end = "";
    $current_region = "";
    %tag_values = ();
}


__DATA__

parse_embl.pl <file>

   Parses a sequence file (e.g., .contig files)

   -s <str>:   The string used to identify the beginning of an entity (default: 'FT')

   -f1 <str>:  First feature name to extract (e.g., 'gene')
   -f2 <str>:  Second feature name to extract (can have multiple ones)

   -fs1 <str>: Feature 1 must start with the sequence <str> (optional, e.g., 'LocusLink')
   -fs2 <str>: Feature 1 must start with the sequence <str> (optional, e.g., 'LocusLink')

