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
my $overwrite = get_arg("o", 0, \%args);
my $str_col_def = get_arg("s", "", \%args);
my $col_def_file = get_arg("f", "", \%args);

if (length($db_name) == 0)
{
   die "Error: Must supply database name (-db)";
}
if (length($table_name) == 0)
{
   die "Error: Must supply table name (-n)";
}

if (length($str_col_def) == 0 and length($col_def_file) == 0)
{
   die "Error: Columns definitions must be supplied (by either -s or -f parameters)";
}

my $col_def = "";
if (length($col_def_file) > 0)
{
   open (COL_DEF_FILE, "<${col_def_file}") or die "Error: Failed to open file: $col_def_file";
   while (<COL_DEF_FILE>)
   {
      $col_def .= $_;
   }
   close COL_DEF_FILE;
}
else
{
   $col_def = $str_col_def;
}

my $dbh = DBI->connect("DBI:mysql:${db_name}", $user, $password);
if (not $dbh)
{
   die ("Error: The connection attempt failed:\n".$DBI::errstr);
}


my $create_cmd = "create table " . ($overwrite == 1 ? "" : "if not exists ") . $table_name . "( " . $col_def . " );";

$dbh->do($create_cmd) or die ("Error: Failed to create new table:\n".$DBI::errstr);


__DATA__

delete_all_table.pl <parameters>

   Deletes all the tables in the specified database.

   -db <str>:    Database name

   -n <str>:     Table name

   -s <str>:     Columns definitions in mysql format.
   -f <str>:     File name containing the columns definitions (if specified, -s is ignored and may not be specified)

   -o:           Overwrite existing table with the same name if exists (default: do not overwrite).

   -u <str>:     mysql user name (default: mysql)
   -p <str>:     mysql user password (default: undef)
