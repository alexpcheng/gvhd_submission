#!/usr/bin/perl

use File::Basename;
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

my $templateName = get_arg("t", "expand", \%args);

open(FILE,"element_$templateName.txt");
my @LINES = <FILE>;
close(FILE);
my $template = join ('', @LINES);
	
# Step on files, add each one to the index file, with
# its' help text (in case it exists) and a link to the
# HTML-ized program

my @problems;
my $fileIndex = 0;
my $current_element;
my $content;

my $indexHTML = "";

while(<$file_ref>)
{
    chop;
    
    my $program;
    my $dir;
    my $ext;
    my $fullPath = $_;
    
    ($program, $dir, $ext) = fileparse ($fullPath, '\..*');
	print STDERR "Adding $program... ";
	
	$fileIndex = $fileIndex + 1;
	
	my $help_exists = `grep -c -e --help $_`;
	
	if ($help_exists > 0)
	{
		$content = `$fullPath --help`;
		
		if (length ($content) == 0)
		{
			push (@problems, "$program.pl");
		}
 
		$content =~ s/\</&lt;/g; 
		$content =~ s/\>/&gt;/g;
		
		$content =~ s/\s+$//o;
		$content =~ s/^\s+//o;
	}
	else
	{
		$content = "Help not available.";
	}
		
	$current_element = $template;
	$current_element =~ s/QQQHelpTextQQQ/$content/g;
	$current_element =~ s/QQQnumQQQ/$fileIndex/g;
	$current_element =~ s/QQQProgramNameQQQ/$program/g;
	$current_element =~ s/QQQHTMLSourceQQQ/$program.html/g;

	$indexHTML = $indexHTML . $current_element;

	
	print STDERR "Generating HTML... \n";
	
	system ("perl2html.pl $fullPath > $program.html");
}

# Read header
open(FILE,"header_$templateName.txt");
my @LINES = <FILE>;
close(FILE);
my $header = join ('', @LINES);
$header =~ s/QQQnumFilesQQQ/$fileIndex/g;

print $header;
print $indexHTML;

# Print footer 
system ("cat footer_$templateName.txt");

print STDERR "\n$fileIndex scripts indexed using template \"$templateName\".\n\n";

if (@problems)
{
	print STDERR "WARNING: The following files seemed to have a --help option but did not return\nanything (writing to STDERR? Failing to compile?):\n\n";
	print STDERR join ("\n", @problems);
	print STDERR "\n\n";
}

__DATA__

make_genie_help.pl <file>

   Creates a master index.html file containing the help
   messages of specified perl programs.
   
   Also creates a syntax-colored HTML version of every
   given perl program, which is linked to from index.html
   
   -t <str>  Template to use (default is 'exapnd')
   
