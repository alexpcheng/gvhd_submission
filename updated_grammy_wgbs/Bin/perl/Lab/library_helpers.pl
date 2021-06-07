#!/usr/bin/perl

use strict;

my $ABC = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

my $STRAINS_TABLE = "$ENV{DEVELOP_HOME}/Lab/Databases/Strains/StrainsTable.tab";

my @COLUMN_NAMES = ("Plate no.", "_MaxRow", "_MaxColumn", "Well", "WellContentAlias", "RelatedStrainID", "ActualStrainID", "Medium", "Product", "SourcePlates", "SourceWell", "Success", "Comments", "DateOfPreparation");

my @XLS_COLUMN_NAMES = ("Well", "WellContentAlias", "RelatedStrainID", "ActualStrainID", "Medium", "Product", "SourcePlates", "SourceWell", "Success", "Comments", "DateOfPreparation");

################################
# Input is a 2 columns file.
# Returns a hash with these pairs: <column 1> -> <column 2>
################################
sub load_list_file
{
   my $input_file = @_[0];
   open (INPUT, "<$input_file") or die "Failed to open $input_file";

   my %res;
   my @r;
   my $key;
   while (<INPUT>)
   {
      chop;
      @r = split(/\t/);
      $key = shift(@r);
      $res{$key} = join("\t", @r);
   }

   return %res;
}

##############################
# Get a table line and add its columns to the given hash with key: <COL 0>_COLUMN_NAME
# Input: Hash to store result, Line, Boolean (if input is a template file)
# Return new hash
##############################

