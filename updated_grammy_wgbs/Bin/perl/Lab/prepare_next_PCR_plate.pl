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
my $previous_pcr_plate = get_arg("prev_pcr_plate", "", \%args);
my $next_pcr_source_plates = get_arg("next_pcr_source_plates_names", "", \%args);
my $new_plate_name = get_arg("new_plate_name", "", \%args);
my $table_name = get_arg("table_name", "REPLACE_WITH_TABLE_NAME", \%args);
my $input_plate_pos = get_arg("input_plate_pos", "REPLACE_WITH_INPUT_PLATE_POSITION", \%args);
my $output_plate_pos = get_arg("output_plate_pos", "REPLACE_WITH_OUTPUT_PLATE_POSITION", \%args);
my $volume = get_arg("volume", "REPLACE_WITH_VOLUME", \%args);
my $liquid_class = get_arg("liquid_class", "REPLACE_WITH_LIQUID_CLASS", \%args);
my $tiptype = get_arg("tiptype", "REPLACE_WITH_TIPTYPE", \%args);

if (length($previous_pcr_plate) == 0)
{
   die ("Please supply  -previous_pcr_plate parameter\n");
}
if (length($next_pcr_source_plates) == 0)
{
   die ("Please supply  -next_pcr_source_plates_names parameter\n");
}
if (length($new_plate_name) == 0)
{
   die ("Please supply  -new_plate_name parameter\n");
}

my $prev_pcr_plate_file = $previous_pcr_plate.".tab";
if ( !(-f$prev_pcr_plate_file)) 
{
   die ("File $prev_pcr_plate_file not found\n");
}

my %mapped_next_plate_src = ();
my %mapped_next_plate_strain_id_src = ();
my $strain_id;
my @next_pcr_names = split(/,/, $next_pcr_source_plates);
my @r;
for my $n (@next_pcr_names)
{
   open (NEXT_PLATE_SOURCE, "<${n}.tab") or die "Failed to open ${n}.tab for reading";
   my %tmp_mapped;
   while (<NEXT_PLATE_SOURCE>)
   {
      chop;
      %tmp_mapped = &map_line(\%tmp_mapped, $_, 0);
      @r = split (/\t/, $_);
      $strain_id = $r[&get_column_idx("RelatedStrainID")];
      my $x = $mapped_next_plate_strain_id_src{$n."_".$strain_id};
      if ($x)
      {
	 $mapped_next_plate_strain_id_src{$n."_".$strain_id} = $x . "_" . $r[&get_column_idx("Well")];
      }
      else
      {
	 $mapped_next_plate_strain_id_src{$n."_".$strain_id} = $r[&get_column_idx("Well")];
      }
   }
   close NEXT_PLATE_SOURCE;
   for my $k (keys %tmp_mapped)
   {
      $mapped_next_plate_src{$n}->{$k} = $tmp_mapped{$k};
   }
}

open (PREV_PLATE, "<$prev_pcr_plate_file") or die "Failed to open $prev_pcr_plate_file for reading";
open (NEW_PLATE, ">$new_plate_name".".tab") or die "Failed to create ${new_plate_name}.tab";

my $header_line = <PREV_PLATE>;
print NEW_PLATE $header_line;

my $max_row = `dos2unix.pl < $prev_pcr_plate_file | tail -n +2 | cut -c 1 | sort  | tail -n 1`;
my $max_col = `dos2unix.pl < $prev_pcr_plate_file | tail -n +2 | cut -f 1 | cut -c 2- | sort -n | tail -n 1`;
chop $max_row;
chop $max_col;

my %from_list;
my %to_list;

my $curr_well_num = 0;
my @r;

while (<PREV_PLATE>)
{
   chop;
   @r = split(/\t/);

   if (length($r[&get_column_idx("Success")]) > 0 and $r[&get_column_idx("Success")] ne "NA" and $r[&get_column_idx("Success")] == 0)
   {
      my $selected_next_plates = substr ($r[&get_column_idx("Comments")], index($r[&get_column_idx("Comments")], ": ") + 2);

      if (! $selected_next_plates)
      {
	    print STDERR "Error: Please specify next pcr plates for well $r[0] (check \"Comments\" column in plate $previous_pcr_plate).\n";
            exit 1;
      }

      for my $n (split (/,/, $selected_next_plates))
      {
	 my $same_strain_ids_wells = $mapped_next_plate_strain_id_src{$n . "_" . $r[&get_column_idx("RelatedStrainID")]};
	 for my $well (split (/_/, $same_strain_ids_wells))
	 {
	    my $curr_well = num2well_id($curr_well_num++, $max_row, $max_col);

	    if ($mapped_next_plate_src{$n}->{${well}."_".&get_column(1)})
	    {
	       print NEW_PLATE "$curr_well\t".$mapped_next_plate_src{$n}->{${well}."_".&get_column(1)}."\t".$mapped_next_plate_src{$n}->{${well}."_".&get_column(2)}."\t".$mapped_next_plate_src{$n}->{${well}."_".&get_column(3)}."\t".$mapped_next_plate_src{$n}->{${well}."_".&get_column(4)}."\t$r[5]\t$n\t$well\t\t\t\n";
	       
	       $from_list{$n} = $from_list{$n}. $well . ",";
	       $to_list{$n} = $to_list{$n}. $curr_well . ",";
	    }
	    else
	    {
	       print STDERR "Error: plate $n not found (check \"Comments\" column in plate $previous_pcr_plate).\n";
	       exit 1;
	    }
	 }
      }
   }
}
close PREV_PLATE;
close NEW_PLATE;

