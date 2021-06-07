#!/usr/bin/perl

use strict;
use POSIX;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libfile.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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

my $row_counter = 0;

while (<$file_ref>)
{
  chomp;
  #my $str = "";
  my @row = split(/\t/);
  if ($row_counter == 0)
  {
    $row_counter++;
  }
  elsif ($row_counter >= 1)
  {
	#system("cp $row[0]-UraDetFw.ab1 $row[1]-UraDetFw.ab1");
	#system("cp $row[0]-PromSeqTstRv.ab1 $row[1]-PromSeqTstRv.ab1");
  
    system("cp $row[0]-UraDetFw.TXT $row[1]-tmp");
    &change_fasta_head("$row[1]-tmp", "$row[1]-UraDetFw.TXT", ">$row[1]-UraDetFw");
    system("rm $row[1]-tmp");
    
    system("cp $row[0]-UraDetFw.TXT.qual $row[1]-tmp");
    &change_fasta_head("$row[1]-tmp", "$row[1]-UraDetFw.TXT.qual", ">$row[1]-UraDetFw");
    system("rm $row[1]-tmp");
    
    system("cp $row[0]-PromSeqTstRv.TXT $row[1]-tmp");
    &change_fasta_head("$row[1]-tmp", "$row[1]-PromSeqTstRv.TXT", ">$row[1]-UPromSeqTstRv");
    system("rm $row[1]-tmp");
    
    system("cp $row[0]-PromSeqTstRv.TXT.qual $row[1]-tmp");
    &change_fasta_head("$row[1]-tmp", "$row[1]-PromSeqTstRv.TXT.qual", ">$row[1]-UPromSeqTstRv");
    system("rm $row[1]-tmp");
  }
}

sub change_fasta_head
{
   my $input_file_name = @_[0];
   my $output_file_name = @_[1];
   my $new_header = @_[2];
   
   open (INPUT, "<$input_file_name") or die "Failed to open $input_file_name"; 
   my @r;
   my $old_header;
   my $inner_row_counter=0;
   my $sequence;
   while (<INPUT>)
   {
    if ($inner_row_counter==0)
    {
    $inner_row_counter++;
    open (OUTPUT, ">>$output_file_name") or die "Failed to open $output_file_name";
    print OUTPUT "$new_header\n";
    }
    elsif ($inner_row_counter>=1)
    {
    #chomp;
    @r = split(/\t/);
    $sequence = shift(@r);
    #open (OUTPUT, ">>$output_file_name") or die "Failed to open $output_file_name";
    print OUTPUT "$sequence";
    }
   }
   close OUTPUT;
   close INPUT
}

__DATA__

change_filenames.pl <file>

   Changes the names of files in a folder according to a table containing the old and new names

   

