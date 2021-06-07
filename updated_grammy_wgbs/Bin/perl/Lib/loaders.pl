#!/usr/bin/perl

#---------------------------------------------------------
# LoadHash
#---------------------------------------------------------
sub LoadHash
{
    my ($file_name, $key_column, $value_column, $max_columns) = @_;

    my %res;

    open(INFILE, "<$file_name") or print STDERR "LoadHash could not open file $file_name\n";
    while(<INFILE>)
    {
	chop;

	my @row = split(/\t/);
	if (length($max_columns) == 0)
	{
	    @row = split(/\t/);
	}
	else
	{
	    @row = split(/\t/, $_, $max_columns);
	}

	$res{$row[$key_column]} = $row[$value_column];
    }

  return %res;
}

1
