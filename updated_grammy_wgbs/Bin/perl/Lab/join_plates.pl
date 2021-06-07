#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lab/library_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $source_plates = get_arg("source_plates", "", \%args);
my $new_plate_name = get_arg("new_plate_name", "", \%args);
my $select_mode = get_arg("select_wells_by", "SuccessUnique", \%args);
my $comment_str = get_arg("str_in_comment", "UseWell", \%args);
my $leave_empty = get_arg("leave_empty", "", \%args);
my $table_name = get_arg("table_name", "REPLACE_WITH_TABLE_NAME", \%args);
my $input_plate_pos = get_arg("input_plate_pos", "REPLACE_WITH_INPUT_PLATE_POSITION", \%args);
my $output_plate_pos = get_arg("output_plate_pos", "REPLACE_WITH_OUTPUT_PLATE_POSITION", \%args);
my $volume = get_arg("volume", "REPLACE_WITH_VOLUME", \%args);
my $liquid_class = get_arg("liquid_class", "REPLACE_WITH_LIQUID_CLASS", \%args);
my $tiptype = get_arg("tiptype", "REPLACE_WITH_TIPTYPE", \%args);

if (length($source_plates) == 0)
{
   die ("Please supply  -source_plates parameter\n");
}
if (length($new_plate_name) == 0)
{
   die ("Please supply  -new_plate_name parameter\n");
}

open (NEW_PLATE, ">$new_plate_name".".tab") or die "Failed to create ${new_plate_name}.tab";
print NEW_PLATE "Well\tWellContentAlias\tRelatedStrainID\tActualStrainID\tMedium\tProduct\tSourcePlates\tSourceWell\tSuccess\tComments\tDateOfPreparation\n";

my @from_lists;
my @to_lists;
my %assigned_wells;
my %leave_empty;

my $global_max_row = -1;
my $global_max_col = -1;
my $curr_well_num = 0;
my $line;

for my $empty_well (split(/,/, $leave_empty))
{
    $leave_empty{$empty_well} = 1;
}

for my $curr_src_plate (split(/,/, $source_plates))
{
   my $curr_source_plate_file = $curr_src_plate.".tab";
   if ( !(-f$curr_source_plate_file))
   {
      die ("File $curr_source_plate_file not found\n");
   }

   open (SRC_PLATE, "<$curr_source_plate_file") or die "Failed to open $curr_source_plate_file for reading";


   my $header_line = <SRC_PLATE>;

   my $max_row = `dos2unix.pl < $curr_source_plate_file | tail -n +2 | cut -c 1 | sort  | tail -n 1`;
   my $max_col = `dos2unix.pl < $curr_source_plate_file | tail -n +2 | cut -f 1 | cut -c 2- | sort -n | tail -n 1`;
   chop $max_row;
   chop $max_col;


   if ($global_max_row == -1)
   {
      $global_max_row = $max_row;
      $global_max_col = $max_col;
   }
   elsif ($global_max_row < $max_row or $global_max_col < $max_col)
   {
      die "Error: current plate ($curr_src_plate) size is bigger then previous plates sizes.";
   }


   my @from_list;
   my @to_list;

   my @r;

   my $max_well_num = (index(&get_abc(), $global_max_row) + 1) * $global_max_col;

   if ($max_well_num == 0)
   {
      die "Maximum output well number is zero...";
   }

   while (<SRC_PLATE>)
   {
      chop;
      $line = $_;
      $line =~ s/\r//g;

      @r = split(/\t/, $line);

      if (($select_mode eq "SuccessUnique" and (!$assigned_wells{$r[&get_column_idx("RelatedStrainID")]} and length($r[&get_column_idx("Success")]) > 0 and $r[&get_column_idx("Success")] ne "NA" and $r[&get_column_idx("Success")] == 1)) or
	  ($select_mode eq "AllSuccess" and (length($r[&get_column_idx("Success")]) > 0 and $r[&get_column_idx("Success")] ne "NA" and $r[&get_column_idx("Success")] == 1)) or
	  ($select_mode eq "ByStrInComment" and $r[&get_column_idx("Comments")] =~ $comment_str))
      {
	 $assigned_wells{$r[&get_column_idx("RelatedStrainID")]} = 1;

	 while (($curr_well_num < $max_well_num) && $leave_empty{num2well_id($curr_well_num, $global_max_row, $global_max_col)})
	 {
	     my $curr_well = num2well_id($curr_well_num, $global_max_row, $global_max_col);
	     print NEW_PLATE "$curr_well\tEMPTY\t\t\t\t\t\t\t\t\t\n";
	     $curr_well_num++;
	 }

	 if (($select_mode eq "AllSuccess" or $select_mode eq "ByStrInComment") and ($curr_well_num == $max_well_num)) 
	 {
	    print "*****\n"."Warning: Too many wells selected for output plate size. Only first 96 were used.\n"."*****\n";
	    last;
	 }

	 my $curr_well = num2well_id($curr_well_num++, $global_max_row, $global_max_col);
	 print NEW_PLATE "$curr_well\t$r[1]\t$r[2]\t$r[3]\t$r[4]\t$r[5]\t$curr_src_plate\t$r[0]\t\t\t\n";
	 push (@from_list, $r[0]);
	 push (@to_list, $curr_well);
      }
   }

   push @from_lists, [ @from_list ];
   push @to_lists,   [ @to_list ];

   close SRC_PLATE;
}

