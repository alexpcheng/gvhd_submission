#!/usr/bin/perl

use strict;


require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lab/library_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $plate = get_arg("plate", "", \%args);
my $gel_info = get_arg("gel_info", "", \%args);
my $output_plate = get_arg("output_plate", "", \%args);

if (length($plate) == 0)
{
   die ("Please supply  -plate parameter\n");
}
if (length($gel_info) == 0)
{
   die ("Please supply  -gel_info parameter\n");
}

system ("dos2unix $gel_info >& /dev/null");
system ("dos2unix $plate >& /dev/null");

open (GEL, "<$gel_info") or die ("Failed to open gel info file: $gel_info\n");
open (PLATE, "<$plate") or die ("Failed to open plate file: $plate\n");
my $temp_plate = $output_plate ? $output_plate : "$plate.tmp_$$";

open (TEMP_PLATE, ">$temp_plate");

my %gel_info_hash;

my @row = split (/\t/, <GEL>);
chop $row[$#row];

if ($#row != 3 or $row[2] ne "Well" or $row[3] ne "Info")
{
    close GEL;
    close PLATE;
    close TEMP_PLATE;
    unlink $temp_plate;
    die ("Wrong gel info file format. Expecting column names: Gel Number, Band Size, Well, Info.\n");
} 

while (<GEL>)
{
    chop;
    @row = split (/\t/);

    $gel_info_hash{$row[2]} = $row[3];
}
close GEL;

my $line = <PLATE>;
@row = split (/\t/, $line);
print TEMP_PLATE $line;

my $comments_col = -1;
my $well_col = -1;
for (my $i = 0; $i <= $#row; $i++)
{
    if ($row[$i] eq "Comments")
    {
	$comments_col = $i
    }
    if ($row[$i] eq "Well")
    {
	$well_col = $i;
    }
}

if ($comments_col == -1 or $well_col == -1)
{
    close PLATE;
    close TEMP_PLATE;
    unlink $temp_plate;
    die ("Did not find the 'Comments' or the 'Well' columns in the plate file\n");
}

while (<PLATE>)
{
    chop;
    @row = split(/\t/);

    if ($gel_info_hash{$row[$well_col]})
    {
	$row[$comments_col] .= " GEL_INFO: " . $gel_info_hash{$row[$well_col]};
    }
    print TEMP_PLATE join("\t", @row) . "\n";
}

close PLATE;
close TEMP_PLATE;
#system ("mv $temp_plate $plate");


__DATA__

  update_gel_info.pl <parameters>

   Updates gels information in the comments field of a plate.

    -plate <str>       :   Plate file to update.

    -gel_info <str>    :   File name of the gel info file. Should have these columns: Gel Number, Band Size, Well, Info. 
                           The content of the info field will be appended to the comments field of the respective well in 
                           the plate file (After the string: " GEL_INFO: ").

    -output_plate <str>:   Output plate name (if not specified, will be someting like: <plate name>.tmp_##### )
