#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $LIFTOVER_BASE_DIR = "$ENV{GENIE_HOME}/Bin/LiftOver/Remote";

my %args = load_args(\@ARGV);

my $org           = get_arg("org", "Hg", \%args);
my $input_file    = get_arg("f", "", \%args);
my $output_file   = get_arg("o", "", \%args);
my $unmapped_file = get_arg("u", "", \%args);
my $src_build     = get_arg("src", "", \%args);
my $dst_build     = get_arg("dst", "", \%args);

my $lc_org = $org;
$lc_org =~ tr/A-Z/a-z/;

if (($lc_org ne "hg") && ($lc_org ne "mm")){ print STDERR "Error: Unknown organism: $lc_org\n"; exit 1;}
if (not(-e $input_file)) { print STDERR "Error: File not found: $input_file\n"; exit 1;}
if ((($lc_org eq "hg") && not($src_build == 10 || $src_build == 12 || $src_build == 13 || $src_build == 15 || $src_build == 16 || $src_build == 17)) ||
     (($lc_org eq "mm") && not($src_build == 3 || $src_build == 4 || $src_build == 5 || $src_build == 6 || $src_build == 8))) { print STDERR "Error: Source build is not supported: $src_build\n"; exit 1;}
if ((($lc_org eq "hg") && not($dst_build == 16 || $dst_build == 17 || $dst_build == 18)) ||
     (($lc_org eq "mm") && not($dst_build == 7 || $dst_build == 9))) { print STDERR "Error: Destination build is not supported: $dst_build\n"; exit 1;}

if (length($output_file) == 0)
{
   $output_file = $input_file.".out";
}
if (length($unmapped_file) == 0)
{
   $unmapped_file = $input_file.".unmapped";
}

my $cap_org = $lc_org eq 'hg' ? 'Hg' : 'Mm';
my $curr_build = $src_build;
my $lift_file;
my $first = 1;
my $tmp_input_file;
my $tmp_output_file;

while ($curr_build != $dst_build)
{
   if ($first == 1)
   {
      $first = 0;
      $tmp_input_file = $input_file;
      $tmp_output_file = $output_file;
   }
   else
   {
      system "mv $tmp_output_file $output_file.tmp";
      system "mv $unmapped_file $unmapped_file.$curr_build";
      $tmp_input_file = $output_file.".tmp";
      $tmp_output_file = $output_file;
   }
   if ($lc_org eq 'hg')
   {
      if ($curr_build == 10 || $curr_build == 12 || $curr_build == 13)
      {
	 $lift_file = "$LIFTOVER_BASE_DIR/".$lc_org.$curr_build."To".$cap_org."16.over.chain";
	 $curr_build = 16;
      }
      elsif ($curr_build == 15 || $curr_build == 16)
      {
	 $lift_file = "$LIFTOVER_BASE_DIR/".$lc_org.$curr_build."To".$cap_org."17.over.chain";
	 $curr_build = 17;
      }
      elsif ($curr_build == 17)
      {
	 $lift_file = "$LIFTOVER_BASE_DIR/".$lc_org.$curr_build."To".$cap_org."18.over.chain";
	 $curr_build = 18;
      }
      else
      {
	 print STDERR "Error: Illegal build versions\n";
	 exit 1;
      }
      
      print STDERR "$LIFTOVER_BASE_DIR/liftOver $tmp_input_file $lift_file $tmp_output_file $unmapped_file";
      system "$LIFTOVER_BASE_DIR/liftOver $tmp_input_file $lift_file $tmp_output_file $unmapped_file -gff";
   }
   elsif ($lc_org eq 'mm')
   {
      if ($curr_build == 3 || $curr_build == 4 || $curr_build == 5 || $curr_build == 6)
      {
	 $lift_file = "$LIFTOVER_BASE_DIR/".$lc_org.$curr_build."To".$cap_org."7.over.chain";
	 system "$LIFTOVER_BASE_DIR/liftOver $tmp_input_file $lift_file $tmp_output_file $unmapped_file -gff";
	 $curr_build = 7;
      }
      elsif ($curr_build == 8)
      {
	 $lift_file = "$LIFTOVER_BASE_DIR/".$lc_org.$curr_build."To".$cap_org."9.over.chain";
	 system "$LIFTOVER_BASE_DIR/liftOver $tmp_input_file $lift_file $tmp_output_file $unmapped_file -gff";
	 $curr_build = 9;
      }
      else
      {
	 print STDERR "Error: Illegal build versions\n";
	 exit 1;
      }
   }
}

__DATA__

liftover.pl <file>

   Translates genomic coordinates file to a newer genome version.

   -org <ORG>: The organism. Currently supports human (hg) and mouse (mm) (default: hg).
   -f <FILE>: Input file (does not support standard input).

              Expecting gff format: 
                 chr<chr> <type> <ID> <start> <end> <value> <strand> <dummy value>

   -o <FILE>: Output file (default: <input_file>.out).
   -u <FILE>: Unmapped information file (default: <input_file>.unmapped).
   -src <NUM>: The source NCBI build number.
   -dst <NUM>: The output NCBI build number.

      Supported translations: hg10, hg12, hg13, hg15, hg16, hg17 --> hg16, hg17, hg18
                              mm3, mm4, mm5, mm6 --> mm7
                              mm8 --> mm9
