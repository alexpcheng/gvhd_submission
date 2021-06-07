#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $files_str = get_arg("f", 0, \%args);
my $files_from_file_str = get_arg("ff", "", \%args);

my $output_file = get_arg("o", "", \%args);


#print STDERR "\n\nAdding:\n$files_str\n\n";

if (length($output_file) > 0) { open(OUTFILE, ">$output_file"); }

my @files;

if (length($files_from_file_str) > 0)
{
   open(FILES, $files_from_file_str) or die("Could not open the file (the list of files) '$files_from_file_str'.\n");
   @files = <FILES>;
   close(FILES);
}
else
{
   @files = split(/\,/, $files_str);
}

my $files_params = "";
for (my $i = 0; $i < @files; $i++)
{
   chomp($files[$i]);
   $files[$i] =~ s/^\s+//;
   $files[$i] =~ s/\s+$//;

   if (substr($files[$i], length($files[$i]) - 3, 3) ne ".ps" and
       substr($files[$i], length($files[$i]) - 4, 4) ne ".eps" and
       substr($files[$i], length($files[$i]) - 4, 4) ne ".pdf" and
       substr($files[$i], length($files[$i]) - 4, 4) ne ".jpg" and
       substr($files[$i], length($files[$i]) - 5, 5) ne ".jpeg" and
       substr($files[$i], length($files[$i]) - 5, 5) ne ".tiff")
   {
      print STDERR "Warning: Unsupported file type: Ignoring $files[$i]\n";
   }
   elsif (-r $files[$i])
   {
      $files_params = $files_params." $files[$i]";
   }
   else
   {
      print STDERR "Warning: $files[$i] not found\n";
   }
}

system ("pstill -M default -J 70 -o $output_file $files_params");

__DATA__

create_pdf.pl

   Combine input files into a pdf.

   -o <file>:     Output file name

   -f <f1,f2>:    List of all files, separated by commas. Supporting these formats: 

                            Format        Extension
                            ======        =========
                            JPEG          jpg/jpeg
                            Postscript    ps/eps
                            PDF           pdf
                            TIFF          tiff
   -ff <file>     Give the list of all files in a file (file per line)
