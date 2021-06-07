#!/usr/bin/perl

use strict;
use DBI;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $user = get_arg ("u", "mysql", \%args);
my $password = get_arg("p", undef, \%args);
my $db_name = get_arg("db", "", \%args);
my $table_name = get_arg("n", "", \%args);
my $file_name = get_arg("f", "", \%args);

if (length($db_name) == 0)
{
   die "Error: Must supply database name (-db)";
}
if (length($table_name) == 0)
{
   die "Error: Must supply table name (-n)";
}

if (length($file_name) == 0)
{
   die "Error: Must supply input file name (-f)";
}

if (not -e $file_name)
{
   die "Error: Input file not found ($file_name)";
}

my $dbh = DBI->connect("DBI:mysql:${db_name}", $user, $password);
if (not $dbh)
{
   die ("Error: The connection attempt failed:\n".$DBI::errstr);
}

$dbh->do("LOAD DATA LOCAL INFILE '$file_name' INTO TABLE $table_name;") or die ("Error: Failed to load file\n".$DBI::errstr); 


__DATA__

populate_table.pl <parameters>

   Reads data from a file and uploads it to the specified mysql table.

   -db <str>:    Database name

   -n <str>:     Table name

   -f <str>:     Full path of input file name (with columns corresponding to the mysql table columns)

   -u <str>:     mysql user name (default: mysql)
   -p <str>:     mysql user password (default: undef)
