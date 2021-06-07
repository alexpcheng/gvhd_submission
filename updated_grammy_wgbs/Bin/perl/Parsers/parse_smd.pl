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

my $smd_files_str = get_arg("f", "", \%args);
my $alias_files_str = get_arg("a", "", \%args);
my $gene_name_columns_str = get_arg("c", "", \%args);
my $data_column = get_arg("d", "", \%args);
my $min_regression_for_spot = get_arg("cor", 0.6, \%args);
my $min_signal_for_spot = get_arg("sig", 1.5, \%args);
my $append_suffix = get_arg("s", 0, \%args);

my @gene_name_columns = split(/\,/, $gene_name_columns_str);

my %name2id;
if ($alias_files_str != 1 and length($alias_files_str) > 0)
{
    my @alias_files = split(/\,/, $alias_files_str);
    for (my $i = 0; $i < @alias_files; $i++)
    {
	my $row_num = 0;
	open(ALIAS_FILE, "<$alias_files[$i]") or die "Could not open alias file $alias_files[$i]\n";
	print STDERR "Parsing alias file $alias_files[$i]\n";
	while(<ALIAS_FILE>)
	{
	    chop;
	    
	    my @row = split(/\t/);
	    
	    $name2id{$i}{$row[1]} = $row[0];
	    
	    if ($row_num % 10000 == 0) { print STDERR "."; }
	    $row_num++;
	    
	    #print STDERR "name2id{$i}{$row[1]} = $row[0]\n";
	}
	print STDERR "\n";
    }
}

my @smd_files = split(/\ /, $smd_files_str);
foreach my $smd_file (@smd_files)
{
    my $experiment_name;

    my %id2num_appearances;

    my $found_header = 0;
    my @header;
    my $CH1I_MEAN_COLUMN = -1;
    my $CH1B_MEAN_COLUMN = -1;
    my $CH2I_MEAN_COLUMN = -1;
    my $CH2B_MEAN_COLUMN = -1;
    my $REGRESSION_COLUMN = -1;
    my $LOG_RAT2N_MEAN_COLUMN = -1;
    open(SMD_FILE, "<$smd_file") or die "Could not open smd file $smd_file\n";
    print STDERR "Parsing smd file $smd_file...\n";
    while(<SMD_FILE>)
    {
	chop;

	my @row = split(/\t/);

	if (/^SPOT/i and $found_header == 0)
	{
	    $found_header = 1;
	    @header = split(/\t/);

	    for (my $i = 0; $i < @header; $i++)
	    {
		if    ($header[$i] eq "CH1I_MEAN" or $header[$i] eq "Ch1 Net (Mean)") { $CH1I_MEAN_COLUMN = $i; }
		elsif ($header[$i] eq "CH1B_MEAN" or $header[$i] eq "Channel 1 Background (Mean)") { $CH1B_MEAN_COLUMN = $i; }
		elsif ($header[$i] eq "CH2I_MEAN" or $header[$i] eq "Ch2 Net (Mean)") { $CH2I_MEAN_COLUMN = $i; }
		elsif ($header[$i] eq "CH2B_MEAN" or $header[$i] eq "Channel 2 Background (Mean)") { $CH2B_MEAN_COLUMN = $i; }
		elsif ($header[$i] eq "CORR" or $header[$i] eq "Regression Correlation") { $REGRESSION_COLUMN = $i; }
		elsif ($header[$i] eq "LOG_RAT2N_MEAN" or $header[$i] eq "Log(base2) of R/G Normalized Ratio (Mean)") { $LOG_RAT2N_MEAN_COLUMN = $i; }
	    }

	    if    ($CH1I_MEAN_COLUMN == -1)      { die "Could not find CH1I_MEAN_COLUMN\n"; }
	    elsif ($CH1B_MEAN_COLUMN == -1)      { die "Could not find CH1B_MEAN_COLUMN\n"; }
	    elsif ($CH2I_MEAN_COLUMN == -1)      { die "Could not find CH2I_MEAN_COLUMN\n"; }
	    elsif ($CH2B_MEAN_COLUMN == -1)      { die "Could not find CH2B_MEAN_COLUMN\n"; }
	    elsif ($REGRESSION_COLUMN == -1)     { die "Could not find REGRESSION_COLUMN\n"; }
	    elsif ($LOG_RAT2N_MEAN_COLUMN == -1) { die "Could not find LOG_RAT2N_MEAN_COLUMN\n"; }

	    print STDERR "CH1I_MEAN      = $CH1I_MEAN_COLUMN\n";
	    print STDERR "CH1B_MEAN      = $CH1B_MEAN_COLUMN\n";
	    print STDERR "CH2I_MEAN      = $CH2I_MEAN_COLUMN\n";
	    print STDERR "CH2B_MEAN      = $CH2B_MEAN_COLUMN\n";
	    print STDERR "REGR           = $REGRESSION_COLUMN\n";
	    print STDERR "LOG_RAT2N_MEAN = $LOG_RAT2N_MEAN_COLUMN\n";

	    $data_column = $LOG_RAT2N_MEAN_COLUMN;
	}
	elsif (/^[\!]Experiment Name=(.*)/)
	{
	    $experiment_name = $1;
	    $experiment_name =~ s/[\"]//g;
	}
	elsif (not(/^[\!]/) and length($row[$data_column]) > 0)
	{
	    my $done = 0;

	    if ($row[$REGRESSION_COLUMN] >= $min_regression_for_spot and
		(($row[$CH1B_MEAN_COLUMN] > 0 and
		  $row[$CH1I_MEAN_COLUMN] > 0 and
		  $row[$CH1I_MEAN_COLUMN] / $row[$CH1B_MEAN_COLUMN] >= $min_signal_for_spot) or 
		 ($row[$CH2B_MEAN_COLUMN] > 0 and
		  $row[$CH2I_MEAN_COLUMN] > 0 and
		  $row[$CH2I_MEAN_COLUMN] / $row[$CH2B_MEAN_COLUMN] >= $min_signal_for_spot)))
	    {
		for (my $i = 0; $i < @gene_name_columns and $done == 0; $i++)
		{
		    #print STDERR "Testing row[$gene_name_columns[$i]]=$row[$gene_name_columns[$i]]\n";
		    
		    my $id = $row[$gene_name_columns[$i]];
		
		    if (length($alias_files_str) > 0 and $alias_files_str != 1)
		    {
			$id = $name2id{$i}{$id};
		    }
		    
		    if (length($id) > 0)
		    {
			if ($append_suffix == 1)
			{
			    $id2num_appearances{$id}++;
			    
			    print "$id;;;$id2num_appearances{$id}\t$experiment_name\t$row[$data_column]\n";
			}
			else
			{
			    print "$id\t$experiment_name\t$row[$data_column]\n";
			}
			
			$done = 1;
		    }
		}
	    }
	}
    }
}

__DATA__

parse_smd.pl <file>

   Parse an smd file into a flat file

   -f <files>: File names separated by SPACES (not commas)
   -a <files>: Alias files separated by commas (stops upon finding the first match in the alias files list)
   -c <num>:   Column numbers to map to the alias files
   -d <num>:   Column for the data

   -cor <num>: Keep only spots where the correlation coefficient column is >= <num> (default: 0.6)
   -sig <num>: Keep only spots where the signal in channel 1 or 2 is >= <num> fold over the background (default: 1.5)
 
   -s:         If specified, append a unique suffix starting with ";;;" to each id added

