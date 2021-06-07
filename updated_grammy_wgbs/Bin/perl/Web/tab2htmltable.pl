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

my $body = get_arg("body", 0, \%args);
my $header = get_arg("header", "", \%args);
my $border = get_arg("border", 1, \%args);
my $cell_spacing = get_arg("cs", 5, \%args);
my $cell_padding = get_arg("cp", 5, \%args);
my $td_header = get_arg("td", "", \%args);
my $colors = get_arg("colors", "", \%args);

if (length($td_header) > 0) { $td_header = " $td_header"; }

if ($body eq "1") { print "<html>\n<body>\n"; }

if (length($header) > 0) { print "<h1>$header</h1>\n"; }

my %colors;
my @lines = split(/\,/, $colors);
foreach my $line (@lines)
{
  my @row = split(/\;/, $line);
  $colors{$row[0]} = "$row[1]";
}

print "<table border=\"$border\" cellspacing=\"$cell_spacing\" cellpadding=\"$cell_padding\">\n";

while(<$file_ref>)
{
  chop;

  if (length($_) > 0)
  {
      print "<tr>";

      my @row = split(/\t/);

      for (my $i = 0; $i < @row; $i++)
      {
	  if (length($colors{$row[$i]}) > 0) { print "<td$td_header bgcolor=\"$colors{$row[$i]}\">"; }
	  else { print "<td$td_header>"; }
	  print "$row[$i]</td>";
      }

      print "</tr>\n";
  }
  else
  {
      print "</table>\n";
      print "<br>\n";
      print "<table border=\"1\">\n";
  }
}

print "</table>\n";

if ($body eq "1") { print "</body>\n</html>\n"; }



__DATA__

list2htmltable.pl <file>

   Takes in a tab delimited file and creates an html table from the list

   -body:         If specified, outputs the body of the html as well

   -header <str>: If specified, prints str as the header of the html file

   -td <str>:     If specified, prints str inside the opening <td> of each column

   -border <num>: Border width (default: 1)
   -cs <num>:     Cell spacing (default: 5)
   -cp <num>:     Cell padding (default: 5)

   -colors:       List of colors for each string. The format is: "1;#0000FF,weird;#C0C0C0"
                  for coloring columns whose string is '1' with the color \#0000FF and for
                  coloring columns whose string is 'weird' with the color \#C0C0C0.

