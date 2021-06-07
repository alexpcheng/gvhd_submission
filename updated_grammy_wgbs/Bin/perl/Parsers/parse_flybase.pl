#!/usr/bin/perl

##############################################################################
##############################################################################
##
## parse_flybase.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "$ENV{PERL_HOME}/Lib/libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $key_col = $args{'-k'} - 1;
my $delim   = $args{'-d'};
my $headers = $args{'-h'};
my $file    = $args{'--file'};

my $line_no = 0;
my $filep = &openFile($file);
my $id = '';
my %desc;
my $entries = 0;
my $passify = 1000;
my $total_entries = int(`grep '^\*z' < Remote/genes.txt | wc -l`);
while(<$filep>)
{
   $line_no++;
   if($line_no > $headers)
   {
      if(/\*z[ ]+(FBgn\d+)/)
      {
	 &printThis($id, \%desc);

         $id     = $1;

	 undef(%desc);

	 $entries++;

	 if($entries % $passify == 0)
	 {
	    my $done = int($entries / $total_entries * 100.0);
	    print STDERR "$entries parsed ($done% done).\n";
	 }
      }
      if(/\*i[ ]+(CG\d+)/)
      {
         $desc{$1} = 1;
      }
      elsif(/\*i[ ]+(\S.+\S)[ ]*$/)
      {
         $desc{&niceText($1)} = 1;
      }
      elsif(not(/GO:\d+/))
      {
         if(/\*d[ ]+(\S.+\S)[ ]*\|/)
	 {
	    $desc{&niceText($1)} = 1;
	 }
         elsif(/\*d[ ]+(\S.+\S)[ ]*$/)
	 {
	    $desc{&niceText($1)} = 1;
	 }
      }
      elsif(/\*M[ ]+(\S.+\S)[ ]*$/)
      {
	 $desc{&niceText($1)} = 1;
      }
   }

}
close($filep);

&printThis($id, \%desc);

exit(0);

sub printThis
{
   my ($id, $desc) = @_;

   if($id =~ /\S/)
   {
      $id =~ tr/a-z/A-Z/;

      my @desc  = sort { length($a) <=> length($b); } keys(%{$desc});

      for(my $i = $#desc; $i >= 0; $i--)
      {
	 if(not($desc[$i] =~ /\S/))
	 {
	    splice(@desc, $i, 1);
	 }
      }

      if(scalar(@desc) > 0)
      {
	 my $name = splice(@desc, 0, 1);

         print STDOUT $id, "\t", $name, "\t", join('|', @desc), "\n";
      }
   }
}

sub niceText
{
   my ($text) = @_;

   $text =~ s/^[ ]+//;
   $text =~ s/[ ]+$//;
   $text =~ s/([ ])[ ]+/$1/g;
   $text =~ s/\&[^;]+;//g;
   $text =~ s/\<[^>]+\>[^<]*\<\/[^>]+\>//g;

   return $text;
}

__DATA__
syntax: parse_flybase.pl [OPTIONS] [FILE | < FILE]

