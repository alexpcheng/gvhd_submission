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

my $add_gsm_to_experiment_name = get_arg("GSM", 0, \%args);
my $sample_alias_file = get_arg("alias", "", \%args);

my $dye_swap = get_arg("dye_swap", 0, \%args);
my $ch1_header = get_arg("ch1_header", "", \%args);
my $ch1_bkd_header = get_arg("ch1_bkd_header", "", \%args);
my $ch2_header = get_arg("ch2_header", "", \%args);
my $ch2_bkd_header = get_arg("ch2_bkd_header", "", \%args);
my $ref_str = get_arg("ref_str", "", \%args);
my $spot_null_file = get_arg("spot_null_file", "", \%args);

if ( $dye_swap ) {
  die "ERROR - ch1_header not given.\n" if ( $ch1_header eq "" );
  die "ERROR - ch1_bkd_header not given.\n" if ( $ch1_bkd_header eq "" );
  die "ERROR - ch2_header not given.\n" if ( $ch2_header eq "" );
  die "ERROR - ch2_bkd_header not given.\n" if ( $ch2_bkd_header eq "" );
  die "ERROR - ref_str not given.\n" if ( $ref_str eq "" );
  die "ERROR - spot_null_file not given.\n" if ( $spot_null_file eq "" );
}



my %sample_aliases;
if (length($sample_alias_file) > 0)
{
    open(ALIAS_FILE, "<$sample_alias_file") or die "Could not open sample alias file $sample_alias_file\n";
    while(<ALIAS_FILE>)
    {
	chop;

	my @row = split(/\t/);

	for (my $i = 0; $i < @row; $i++)
	{
	    $sample_aliases{$row[$i]} = $row[0];
	}
    }
    close ALIAS_FILE;
}


my $inside_gsm = 0;
my $current_gsm = "";
my $value_column = "";
my $channel_1_column = "";
my $channel_1_background_column = "";
my $channel_2_column = "";
my $channel_2_background_column = "";
my @ref_channel_vec;

my %data;
my %data_channel_1;
my %data_channel_2;
my %channel_1_null_indicators;
my %channel_2_null_indicators;
my %id_refs;
my @id_refs_vec;
my %sample_ids;
my @sample_ids_vec;
my %sample_ids2names;
my %sample_names2ids;
my %exclude_ids;
my $current_platform = "";
while (<$file_ref>)
{
    chop;

    if (/^\^sample = (GSM[0-9]+)/i)
    {
	$inside_gsm = 0;
	$current_gsm = $1;
	
	if (length($sample_ids{$current_gsm}) == 0)
	{
	    $sample_ids{$current_gsm} = "1";
	    push(@sample_ids_vec, $current_gsm);
	}
    }
    elsif (/^\!Sample_platform_id = (.*)/i)
    {
      $current_platform = $1;
    }
    elsif (/^\!Sample_title = (.*)/i)
    {
	my $sample_name = $1;

	if (length($sample_aliases{$sample_name}) > 0)
	{
	    $sample_name = $sample_aliases{$sample_name};

	    if (length($sample_names2ids{$sample_name}) > 0)
	    {
		$exclude_ids{$current_gsm} = "1";
		$current_gsm = $sample_names2ids{$sample_name};
	    }
	    else
	    {
		$sample_ids2names{$current_gsm} = $sample_name;
		$sample_names2ids{$sample_name} = $current_gsm;
	    }
	}
	else
	{
	    $sample_ids2names{$current_gsm} = $sample_name;
	}
    }
    elsif ( /^\!Sample_channel_count = (.*)/i )
    {
      if ( $dye_swap and $1 != 2 ) { die "ERROR - Sample_channel_count not equal 2 in a dye-swap experiment.\n"; }
    }
    elsif ( /^\!Sample_characteristics_ch1 = (.*)/i )
    {
      if ( $1 =~ $ref_str ) { push(@ref_channel_vec, 1); }
      else { push(@ref_channel_vec, 2); }
    }
    elsif (/^ID_REF	/ and /VALUE/i)
    {
	$inside_gsm = 1;
	
	my @row = split(/\t/);
	
	for (my $i = 0; $i < @row; $i++)
	{
	  if ($row[$i] eq "VALUE")
	  {
	    $value_column = $i;
	  }
	  elsif ( $dye_swap )
	  {
	    if ($row[$i] eq $ch1_header) { $channel_1_column = $i; }
	    if ($row[$i] eq $ch1_bkd_header) { $channel_1_background_column = $i; }
	    if ($row[$i] eq $ch2_header) { $channel_2_column = $i; }
	    if ($row[$i] eq $ch2_bkd_header) { $channel_2_background_column = $i; }
	  }
	}
    }
    elsif ($inside_gsm == 1)
    {
	my @row = split(/\t/);
	
        my $key = "$row[0]___$current_platform";

	if ( $dye_swap )
	{
	  if ( $ch1_bkd_header eq "NULL" ) { $data_channel_1{$key}{"$current_gsm"} = $row[$channel_1_column]; }
	  else { $data_channel_1{$key}{"$current_gsm"} = $row[$channel_1_column] - $row[$channel_1_background_column]; }

	  if ( $ch2_bkd_header eq "NULL" ) { $data_channel_2{$key}{"$current_gsm"} = $row[$channel_2_column]; }
	  else { $data_channel_2{$key}{"$current_gsm"} = $row[$channel_2_column] - $row[$channel_2_background_column]; }

	  if ( $row[$value_column] eq "NULL" )
	  {
	    $channel_1_null_indicators{$key}{"$current_gsm"} = 1;
	    $channel_2_null_indicators{$key}{"$current_gsm"} = 1;
	  }
	  else
	  {
	    $channel_1_null_indicators{$key}{"$current_gsm"} = 0;
	    $channel_2_null_indicators{$key}{"$current_gsm"} = 0;
	  }
	}
	else
	{
	  $data{$key}{"$current_gsm"} = $row[$value_column];
	}
	
	if (length($id_refs{$key}) == 0)
	{
	    $id_refs{$key} = "1";
	    push(@id_refs_vec, $key);
	}
    }
}

