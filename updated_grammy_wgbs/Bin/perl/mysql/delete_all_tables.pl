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


if (length($db_name) == 0)
{
   die "Error: Must supply database name (-db)";
}

my $dbh = DBI->connect("DBI:mysql:${db_name}", $user, $password);
if (not $dbh)
{
   die ("Error: The connection attempt failed:\n".$DBI::errstr);
}

my @tables = $dbh->tables();
foreach (@tables) {
     $dbh->do("DROP TABLE IF EXISTS $_") or die "Error: Failed to drop table $_:\n".$DBI::errstr;
}

__DATA__

delete_all_table.pl <parameters>

   Deletes all the tables in the specified database.

   -db <str>:    Database name

   -u <str>:     mysql user name (default: mysql)
   -p <str>:     mysql user password (default: undef)
