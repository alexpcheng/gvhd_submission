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

my $output_file = get_arg("o", "microarray2gx.gxp", \%args);
my $gene_list = get_arg("g", "", \%args);
my $experiment_list = get_arg("e", "", \%args);
my $gene_names_file = get_arg("gene_names", "", \%args);
my $url_prefix = get_arg("url", "", \%args);
my $org = get_arg("org", "", \%args);
my $name = get_arg("name", "", \%args);
my $gene_namespace = get_arg("gns", "", \%args);
my $description = get_arg("d", "", \%args);
my $xml = get_arg("xml", "0", \%args);

my $r = int(rand(100000));

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/GeneXPress/microarray2genexpress.map ";
$exec_str   .= "expression_file=$file ";

if (length($gene_list) > 0) { $exec_str .= "gene_list=$gene_list "; }
if (length($experiment_list) > 0) { $exec_str .= "experiment_list=$experiment_list "; }
if (length($gene_names_file) > 0) { $exec_str .= "gene_names_file=$gene_names_file "; }
if (length($url_prefix) > 0) { $exec_str .= "url_prefix=$url_prefix "; }

$exec_str .= "output_file=$output_file -xml > tmp.$r";

system("$exec_str");

$description = &remove_illegal_xml_chars ($description);
$description =~ s/\t/ /g;
$description =~ s/\&/\\&/g;
$description =~ s/\//\\\//g;

if ($xml eq "1")
{
  system("cat tmp.$r");
}
else
{
  system("$ENV{GENIE_EXE} tmp.$r");
  my $n_experiments = `grep "^<Experiment Id=" ${output_file} | cut -f 2 -d '"' | tail -n 1 | tr -d '\n'` + 1;
  my $cmd = "cat $output_file  | sed 's/^<TSCRawData/<TSCRawData Description=\"$description\" Organism=\"$org\" Name=\"$name\" GeneNamespace=\"$gene_namespace\" NumExperiments=\"$n_experiments\"/g' > ${output_file}_tmp_$r; mv ${output_file}_tmp_$r $output_file";
system ("$cmd");
}

system("rm tmp.$r");

#---------------------------------------------------------------------------
# remove_illegal_chars
#---------------------------------------------------------------------------
sub remove_illegal_xml_chars
{
  my $str = $_[0];
  $str =~ s/\&/&amp;/g;
  $str =~ s/\"/&quot;/g;
  $str =~ s/\'/&apos;/g;
  $str =~ s/\</&lt;/g;
  $str =~ s/\>/&gt;/g;
  return $str;
}

__DATA__

microarray2gx.pl <file>

   Converts the microarray to a GeneXPress format

   -o <name>:          The output file name (default: microarray2gx.gxp)
   -g <name>:          If specified, will use <name> as the gene list
   -e <name>:          If specified, will use <name> as the experiment list
   -gene_names <file>: If Specified, uses file as the gene names mapping
   -url:               URL prefix

   -xml:               If specified, print only the xml file

   -org <str>:         Organism (optional)
   -gns <str>:         Gene namespace (e.g. S0106, hg17, optional)
   -d   <str>:         Description
