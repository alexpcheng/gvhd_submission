#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my %journal_mapping;
$journal_mapping{"bioessays"} = "BioEssays";
$journal_mapping{"bioinformatics"} = "Bioinformatics";
$journal_mapping{"blood"} = "Blood";
$journal_mapping{"bmcbioinformatics"} = "BMC Bioinformatics";
$journal_mapping{"bmcgenomics"} = "BMC Genomics";
$journal_mapping{"cell"} = "Cell";
$journal_mapping{"chromosomeresearch"} = "Chromosome Research";
$journal_mapping{"co"} = "Current Opinion";
$journal_mapping{"cr"} = "Cancer Research";
$journal_mapping{"embo"} = "European Molecular Biology Organization";
$journal_mapping{"endocrine"} = "Endocrine";
$journal_mapping{"gb"} = "Genome Biology";
$journal_mapping{"gd"} = "Genes and Development";
$journal_mapping{"genetics"} = "Genetics";
$journal_mapping{"gr"} = "Genome Research";
$journal_mapping{"hmg"} = "Human Molecular Genetics";
$journal_mapping{"jb"} = "Journal of Biology";
$journal_mapping{"jcb"} = "Journal of Cell Biology";
$journal_mapping{"jmb"} = "Journal of Molecular Biology";
$journal_mapping{"jtb"} = "Journal of Theoretical Biology";
$journal_mapping{"mc"} = "Molecular Cell";
$journal_mapping{"mcb"} = "Molecular and Cellular Biology";
$journal_mapping{"nature"} = "Nature";
$journal_mapping{"nb"} = "Nature Biotechnology";
$journal_mapping{"ng"} = "Nature Genetics";
$journal_mapping{"nrg"} = "Nature Reviews Genetics";
$journal_mapping{"nsmb"} = "Nature Structural Molecular Biology";
$journal_mapping{"plosbio"} = "PLoS Biology";
$journal_mapping{"pnas"} = "PNAS";
$journal_mapping{"science"} = "Science";
$journal_mapping{"tcb"} = "Trends in Cell Biology";
$journal_mapping{"tg"} = "Trends in Genetics";

my $pdf = get_arg("pdf", "", \%args);
my $title = get_arg("t", "", \%args);
my $journal = get_arg("j", "", \%args);
my $description = get_arg("d", "", \%args);

my @row = split(/\//, $pdf);
my $only_pdf = $row[@row - 1];

my $first_author;
my $year;

if ($only_pdf =~ /_/)
{
  $only_pdf =~ /([^\_]+)_([^\/]+)([0-9][0-9])[\.]pdf/;
  $first_author = $1;
  my $journal_abbreviation = $2;
  $year = $3;

  if (length($journal) == 0)
  {
    $journal = $journal_mapping{$journal_abbreviation};
  }
}
else
{
  $only_pdf =~ /(.*)([0-9][0-9])[\.]pdf/;
  $first_author = $1;
  $year = $2;
}

print "\u$first_author\t";
print "<A HREF=\"$pdf\">\u$first_author et al.</A>\t";
print "$journal\t";
if ($year >= 30) { print "19$year\t"; }
else { print "20$year\t"; }
print "$title\t";
print "$description\n";


__DATA__

reference.pl

   Generate a reference to a paper. The convention is that the paper
   is named "*yy.pdf" where yy is the first author's last name, and
   yy are the last two digits of the year.

   Format of pdf name: [first_author]_[journal_abbreviation][year].pdf
              Example: segal_ng03.pdf (for segal et al., Nature Genetics, 2003)

   Journal abbreviations:
      bioessays          --- Bioessays
      bioinformatics     --- Bioinformatics
      blood              --- Blood
      bmcbioinformatics  --- BMC Bioinformatics
      bmcgenomics        --- BMC Genomics
      cell               --- Cell
      chromosomeresearch --- Chromosome Research
      co                 --- Current Opinion
      cr                 --- Cancer Research
      embo               --- European Molecular Biology Organization
      endocrine          --- Endocrine
      gb                 --- Genome Biology
      gd                 --- Genes and Development
      genetics           --- Genetics
      gr                 --- Genome Research
      hmg                --- Human Molecular Genetics
      jb                 --- Journal of Biology
      jcb                --- Journal of Cell Biology
      jmb                --- Journal of Molecular Biology
      jtb                --- Journal of Theoretical Biology
      mc                 --- Molecular Cell
      mcb                --- Molecular and Cellular Biology
      nature             --- Nature
      nb                 --- Nature Biotechnology
      ng                 --- Nature Genetics
      nrg                --- Nature Reviews Genetics
      nsmb               --- Nature Structural Molecular Biology
      plosbio            --- PLoS Biology
      pnas               --- PNAS
      science            --- Science
      tcb                --- Trends in Cell Biology
      tg                 --- Trends in Genetics

   -pdf <file>: The name of the pdf
   -t <name>:   The title of the paper
   -j <name>:   The journal's name (overrides abbreviations in pdf)
   -d <desc>:   Description of the paper