die " ERROR - lengths of sample_ids_vec and ref_channel_vec not equal.\n" if ( $dye_swap and @sample_ids_vec != @ref_channel_vec );

my $null_indicators_file_ref;
if ( $dye_swap )
{
  open(NULL_INDICATORS_FILE, ">$spot_null_file") or die "Could not open spot_null_file $spot_null_file\n";
  $null_indicators_file_ref = \*NULL_INDICATORS_FILE;
}

print "ID_REF";
if ( $dye_swap ) { print $null_indicators_file_ref "ID_REF"; }

for ( my $i=0 ; $i < @sample_ids_vec ; $i++ )
{
  my $sample_id = $sample_ids_vec[$i];

  if (length($exclude_ids{$sample_id}) == 0)
  {
    print "\t";
    
    if ( $dye_swap )
    {
      print $null_indicators_file_ref "\t";

      if ($add_gsm_to_experiment_name) { 
	print "$sample_id: "; 
	print $null_indicators_file_ref "$sample_id: ";
      }
      print $sample_ids2names{$sample_id};
      print $null_indicators_file_ref $sample_ids2names{$sample_id};

      if ( $ref_channel_vec[$i] == 1 ) {
	print "_REF";
	print $null_indicators_file_ref "_REF";
      }

      if ($add_gsm_to_experiment_name) {
	print "$sample_id: ";
	print $null_indicators_file_ref "$sample_id: ";
      }
      print "\t" . $sample_ids2names{$sample_id};
      print $null_indicators_file_ref "\t" . $sample_ids2names{$sample_id};

      if ( $ref_channel_vec[$i] == 2 ) {
	print "_REF";
	print $null_indicators_file_ref "_REF";
      }
    }
    else
    {
      if ($add_gsm_to_experiment_name) { print "$sample_id: "; }
      print $sample_ids2names{$sample_id};
    }
  }
}
print "\n";
if ( $dye_swap ) { print $null_indicators_file_ref "\n"; }

foreach my $id_ref (@id_refs_vec)
{
  print "$id_ref";
  if ( $dye_swap ) { print $null_indicators_file_ref "$id_ref"; }

  foreach my $sample_id (@sample_ids_vec)
  {
    if (length($exclude_ids{$sample_id}) == 0)
    {
      if ( $dye_swap )
      {
	print "\t" . $data_channel_1{"$id_ref"}{"$sample_id"};
	print "\t" . $data_channel_2{"$id_ref"}{"$sample_id"};

	print $null_indicators_file_ref "\t" . $channel_1_null_indicators{"$id_ref"}{"$sample_id"};
	print $null_indicators_file_ref "\t" . $channel_2_null_indicators{"$id_ref"}{"$sample_id"};
      }
      else
      {
	print "\t" . $data{"$id_ref"}{"$sample_id"};
      }
    }
  }

  print "\n";
  if ( $dye_swap ) { print $null_indicators_file_ref "\n"; }
}

if ( $dye_swap ) { close $null_indicators_file_ref; }


__DATA__

    parse_gse.pl <source file>

    Parse a GSE file and extract it as a tab-delimited file

    -GSM:         Add the GSM identifier to each experiment name

    -alias <str>: Alias file for samples in the format <name1><tab><name2><tab><name3>...
                  Each sample with the name <name2> or <name3> will be converted into <name1>.
                  Useful for cases where we need to merge 'A' and 'B' arrays.


    -dye_swap:             Get raw data of a dye-swap experiment. In stead of getting a single value column
                           per sample, get two value columns, one per channel.
                           If set, then all of the following six MUST be set as well
                           (this forces you to make sure you know what you are doing...):

    -ch1_header <str>:     The header given for the channel1 data.
    -ch1_bkd_header <str>: The header given for the channel1 background signal.
                           If GSE file does not specify this, then input NULL as the header name.
                           If is given, the background value will be subtracted from the main signal value.
    -ch2_header <str>:     The header given for the channel2 data.
    -ch2_bkd_header <str>: The header given for the channel2 background signal.
                           If GSE file does not specify this, then input NULL as the header name.
                           If is given, the background value will be subtracted from the main signal value.
    -ref_str <str>:        In the GSE file, for each GSM sample there is a Sample_characteristics_ch1 field
                           that contains a description of the channel 1 data. In the two channels case,
                           there is also a Sample_characteristics_ch2 field. For each sample, one of the
                           two is expected to state that it is the reference, such that it contains a string
                           that the other one does not, and this string can be used to distinguish the reference
                           in any GSM sample in the GSE file.
                           Example: !Sample_characteristics_ch1 = parent strain BY4716
                                    !Sample_characteristics_ch2 = reference pool of BY4716 strain
                           In this example, the string 'reference' can be chosen as the ref_str.
    -spot_null_file <str>: Name of tab file, that is identical in structure to the main output, but the values 
                           that it contains are binary 0/1 flags, with 1 indicating a NULL value.
                           Reason: if you need to process the raw data, even if certain spots were deemed NULL,
                           you may require also their raw intensity values (if the processing is done by a tool
			   that accepts no NULL values). Then, you can cross the post-processed values with the
                           NULL flags, and remove values in spots that corresponded to NULLs.