sub map_line
{
   my $line = @_[1];
   my $template = @_[2];
   my $hash_scalar = @_[0];
   my %hash = %$hash_scalar;

   my @r = split(/\t/, $line);
   
   
   for (my $i = 1; $i <= $#r; $i++)
   {
      $r[$i] =~ s/^[\s"]*//g;
      $r[$i] =~ s/[\s"]*$//g;
      
#      print STDERR "$r[0]_$COLUMN_NAMES[$i] = \"$r[$i]\"\n";
      $hash{"$r[0]_".($template == 1 ? $COLUMN_NAMES[$i] : $XLS_COLUMN_NAMES[$i])} = $r[$i];
   }

   return %hash;
}

################################
# Input: Well number, Max row (A-Z), Max col (1..)
# Returns well ID
################################
sub num2well_id
{
   my ($num, $max_row, $max_col) = @_;

   my $max_idx = index($ABC, $max_row) + 1;

   my $res_row = $num % $max_idx;
   my $res_col = int($num / $max_idx) + 1;

   if ($num >= $max_idx * $max_col)
   {
      die "num2well_id ($num, $max_row, $max_col): Number too high - out of plate range";
   }
   else
   {
#      print STDERR "num2well_id ($num, $max_row, $max_col) --> ". substr($ABC, $res_row, 1) ."$res_col\n";
      return substr($ABC, $res_row, 1)."$res_col"; 
   }
}

################################
# Input: Well ID, Max row (A-Z), Max col (1..)
# Returns well number (starting from zero, top left down)
################################
sub well_id2num
{
   my ($well_id, $max_row, $max_col) = @_;

   my $max_row_idx = index ($ABC, $max_row) + 1;
   my $res_row = index ($ABC, substr($well_id, 0, 1));
   my $res_col = substr ($well_id, 1) - 1;
   
   if ($res_row >= $max_row_idx or $res_col >= $max_col)
   {
      die "well_id2num ($well_id, $max_row, $max_col): Well id out of plate range";
   }
   else
   {
#      print STDERR "well_id2num ($well_id, $max_row, $max_col) --> " . (($res_col * $max_row_idx) + $res_row) . "\n";
      return ($res_col * $max_row_idx) + $res_row;
   }
}

##############################
#
##############################
sub get_abc
{
   return $ABC;
}

##############################
#
##############################
sub get_strain_table
{
   return $STRAINS_TABLE;
}

##############################
#
#############################
sub get_n_columns
{
   return $#XLS_COLUMN_NAMES + 1;
}

##############################
# Input: column index
# Returns: column name
###############################
sub get_column
{
   return $XLS_COLUMN_NAMES[shift];
}

##############################
# Input: column name
# Returns: column index, -1 if not found
###############################
sub get_column_idx
{
   my $col_name = shift;
   my $idx = -1;
   
   for ($idx = 0; $idx <= $#XLS_COLUMN_NAMES; $idx++)
   {
      if ($XLS_COLUMN_NAMES[$idx] eq $col_name)
      {
	 return $idx;
      }
   }
   return -1;
}


##############################
#
#############################
sub get_n_template_columns
{
   return $#COLUMN_NAMES + 1;
}

##############################
# Input: column index
# Returns: column name
###############################
sub get_template_column
{
   return $COLUMN_NAMES[shift];
}


####################################################################################################
# Input: RobotScriptFileName, PlatesID, InputPlate, OutputPlate, InputWells (array ref), OutputWells (array ref)
# Appends lines to OutputPlate file, using wells from InputPlate (InputWells[i] is moved to OutputWells[i]).
# Adding lines by the order of OutputWells, so it should be sorted.
# Updates RobotScriptFileName file accordingly. PlatesID is used to identify the plates in the script
###################################################################################################
sub transfer_wells_to_plate
{
   my ($robot_file, $id, $inp_p, $out_p, $inp_w_ref, $out_w_ref) = @_;
   my @inp_w = @$inp_w_ref;
   my @out_w = @$out_w_ref;

   if ($#out_w != $#inp_w)
   {
      die "Error: Length of input wells list (".($#inp_w + 1).") is not equal to that of the output wells list (".($#out_w + 1).")";
   }

   if (! (-f "$inp_p".".tab"))
   {
      die "Error: Input plate file $inp_p.tab not found\n";
   }

   open (INP_P, "<${inp_p}.tab") or die "Failed to open ${inp_p}.tab for reading";

   my $header_line = <INP_P>;

   my $line;
   my %inp_lines;

   while (<INP_P>)
   {
      chop;
      $line = $_;
      $line =~ s/\r//g;
      my $well = substr($line, 0, index($line, "\t"));
      if ($inp_lines{$well} != 0)
      {
	 die "Error: Input plate ($inp_p.tab) has duplicate wells ($well)";
      }
      $inp_lines{$well} = $line;
   }
   close INP_P;

   if (-f "$out_p".".tab")
   {
      open (OUT_P, ">>$out_p".".tab") or die "Failed to open ${out_p}.tab for append";
   }
   else
   {
      open (OUT_P, ">$out_p".".tab") or die "Failed to open ${out_p}.tab";
      print OUT_P $header_line;
   }

   my @r;
   for (my $i = 0; $i <= $#out_w; $i++)
   {
      @r = split(/\t/, $inp_lines{$inp_w[$i]});

      print OUT_P "$out_w[$i]\t$r[1]\t$r[2]\t$r[3]\t$r[4]\t$r[5]\t$inp_p\t$inp_w[$i]\t\t\t\n";
   }
   close OUT_P;

   ######################
   # Print to robot file
   ######################
   open (ROBO_FILE, ">>$robot_file") or die "Error: Failed to open $robot_file for append";

   print ROBO_FILE "\nWELL_LIST ${inp_p}_$id ";

   for (my $i = 0; $i <= $#inp_w; $i++)
   {
      print ROBO_FILE ($i > 0 ? "," : "").$inp_w[$i];
   }
   print ROBO_FILE "\nWELL_LIST ${out_p}_$id ";


   for (my $i = 0; $i <= $#out_w; $i++)
   {
      print ROBO_FILE ($i > 0 ? "," : "").$out_w[$i];
   }

   print ROBO_FILE "\n";

   close ROBO_FILE;

}







1
