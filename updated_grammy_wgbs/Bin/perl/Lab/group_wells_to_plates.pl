#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lab/library_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $MAX_ROW = 'H';
my $MAX_COL = 12;

my %args = load_args(\@ARGV);
my $script_name = get_arg("script_name", "_NOT_SPECIFIED_", \%args);
my $source_plates_dir = get_arg("source_plates_dir", ".", \%args);
my $pre = get_arg("pre", "", \%args);
my $wells_groups_file = get_arg("wells_groups", "", \%args);
my $control_wells_file = get_arg("control_wells", "", \%args);
my $debug = get_arg("debug",0, \%args);

my $table_name = get_arg("table_name", "REPLACE_WITH_TABLE_NAME", \%args);
my $transfer_order = get_arg("transfer_order", "KeepInput", \%args);

#my $input_plate_pos = get_arg("input_plate_pos", "REPLACE_WITH_INPUT_PLATE_POSITION", \%args);
#my $output_plate_pos = get_arg("output_plate_pos", "REPLACE_WITH_OUTPUT_PLATE_POSITION", \%args);
my $volume = get_arg("volume", "REPLACE_WITH_VOLUME", \%args);
my $liquid_class = get_arg("liquid_class", "REPLACE_WITH_LIQUID_CLASS", \%args);
my $tiptype = get_arg("tiptype", "REPLACE_WITH_TIPTYPE", \%args);

my $tmp_str = $$."_".time();
if (! (-d $source_plates_dir))
{
   die "Error: source_plates_dir not found: $source_plates_dir";
}

if (length($wells_groups_file) == 0)
{
   die ("Please supply  -wells_groups parameter\n");
}
if (! (-f $wells_groups_file))
{
   die "Error: wells_groups file not found: $wells_groups_file";
}
if (length($control_wells_file) == 0)
{
   die ("Please supply  -control_wells parameter\n");
}
if (! (-f $control_wells_file))
{
   die "Error: control_wells file not found: $control_wells_file";
}

if ($transfer_order ne "KeepInput" and $transfer_order ne "KeepOutput")
{
   die "Error: Unknown transfer order: $transfer_order\nPlease specify KeepInput or KeepOutput";
}

##########################
# Parsing control wells
##########################
my $control_wells_str = `dos2unix.pl < $control_wells_file `;
my @control_wells = split (/\n/, $control_wells_str);

my %control_wells;
my $n_control_wells = 0;
for my $cw (@control_wells)
{
   my ($inp_p, $inp_w, $out_w) = split (/\t/, $cw);

   if ($control_wells{$out_w} != 0)
   {
      die "Error: Multiple assignment to the same output well ($out_w) in control wells file: $control_wells_file\n";
   }
   $control_wells{$out_w} = $inp_p . "\t" . $inp_w;
   $n_control_wells++;
}

###############################
# Reading intput wells groups
###############################
system ("cat $wells_groups_file | dos2unix.pl | cut -f 3 | see.pl > tmp_$tmp_str; dos2unix.pl < $wells_groups_file | join.pl - tmp_$tmp_str -1 3 -2 2 -q | sort -k 4nr,4 -k 1,1 -k 2,2 > tmp_${tmp_str}_ginfo;");

#my $wells_groups_str = `dos2unix.pl < $wells_groups_file | join.pl - tmp_$tmp_str -1 3 -2 2 -q | sort -k 4nr,4 -k 2,2 | cut.pl -f 2,3,1`;
#unlink "tmp_$tmp_str";
my $wells_groups_str = `dos2unix.pl < $wells_groups_file | sort `;

my @wells_groups = split (/\n/, $wells_groups_str);
my %input_wells_by_group;
my %groups_sizes;
my $max_group_size = -1;

for my $gl (@wells_groups)
{
   my ($inp_p, $inp_w, $gid) = split (/\t/, $gl);

   if (! (-f "$source_plates_dir/${inp_p}.tab"))
   {
      die "Error: Input plate $source_plates_dir/$inp_p.tab not found, check out $wells_groups_file file\n";
   }

   my $prev_wells = $input_wells_by_group{$gid};
   $input_wells_by_group{$gid} = (length($prev_wells) > 0 ? "${prev_wells};" : "") . $inp_p . "\t" . $inp_w;
   $groups_sizes{$gid} = $groups_sizes{$gid} > 0 ? $groups_sizes{$gid} + 1 : 1;

   $max_group_size =  $groups_sizes{$gid} > $max_group_size ? $groups_sizes{$gid} : $max_group_size;
}

#################################
# Assign groups to output plates
################################
my $n_free_wells = &well_id2num ($MAX_ROW.$MAX_COL, $MAX_ROW, $MAX_COL) - $n_control_wells + 1;

if ($max_group_size > $n_free_wells)
{
   die "Error: Largest group size ($max_group_size) exceeds the number of available wells ($n_free_wells)";
}

#my @groups = keys %groups_sizes;
my $groups_str = `cut -f 1 tmp_${tmp_str}_ginfo | uniq`;
system ("rm tmp_${tmp_str} tmp_${tmp_str}_ginfo");

