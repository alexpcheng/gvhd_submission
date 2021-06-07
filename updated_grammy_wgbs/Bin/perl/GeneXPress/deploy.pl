#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $archive = get_arg("a", "Genomica.zip", \%args);
my $copy_archive = get_arg("c", 0, \%args);

my $exec_str = "cd $ENV{HOME}/develop/Genomica/release/; ";

$exec_str .= "rm -f $archive; ";

$exec_str .= "zip $archive ";
$exec_str .= "icons/* ";
$exec_str .= "*.bat ";
$exec_str .= "*.sh ";
$exec_str .= "Samples/*.tab ";
$exec_str .= "Samples/*.gxa ";
$exec_str .= "Samples/*.gxp ";
$exec_str .= "Genomica.jar; ";

if ($copy_archive == 1)
{
    $exec_str .= "cp $archive $ENV{WWW_HOME}/genomica/Download; ";
    $exec_str .= "scp $archive genie\@math01-cl.weizmann.ac.il:public_html/genomica/Download ";
}

print "$exec_str\n";
system("$exec_str");

__DATA__

deploy.pl <gx file>

    Adds contents to a gxp file. The content gets added before the end of the gxp

   -a <archive_name>: The name of the archive to save (default: Genomica.zip)

   -c:                Copy the archive to the web   


