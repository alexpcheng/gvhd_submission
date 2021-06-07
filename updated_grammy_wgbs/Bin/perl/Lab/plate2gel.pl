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


#my $a = 1 ;
#my $b = 2 ;
my $c = 3 ;
my $d = 4 ;
my $e = 5 ;
my $f = 6 ;
my $g = 7 ;
my $h = 8 ; 

#my $beginning = get_arg("b", 0, \%args);
#my $column_location = get_arg("c", -1, \%args);
#my $start_counter = get_arg("n", 0, \%args);
#my $column_string = get_arg("s", "", \%args);
#my $empty_string = get_arg("e", 0, \%args);
#my $divide_columns_string = get_arg("d", "", \%args);
#my $multiply_columns_string = get_arg("m", "", \%args);
#my $subtract_columns_string = get_arg("u", "", \%args);
#my $add_columns_string = get_arg("a", "", \%args);
#my $min_columns_string = get_arg("min", "", \%args);
#my $max_columns_string = get_arg("max", "", \%args);
#my $count_columns_string = get_arg("count", "", \%args);
#my $average_columns_string = get_arg("ave", "", \%args);
#my $qauntile_range_string = get_arg("quant", "0,1", \%args);


#my $add_file = get_arg("f", "", \%args);
#my $significant_nums = get_arg("sn", "2", \%args);

#$column_string =~ s/\"//g;

#my @divide_columns = split(/\,/, $divide_columns_string);
#my @multiply_columns = &ParseRanges($multiply_columns_string);
#my @subtract_columns = split(/\,/, $subtract_columns_string);
#my @add_columns = &ParseRanges($add_columns_string);
#my @min_columns = &ParseRanges($min_columns_string);
#my @max_columns = &ParseRanges($max_columns_string);
#my @count_columns = &ParseRanges($count_columns_string);
#my @average_columns = &ParseRanges($average_columns_string);
#my @qauntile_range = split(/\,/, $qauntile_range_string);

#my @columns;
#if (length($add_file) > 0)
#{
#  open(FILE, "<$add_file");
#  while(<FILE>)
#  {
#    chomp;

#    push(@columns, $_);
#  }
#}

#print ("This is working\n");
#print ("file_ref = $file_ref\n");
#print ("file = $file\n");


my $row_counter = 0;
my $plate_column ;
my $plate_row ;
my $gel_num ;
my %gel_lengths ;
my $gel_n;
my $sequence_l;
my @wells= qw(A1 B1 A2 B2 A3 B3 A4 B4 A5 B5 A6 B6 A7 B7 A8 B8 A9 B9 A10 B10 A11 B11 A12 B12 C1 D1 C2 D2 C3 D3 C4 D4 C5 D5 C6 D6 C7 D7 C8 D8 C9 D9 C10 D10 C11 D11 C12 D12 E1 F1 E2 F2 E3 F3 E4 F4 E5 F5 E6 F6 E7 F7 E8 F8 E9 F9 E10 F10 E11 F11 E12 F12 G1 H1 G2 H2 G3 H3 G4 H4 G5 H5 G6 H6 G7 H7 G8 H8 G9 H9 G10 H10 G11 H11 G12 H12) ;
while (<$file_ref>)
{
  chomp;

  my $str = "";
  #if (length($add_file) > 0) { $str = $columns[$row_counter]; }
  #elsif (length($column_string) > 0) { $str = $column_string; }
  #elsif ( $empty_string ) { $str = ""; }
  #elsif (length($divide_columns_string) > 0)
  #{
  
  
  my @row = split(/\t/);
  if ($row_counter == 0)
  {
    $row_counter++;
  }
  elsif ($row_counter >= 1)
  {
    #print ("I am here\n") ;
    #print ("@row\n") ;
    
    $plate_column = ceil($row_counter/8);
    $plate_row = $row_counter - 8*(ceil($row_counter/8)-1);
    
    $gel_num = 26*(ceil($plate_row/2)-1)+2*$plate_column-1;
    if ($plate_row % 2 == 0) {
      $gel_num++ ;
    }
    
    #print ("Plate Row=$plate_row, Plate Column=$plate_column \n");
    #print ("gel_num = $gel_num \n");
    
    if ($row[2])
    {
    system("filter.pl ~/Develop/Lab/Databases/Strains/StrainsTable.tab -c 0 -estr $row[2] | cut.pl -f 1,7 | stab2length.pl | cut.pl -f 2 > well2strain");
    my $sequence_length = &load_list_file("well2strain");
    $gel_lengths{$gel_num} = $sequence_length ;
    #print ("length = $sequence_length\n");
    
    }
    $row_counter++;
  }
}
unlink("well2strain") ;
#while(($gel_n,$sequence_l) = each %gel_lengths) {
#  print ("$gel_n\t$sequence_l\n");
#}

print("Gel Number\tBand Size\tWell\n");
my $count_well=0;
foreach $gel_n (sort {$a <=> $b} keys %gel_lengths) {
    my $sequence_l = $gel_lengths{$gel_n};
    my $well = $wells[$count_well];
    print ("$gel_n\t$sequence_l\t$well\n");
    $count_well++;
  }


sub load_list_file
{
   my $input_file = @_[0];
   open (INPUT, "<$input_file") or die "Failed to open $input_file";

   my %res;
   my @r;
   my $length_of_sequence;
   while (<INPUT>)
   {
      chomp;
      @r = split(/\t/);
      $length_of_sequence = shift(@r);
      $length_of_sequence--;
      #$res{$key} = join("\t", @r);
   }

   return $length_of_sequence;
}


__DATA__

plate2gel.pl <file>

   Transform a plate file such as from Data/Promoter/Plates/PlateFiles *.txt into a tab dilimited gel file which contains the length of each sequence.
   The operation assumes pipetting with 12 pippetor (each row) into positions seperated by 1 well from each other
   For example, A1,A2,A3.. A12 go to 1,3,5,7,..,23 
  

   -n:                 number of wells (default 96)
   