my @groups = split (/\n/, $groups_str);

#my @groups_to_assign = ();
my %assigned_groups;

my %groups2plates;
my $curr_out_p_n = 0;
my $curr_free_wells = $n_free_wells;
my @assigned = ();

while ($#assigned != $#groups)
{
   $debug and print "Assigned $#assigned of $#groups\n";

   $curr_free_wells = $n_free_wells;
   $curr_out_p_n++;
   #@groups_to_assign = ();

   foreach my $gid (@groups)
   {
      $debug and print "Group $gid\n";
      if (!$assigned_groups{$gid})
      {
	 
	 if ($groups_sizes{$gid} <= $curr_free_wells)
	 {
	    $groups2plates{$gid} =  $curr_out_p_n;
	    $curr_free_wells -= $groups_sizes{$gid};
	    
	    $debug and print "Assigned $curr_out_p_n\t$gid\t".$groups_sizes{$gid}."\n";
	    $assigned_groups{$gid} = 1;
	 }
	 else
	 {
	    #push (@groups_to_assign, $gid);
	    $debug and print "Did not assign: $gid\t".$groups_sizes{$gid}."\n";
	 }
      }
   }

   @assigned = keys %assigned_groups;
#   @groups = @groups_to_assign;
}

#######################
# Robot script init
########################
if ($script_name eq "_NOT_SPECIFIED_")
{
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
   $year += 1900;

   $mon = length($mon) == 1 ? "0" . $mon : $mon;
   $hour = length($hour) == 1 ? "0" . $hour : $hour;
   $min = length($min) == 1 ? "0" . $min : $min;

   $script_name = "${pre}transfer_wells_".($year)."_".($mon)."_".($mday)."_".($hour).":".($min).".conf";
}

open (ROBO_FILE, ">$script_name") or die "Failed to create file $script_name";
print ROBO_FILE "\nDOC\n\nThis program transfers wells grouped by $wells_groups_file with control wells specified $control_wells_file.\n\nENDDOC\n\nTABLE $table_name\n";


#########################################################################################
# Prepare transfer file (columns: input plate, output plate, input well, output well)
#########################################################################################
my $pid = $$;
my $tmp_trans_file = "tmp_transfer_$tmp_str";
open (TRANS_FILE, ">$tmp_trans_file") or die ("Error: Failed to open $tmp_trans_file for write");

my $out_p;
my $inp_p;
my $inp_w;
my $out_w;
my $inp_w_idx;
my $out_w_idx;

my %next_free_well_idx;

# Control wells
for (my $i = 1; $i <= $curr_out_p_n; $i++)
{
   $next_free_well_idx{$i} = 0;
   unlink "${pre}${i}.tab";

   for my $out_w (keys %control_wells)
   {
      ($inp_p, $inp_w) = split (/\t/, $control_wells{$out_w}, 2);
      print TRANS_FILE "$inp_p\t$i\t".(&well_id2num($inp_w, $MAX_ROW, $MAX_COL))."\t$out_w\n";
      $debug and print "$inp_p\t$i\t$inp_w\t$out_w\n";
   }
}

# Assigned groups
my @inp_pairs;

for my $gid (keys %input_wells_by_group)
{
   $out_p = $groups2plates{$gid};
   @inp_pairs = split(/;/, $input_wells_by_group{$gid});
   
   for my $line (@inp_pairs)
   {
      ($inp_p, $inp_w) = split (/\t/, $line);
      for ($out_w_idx = $next_free_well_idx{$out_p}; $control_wells{&num2well_id($out_w_idx, $MAX_ROW, $MAX_COL)}; $out_w_idx++){}
      print TRANS_FILE "$inp_p\t$out_p\t".(&well_id2num($inp_w, $MAX_ROW, $MAX_COL))."\t".&num2well_id($out_w_idx, $MAX_ROW, $MAX_COL)."\n";
      $debug and print "$inp_p\t$out_p\t$inp_w\t".&num2well_id($out_w_idx, $MAX_ROW, $MAX_COL)."\n";
      $next_free_well_idx{$out_p} = $out_w_idx + 1;
   }
}

close TRANS_FILE;

if ($transfer_order eq "KeepInput")
{
   system ("cat $tmp_trans_file | sort -k 1,1 -k 2,2 -k 3n,3 > ${tmp_trans_file}_sorted");
}
elsif ($transfer_order eq "KeepOutput")
{
   system ("cat $tmp_trans_file | sort -k 2,2 -k 1,1 -k 3n,3 > ${tmp_trans_file}_sorted");
}
else
{
   die "Error: Unknown transfer order: $transfer_order\nPlease specify KeepInput or KeepOutput";
}


#########################
# Execute transfer file
#########################
open (SORTED_TRANS_FILE, "<${tmp_trans_file}_sorted") or die ("Error: Failed to open ${tmp_trans_file}_sorted for reading");

my $prev_inp_p = "";
my $prev_out_p = "";
my @curr_inp_w;
my @curr_out_w;
my $curr_line = 0;
my $curr_transfer_list = 1;
my @list_pairs = ();
close ROBO_FILE;
while (<SORTED_TRANS_FILE>)
{
   chop;
   $curr_line++;

   ($inp_p, $out_p, $inp_w_idx, $out_w) = split(/\t/);

   if ($curr_line > 1 and ($inp_p ne $prev_inp_p or $out_p ne $prev_out_p))
   {
      &transfer_wells_to_plate ($script_name, $curr_transfer_list, $prev_inp_p, $pre.$prev_out_p, \@curr_inp_w, \@curr_out_w);
      @curr_inp_w = ();
      @curr_out_w = ();
      push (@list_pairs, "$prev_inp_p\t$prev_out_p\t$curr_transfer_list");
      $curr_transfer_list++;
   }

   push (@curr_inp_w, &num2well_id($inp_w_idx, $MAX_ROW, $MAX_COL));
   push (@curr_out_w, $out_w);
   $prev_inp_p = $inp_p;
   $prev_out_p = $out_p;
}

&transfer_wells_to_plate ($script_name, $curr_transfer_list, $prev_inp_p, $pre.$prev_out_p, \@curr_inp_w, \@curr_out_w);
push (@list_pairs, "$inp_p\t$out_p\t$curr_transfer_list");


my @r;
for (my $i = 1; $i <= $curr_out_p_n; $i++)
{
   open (TMP_OUT_FILE, ">tmp_${i}_$$") or die ("Error: Failed to open tmp_${i}_$$ for write");
   open (OUT_TABLE, "<${pre}${i}.tab") or die ("Error: Failed to open ${pre}{i}.tab for read");

   my $header_line = <OUT_TABLE>;

   print TMP_OUT_FILE "well_num\t$header_line";

   while (<OUT_TABLE>)
   {
      chop;
      @r = split (/\t/);
      $out_w_idx = &well_id2num($r[0], $MAX_ROW, $MAX_COL);
      print TMP_OUT_FILE "$out_w_idx\t" . join ("\t", @r) . "\n";
   }
   close TMP_OUT_FILE;
   close OUT_TABLE;

   system ("sort.pl tmp_${i}_$$ -skip 1 -q -c0 0 -n0 | cut -f 2- > ${pre}${i}.tab");
   system ("rm tmp_${i}_$$");
}

##########################
# Finalize robot script
##########################
open (ROBO_FILE, ">>$script_name") or die "Failed to create file $script_name";

print ROBO_FILE "\n\nSCRIPT\n\n";

for my $pair (@list_pairs)
{
   ($inp_p, $out_p, $curr_transfer_list) = split (/\t/, $pair);
   print ROBO_FILE "PROMPT Put input plate ${inp_p} at REPLACE_WITH_INPUT_PLATE_POSITION_$curr_transfer_list\nPROMPT Put output plate ${pre}${out_p} at REPLACE_WITH_OUTPUT_PLATE_POSITION_$curr_transfer_list\nTRANSFER_WELLS REPLACE_WITH_INPUT_PLATE_POSITION_$curr_transfer_list ${inp_p}_$curr_transfer_list REPLACE_WITH_OUTPUT_PLATE_POSITION_$curr_transfer_list ${pre}${out_p}_$curr_transfer_list $volume $liquid_class TIPTYPE:$tiptype\n\n";
}

print ROBO_FILE "ENDSCRIPT\n";

close ROBO_FILE;

################
# Cleanup
################
system ("rm ${tmp_trans_file}_sorted ${tmp_trans_file}");

############################
# Sort hash by value (desc)
############################
# sub hashValueDescendingNum {
#    $groups_sizes{$b} <=> $groups_sizes{$a};
# }


__DATA__

 group_well_to_plates.pl

   Collect wells from several input plates into a output plates making sure that wells from the same group are moved to the same output plate.
   Creates tab files (1.tab, 2.tab ...) and a robot script file for the new plates.

   Method: Assigning the largest group to the first output plate. Then assigning the next largest group that fits into the plate and so on until filling up the first plate. Repeating this process on the next plate with the remaining groups.

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

      -wells_groups <str>  :        File <str> has the input wells groups, with these columns: Plate, Well, GroupID.

      -control_wells <dtr> :        File <str> has the control wells to put with these columns: Input plate, Input well, Output well. It puts the control wells in all output plates.

      -pre <str>           :        Use <str> as prefix for the output plates and robot files.
      -source_plates_dir <str>:     Directory where the source plates are (default: current directory)



  Robot script parameters:

      -script_name <str>   :        File to write the robot script to (default: [pre]transfer_wells_YYYY_MM_DD_HH:MM.conf)
      -transfer_order <str>:        KeepInput  - Transfer from each input plate to all its output plates before moving to the next input plate (default).
                                    KeepOutput - Fill each output plate from all its input plates before moving to the next output plate.

      -table_name <str>    :        Robot table name (e.g. tableExample.ewt)
      -volume <num>        :        Volume
      -liquid_class <str>  :        Liquid class
      -tiptype <str>       :        Tip type




