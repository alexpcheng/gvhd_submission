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
my $td_header = get_arg("td", "", \%args);
my $link_images = get_arg("link", 0, \%args);
my $print_png = get_arg("png", 0, \%args);
my $print_gif = get_arg("gif", 0, \%args);
my $print_jpg = get_arg("jpg", 0, \%args);

my $r = int(rand(10000));

open(OUTFILE, ">tmp_$r");

my $folder_index = 1;
my $done = 0;
while ($done == 0)
{
    my $folder_str = get_arg("f$folder_index", "", \%args);

    if (length($folder_str) > 0)
    {
	if ($print_png == 1)
	{
	    my $files_str = `find $folder_str/. -name "*.png"`;
	    &CollectImages($files_str);
	}
	if ($print_gif == 1)
	{
	    my $files_str = `find $folder_str/. -name "*.gif"`;
	    &CollectImages($files_str);
	}
	if ($print_jpg == 1)
	{
	    my $files_str = `find $folder_str/. -name "*.jpg"`;
	    &CollectImages($files_str);
	}
    }
    else
    {
	$done = 1;
    }

    $folder_index++;
}

my $pass_args = "";
if ($body == 1) { $pass_args .= "-body "; }
if (length($header) > 0) { $pass_args .= "-header $header "; }
if (length($td_header) > 0) { $pass_args .= "-td $td_header "; }

system("cat tmp_$r | tab2htmltable.pl $pass_args");
system("rm -f tmp_$r");

sub CollectImages
{
    my ($files_str) = @_;

    my @files = split(/\n/, $files_str);

    foreach my $file (@files)
    {
	my @row = split(/\//, $file);

	print STDERR "Adding file $file...\n";

	my $print_name = $row[@row - 1];
	if ($print_name =~ /[\.]/)
	{
	    $print_name =~ /([^\.]+)[\.]/;
	    $print_name = $1;
	}

	if ($link_images == 1)
	{
	  print OUTFILE "<A HREF=\"$file\">$print_name</A>\n";
	}
	else
	{
	  print OUTFILE "$print_name\t<img src=\"$file\">\n";
	}
    }
}

__DATA__

images2htmltable.pl <file>

   Takes in a list of folders and creates a table html file with one image on each row

   -body:         Outputs the body of the html as well

   -header <str>: Prints str as the header of the html file

   -td <str>:     Prints str inside the opening <td> of each column

   -link:         Links the image rather than embeding it within the html

   -f1 <str>:     First folder to find images in (specify other folders with -f2 <str>...)

   -png:          Search for png files
   -gif:          Search for gif files
   -jpg:          Search for jpg files

