#! /usr/bin/perl
use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";




#----------------------------------------------------------------
# parameters
#----------------------------------------------------------------
sub c_bio_tokens_2_hash
{

  if (length(@_) != 1 or  @_[0] eq "--help")
  {
      print "Usage: c_bio_tokens_2_hash.pl in_file.h extract the tokens from c bio_tokens.h to perl hash \n\n";
  }

  my ($c_tokens_infile) = @_;



  my %tokens_hash;

  #print $c_tokens_infile . "\n";

  open(INFILE, "<$c_tokens_infile") or die "could not open $c_tokens_infile\n";
  
  my $line = "";
  while(<INFILE>)
  {
    $line = $_;

    if ($line =~ m/^#define.*\"/)
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
      
      $line =~ s/"//;
      $line =~ s/\/\/(.*)$//;
      
      #print $line . "\n";
      $line =~ m/(\w*)\s*(\w*)/;
      #print $1 . "\n";
      #print $2 . "\n";
      my $token = $1;
      my $token_str = $2;
      $token =~ s/^\s+//;
      $token =~ s/\s+$//;
      $token_str =~ s/^\s+//;
      $token_str =~ s/\s+$//;

      $tokens_hash{$token} = $token_str;

    }
   
  }
  close(INFILE);

  return \%tokens_hash;
}


#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
#if (length($ARGV[0]) > 0 and $ARGV[0] ne "--help")
#{
#  my %args = load_args(\@ARGV);
#
#  my $tokens_hash_ptr = &c_bio_tokens_2_hash_main($ARGV[0]);
#  my %ret_tokens_hash = %$tokens_hash_ptr;
#  return \%ret_tokens_hash;
#}
#else
#{
#  print "Usage: c_bio_tokens_2_hash.pl in_file.h extract the tokens from c bio_tokens.h to perl hash \n\n";
#}