######################
#
# Create robot script
#
######################
open (ROBO_FILE, ">transfer_wells_".join("_", @next_pcr_names)."_to_${new_plate_name}.conf") or die "Failed to create file transfer_wells_".join(@next_pcr_names, "_")."_to_${new_plate_name}.conf";

print ROBO_FILE "\nDOC\nThis program transfer wells from plate " . join (" ", @next_pcr_names). " into plate $new_plate_name\n\nENDDOC\n\nTABLE $table_name\n";


my @curr_from;
my @curr_to;

for (my $s = 0; $s <= $#next_pcr_names; $s++)
{
   if ($from_list{$next_pcr_names[$s]} and $to_list{$next_pcr_names[$s]})
   {
      print ROBO_FILE "\nWELL_LIST $next_pcr_names[$s]_list_$s ";
      
      @curr_from =  split (/,/, $from_list{$next_pcr_names[$s]}) ;
      for (my $i = 0; $i <= $#curr_from; $i++)
      {
	 if ($curr_from[$i])
	 {
	    print ROBO_FILE ($i > 0 ? "," : "").$curr_from[$i];
	 }
      }
      print ROBO_FILE "\nWELL_LIST ${new_plate_name}_list_$s ";
      
      @curr_to =  split (/,/, $to_list{$next_pcr_names[$s]}) ;
      for (my $i = 0; $i <= $#curr_to; $i++)
      {
	 if ($curr_to[$i])
	 {
	    print ROBO_FILE ($i > 0 ? "," : "").$curr_to[$i];
	 }
      }
   }
}

print ROBO_FILE "\n\nSCRIPT\n\n";

for (my $s = 0; $s <= $#next_pcr_names; $s++)
{
   print ROBO_FILE "PROMPT Put input plate $next_pcr_names[$s] at $input_plate_pos\nTRANSFER_WELLS $input_plate_pos $next_pcr_names[$s]_list_$s $output_plate_pos ${new_plate_name}_list_$s $volume $liquid_class TIPTYPE:$tiptype\n\n";
}

print ROBO_FILE "ENDSCRIPT\n";

close ROBO_FILE;

__DATA__

 prepare_next_PCR_plate.pl

   Creates an tab and a robot script file for the next plate for PCR.
   The failed wells from the previous PCR plate will be taken from the colony source plate to the new plate.

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

      -prev_pcr_plate <str>:                Name of the previous PCR plate with success information on each well (1 - success, 0 - fail, NA - do not process), expecting file <str>.tab to exist. The "Comments" column should specify from which next pcr source plates to take the well (expecting this format in the Comments column: ...: <plate 1 name>,<plate 2 name>,...).

      -next_pcr_source_plates_names <str>:  Names of the colony source plates for the new plate (comma delimited, at least one).

      -new_plate_name <str>:                Name of the new plate (plate file will be <str>.tab)

  Robot script parameters:

      -table_name <str>:                    Robot table name (e.g. tableExample.ewt)
      -input_plate_pos <str>:               Input plate position (e.g. P3)
      -output_plate_pos <str>:              Output plate position (e.g. P5)
      -volume <num>:                        Volume
      -liquid_class <str>:                  Liquid class
      -tiptype <str>:                       Tip type




 Example matching the diagram below:
 ==================================

 prepare_next_PCR_plate.pl -prev_pcr_plate 37 -next_pcr_source_plates_names 35 -new_plate_name 38


               34                   35                   36
           ----------           ----------           ----------
           |        |           |        |           |        |
           |        |           |        |           |        |
           | Colony |           | Colony |           | Colony |
           |   I    |           |   II   |           |  III   |
           |        |           |        |           |        |
           ----------           ----------           ----------
                |                    |
                |                    |
                |                    |
               \ /                  \ /
               37                   38
           ----------           ----------
           |        |           |        |
           |  PCR   |           |  PCR   |           Create 
           | plate  |           | plate  |   o o o   plate 39
           |   I    |           |  II    |           if needed
           |        |           |        |
           ----------           ----------


   The robot script will be saved in a file named: transfer_wells_35to38.conf