close NEW_PLATE;

######################
#
# Create robot script
#
######################
my @src_plates = split (/,/, $source_plates);

open (ROBO_FILE, ">transfer_wells_".join("_", @src_plates)."_to_${new_plate_name}.conf") or die "Failed to create file transfer_wells_".join(@src_plates, "_")."_to_${new_plate_name}.conf";

print ROBO_FILE "\nDOC\n\nThis program transfers wells from plates $source_plates into plate $new_plate_name.\n\n";

if ($leave_empty) { print ROBO_FILE "Wells $leave_empty in plate $new_plate_name will be left empty, unless you change that.\n\n";}

print ROBO_FILE "ENDDOC\n\nTABLE $table_name\n";



my @curr_from;
my @curr_to;

for (my $s = 0; $s <= $#src_plates; $s++)
{
   print ROBO_FILE "\nWELL_LIST $src_plates[$s]_list_$s ";

# for $i ( 0 .. $#AoA ) {
#         $aref = $AoA[$i];
#         $n = @$aref - 1;
#         for $j ( 0 .. $n ) {
#             print "elt $i $j is $AoA[$i][$j]\n";
#         }
#     }

   @curr_from =  @{$from_lists[$s]} ;
   for (my $i = 0; $i <= $#curr_from; $i++)
   {
      print ROBO_FILE ($i > 0 ? "," : "").$curr_from[$i];
   }
   print ROBO_FILE "\nWELL_LIST ${new_plate_name}_list_$s ";

   @curr_to =  @{$to_lists[$s]} ;
   for (my $i = 0; $i <= $#curr_to; $i++)
   {
      print ROBO_FILE ($i > 0 ? "," : "").$curr_to[$i];
   }
}

print ROBO_FILE "\n\nSCRIPT\n\n";

for (my $s = 0; $s <= $#src_plates; $s++)
{
   print ROBO_FILE "PROMPT Put input plate $src_plates[$s] at $input_plate_pos\nTRANSFER_WELLS $input_plate_pos $src_plates[$s]_list_$s $output_plate_pos ${new_plate_name}_list_$s $volume $liquid_class TIPTYPE:$tiptype\n\n";
}

print ROBO_FILE "ENDSCRIPT\n";

close ROBO_FILE;


__DATA__

 prepare_plate_for_sequencing.pl

   Collect successful wells from several input plates into a single new plate.
   Creates a tab and a robot script file for the new plate.

   Source and new plates have these columns:
     1       Well
     2       WellContentAlias
     3       RelatedStrainID
     4       ActualStrainID
     5       Medium
     6       Product
     7       SourcePlates
     8       SourceWell
     9       Success
     10      Comments
     11      DateOfPreparation

 Parameters:
 ==========

      -source_plates <str>:               Names of the source plates, comma separated (e.g. '37,38,39')

      -new_plate_name <str>:              Name of the new plate (plate file will be <str>.tab)

      -select_wells_by <str>:             Options for <str>:
                                            - SuccessUnique : Default, select a single successful source per RelatedStrainID.
                                            - AllSuccess    : Select all successful wells (error if number exceeds output plate size)
                                            - ByStrInComment: Select all wells with a certain string in their comment field (see -str_in_comment, error if number exceeds output plate size)

      -str_in_comment <str>:              For -select_wells_by ByStrInComment, select wells that have <str> in their comment field (default: "UseWell").
      -leave_empty <str>:                 List the wells you would like to leave empty in the final plate, comma separated, surrounded by single quotations. (e.g. 'A4,G6,H12') Order does not matter.


  Robot script parameters:

      -table_name <str>:                  Robot table name (e.g. tableExample.ewt)
      -input_plate_pos <str>:             Input plate position (e.g. P3)
      -output_plate_pos <str>:            Output plate position (e.g. P5)
      -volume <num>:                      Volume
      -liquid_class <str>:                Liquid class
      -tiptype <str>:                     Tip type




 Example matching the diagram below:
 ==================================

 join_plates.pl  -source_plates '37,38,39' -new_plate_name 40


           ----------       ----------       ----------
           |        |       |        |       |        |
           |        |       |        |       |        |
           |   37   |       |   38   |       |   39   |
           |        |       |        |       |        |
           |        |       |        |       |        |
           ----------       ----------       ----------
                \                |                /
                 \               |               /
                  \              |              /
                   \_____________|_____________/
                                 |
                                \ /
                            ----------
                            |        |
                            |        |
                            |   40   |
                            |        |
                            |        |
                            ----------


   The robot script will be saved in a file named: transfer_wells_37_38_39_to_40.conf
