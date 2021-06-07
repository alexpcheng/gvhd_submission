#! /usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";


#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0 and $ARGV[0] ne "--help")
{
  my %args = load_args(\@ARGV);

  c_bio_tokens_2_perl_bio_tokens_main($ARGV[0],
				      get_arg("o", "bio_tokens.pl", \%args));
}
else
{
  print "Usage: c_bio_tokens_2_perl_bio_tokens.pl in_file.c extract the tokens from c bio_tokens.h to perl file (the output can be included for use in perl scripts) \n\n";
  print "      -o <output file name>: the output file (default is bio_tokens.pl)\n";

}


#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
sub c_bio_tokens_2_perl_bio_tokens_main
{
  my ($c_tokens_infile, $perl_outfile_prefix) = @_;


  open(INFILE, "<$c_tokens_infile") or die "could not open $c_tokens_infile\n";
  open(OUTFILE, ">$perl_outfile_prefix") or die "could not open $perl_outfile_prefix\n";

  print OUTFILE "#! /usr/bin/perl\n\n";
  print OUTFILE "use strict;\n\n";
  print OUTFILE 'require "$ENV{PERL_HOME}/Lib/load_args.pl";';
  print OUTFILE "\n\n";
  print OUTFILE 'require "$ENV{PERL_HOME}/Lib/system.pl";';
  print OUTFILE "\n\n";

  my $line = "";
  while(<INFILE>)
  {
    $line = $_;

    #print $line;

    if ($line =~ m/^\/\//)
    {
      $line =~ s/^\/\//\#/;
      print OUTFILE $line;
      print $line;
    }
    elsif ($line =~ m/^#define.*\"/)
    {
      $line =~ s/#define\s//;
      chomp($line);
      chomp($line);
      #chop($line);
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;
      
      if ($line =~ m/"$/)
      {
	chop($line);
      }
      
      $line =~ s/"/="/;
      
      $line = "my \$" . $line . "\";\n";
      $line =~ s/\/\/(.*);$/;/;
      print OUTFILE $line;
      print $line;
    }
   
  }
  close(INFILE);
  close(OUTFILE);
  `chmod 775 $perl_outfile_prefix`;
}

