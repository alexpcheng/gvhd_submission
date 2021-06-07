#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $output_track_file = get_arg("o", "", \%args);
my $input_track_files = get_arg("f", "", \%args);

my $xml = get_arg("xml", 0, \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/merge_chromosome_tracks.map ";

$exec_str .= "input_track_files=$input_track_files ";
my @input_tracks = split(/\,/, $input_track_files);
my $num_input_track_files = @input_tracks;
$exec_str .= "num_input_track_files=$num_input_track_files ";

$exec_str .= "output_track_file=$tmp_clu ";

system("$exec_str > $tmp_xml");

#print "$exec_str\n";

if ($xml == 1)
{
  system("cat $tmp_xml");
}
else
{
  `$ENV{GENIE_EXE} $tmp_xml >& /dev/null`;
  system("cat $tmp_clu");
  `rm $tmp_clu`;
}

#system("genesets2tab.pl $tmp_clu");

`rm $tmp_xml`;

__DATA__

merge_gxts.pl 

    Creates a merged gxt from input gxts (e.g., merge hmm gxts)

    -o <name>:  Name of the output chromosome track
    -f <files>: Name of input track files, separated by commas

    -xml:      Print only the xml

