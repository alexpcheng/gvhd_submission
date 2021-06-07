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
my $well2primer_name_file = get_arg("well2primer_name", "", \%args);
my $well2strain_id_file = get_arg("well2strain_id", "", \%args);
my $plates_template_file = get_arg("plates_template", "", \%args);
my $prefix = get_arg("pre", "", \%args);

if (length($well2primer_name_file) == 0)
{
   die ("Please supply  -well2primer_name parameter\n");
}
if ( !(-f$well2primer_name_file)) 
{
   die ("File $well2primer_name_file not found\n");
}

if (length($well2strain_id_file) == 0)
{
   die ("Please supply  -well2strain_id parameter\n");
}
if ( !(-f$well2strain_id_file)) 
{
   die ("File $well2strain_id_file not found\n");
}
if (length($plates_template_file) == 0)
{
   die ("Please supply  -plates_template parameter\n");
}
if ( !(-f$plates_template_file)) 
{
   die ("File $plates_template_file not found\n");
}

my %col_names_idx;
my $c = 0;
for (my $i = 0; $i < &get_n_template_columns(); $i++)
{
   if (index(&get_template_column($i), "_") != 0)
   {
      $col_names_idx{&get_template_column($i)} = $c++;
   }
}

my %well2primer_name = &load_list_file($well2primer_name_file);


my $tmp_strain_file = "${well2strain_id_file}_tmp".$$;
system ("cat ".&get_strain_table()." | dos2unix.pl | join.pl $well2strain_id_file - -1 2 -2 1 -q | cut.pl -f 2,1,3 > $tmp_strain_file");
my %well2strain_field   = &load_list_file($tmp_strain_file);


my %column_names;

open (TEMPLATE, "<$plates_template_file") or die "Failed to open $plates_template_file\n";
my $header_line = <TEMPLATE>;
chop $header_line;

my @cols = split(/\t/, $header_line);

$header_line = "";
for (my $i = 0; $i <= $#cols; $i++)
{
   my $curr_col = $cols[$i];
   $curr_col =~ s/^\s\s*//g;
   $curr_col =~ s/\s\s*$//g;
   if ($curr_col ne &get_template_column($i))
   {
      die "Illegal column name for column " . ($i + 1) . ": Expecting \"".&get_template_column($i)."\", received \"$curr_col\"\n";
   }
   
   if ($i >= 1 and !($curr_col =~ /^_/))
   {
      $header_line .= (length($header_line) > 0 ? "\t" : "") . $curr_col;
   }
}

my %mapped_fields;
my $curr_line;
while (<TEMPLATE>)
{
   chop;
   $curr_line = $_;

   %mapped_fields = &map_line(\%mapped_fields, $curr_line, 1);
   my @r = split (/\t/, $curr_line);
   my $line_id = $r[0];
#   print STDERR "curr_line: $curr_line\tline_id: $line_id\n";
   my $first_plate;
   my $last_plate;
   if ($line_id =~ /^(\d+)-(\d+)$/)
   {
      $first_plate = $1;
      $last_plate = $2;
   }
   elsif ($line_id =~ /^(\d+)$/)
   {
      $first_plate = $last_plate = $1;
   }
   else 
   {
      die ("Illegal plate number: $line_id\n");
   }
   
   for (my $p_num = $first_plate; $p_num <= $last_plate; $p_num++)
   {
      print STDERR "Producing ${prefix}${p_num}.tab\n";
      open (PLATE_FILE, ">${prefix}${p_num}.tab") or die ("Failed to open ${prefix}${p_num}.tab for writing");
      print PLATE_FILE "$header_line\n";
      
      if (!($mapped_fields{"${line_id}__MaxRow"} =~ /[A-Z]/))
      {
	 die ("Illegal maximum row: ".$mapped_fields{"${line_id}__MaxRow"}."\n");
      }
      
      if (!($mapped_fields{"${line_id}__MaxColumn"} =~ /\d+/))
      {
	 die ("Illegal maximum column: ".$mapped_fields{"${line_id}__MaxColumn"}."\n");
      }
      
      my $a = "A";
      my $n_wells = (index(&get_abc(), $mapped_fields{"${line_id}__MaxRow"})+1)*$mapped_fields{"${line_id}__MaxColumn"};
      


      for my $col (1..$mapped_fields{"${line_id}__MaxColumn"})
      {
	 for my $row ($a..$mapped_fields{"${line_id}__MaxRow"})
	 {
	  
	    my $well_id = "$row$col";
#	    print STDERR "$p_num\t$well_id\n";
	    if (!$well2primer_name{$well_id})
	    {
	       die ("Failed to find matching primer name for well $well_id\n");
	    }
	    my $primer_name = $well2primer_name{$well_id};
	    if (!$well2strain_field{$well_id})
	    {
	       die ("Failed to find matching strain id for well $well_id\n");
	    }
	    my ($strain_id, $strain_name) = split (/\t/, $well2strain_field{$well_id});
	    
	    my $source_well;
	    my $actual_strain_id;
	    my $source_line_id = $mapped_fields{"${line_id}_SourcePlates"};
	    my $source_plate = $source_line_id;

	    if ($mapped_fields{"${line_id}_Well"} eq $mapped_fields{"${line_id}_SourceWell"})
	    {
	       $source_well = $well_id;
	    }
	    elsif ($mapped_fields{"${line_id}_SourceWell"} eq "SepToPlates")
	    {
	       my $source_well_num = ($p_num - $first_plate) * $n_wells + &well_id2num($well_id, $mapped_fields{"${line_id}__MaxRow"}, $mapped_fields{"${line_id}__MaxColumn"});$mapped_fields{"${source_line_id}__MaxRow"};
#	       print STDERR "Source well num: $source_well_num\n";
	       $source_well = &num2well_id($source_well_num , $mapped_fields{"${source_line_id}__MaxRow"}, $mapped_fields{"${source_line_id}__MaxColumn"});
	    }
	    elsif ($mapped_fields{"${line_id}_SourceWell"} eq "CollectFromPlates")
	    {
	       if ($source_line_id =~ /(\d+)-(\d+)/)
	       {
		  my $source_first_plate = $1;
		  my $source_last_plate = $2;
		  my $source_max_row = $mapped_fields{"${source_line_id}__MaxRow"};
		  my $source_max_col = $mapped_fields{"${source_line_id}__MaxColumn"};
		  my $source_n_wells = (index(&get_abc(), $source_max_row) + 1) * $source_max_col;
		  
		  my $num = &well_id2num($well_id, $mapped_fields{"${line_id}__MaxRow"}, $mapped_fields{"${line_id}__MaxColumn"});
		  $source_plate = $source_first_plate + int($num / $source_n_wells);
		  $source_well = &num2well_id($num % $source_n_wells , $mapped_fields{"${source_line_id}__MaxRow"}, $mapped_fields{"${source_line_id}__MaxColumn"});
	       }
	       else
	       {
		  die "Error: In CollectFromPlates mode, SourcePlates should have this format: <first plate>-<last plate>";
	       }
	    }
	    elsif ($mapped_fields{"${line_id}_SourceWell"} eq "SameFromRespectivePlate")
	    {
	       if ($source_line_id =~ /(\d+)-(\d+)/)
	       {
		  if ((($2 - $1) != ($last_plate - $first_plate)) or 
		      ($mapped_fields{"${source_line_id}__MaxRow"} ne $mapped_fields{"${line_id}__MaxRow"}) or
		      ($mapped_fields{"${source_line_id}__MaxColumn"} ne $mapped_fields{"${line_id}__MaxColumn"}))
		  {
		     die "Error: In SameFromRespectivePlate mode, number and type of source plates do not match current step number and size of plates";
		  }
		  
		  $source_plate = $1 + $p_num - $first_plate;
		  $source_well = $well_id;
	       }
	       else
	       {
		  die "Error: In SameFromRespectivePlate mode, SourcePlates should have this format: <first plate>-<last plate>";
	       }
	    }
	    else
	    {
	       $source_well = "";
	    }
	    
	    if ($mapped_fields{"${line_id}_ActualStrainID"} eq "INHERITED")
	    {
	       $actual_strain_id = `grep '^$well_id\t' ${prefix}${source_plate}.tab | cut -f $col_names_idx{"ActualStrainID"}`;
	       chop $actual_strain_id;
	    }

	    my $line = "";
	    for (my $i = 1; $i < &get_n_template_columns(); $i++)
	    {
	       if (!(&get_template_column($i) =~ /^_/))
	       {
		  if (&get_template_column($i) eq "Well")
		  {
		     $line .= (length($line) > 0 ? "\t" : "") . $well_id;
		  }
		  elsif (&get_template_column($i) eq "SourceWell")
		  {
		     $line .= (length($line) > 0 ? "\t" : "") . $source_well;
		  }
		  elsif (&get_template_column($i) eq "SourcePlates")
		  {
		     my $sp_str = "";
		     if ($source_plate =~ /,/)
		     {
			for my $s (split(/,/, $source_plate))
			{
			   if (length($sp_str) > 0)
			   {
			      $sp_str .= ",";
			   }
			   $sp_str .= $prefix . $s;
			}
		     }
		     else
		     {
			$sp_str = $prefix.$source_plate;
		     }
		     $line .= (length($line) > 0 ? "\t" : "") . $sp_str;
		  }
		  elsif (&get_template_column($i) eq "ActualStrainID" and $actual_strain_id)
		  {
		     $line .= (length($line) > 0 ? "\t" : "") . $actual_strain_id;
		  }
		  else
		  {
		     $line .= (length($line) > 0 ? "\t" : "") . $mapped_fields{"${line_id}_".&get_template_column($i)};
		  }
	       }
	    }
	    $line =~ s/\{PRIMER_NAME\}/$primer_name/g;
	    $line =~ s/\{STRAIN_ID\}/$strain_id/g;
	    $line =~ s/\{PLATE_NAME\}/${prefix}${p_num}/g;
	    $line =~ s/\{STRAIN_NAME\}/$strain_name/g;
	    print PLATE_FILE "$line\n";
	 }
      }
      close (PLATE_FILE);
   }

   unlink $tmp_strain_file;
}

__DATA__

make_library_exp_tab_files.pl <file>

   Creates a tab file per plate in the experiment

    -pre <str>:                        Use <str> as a file name prefix (file name will be: <str><#plate>.tab).

    -well2primer_name <str>:           File <str> maps wells (column 1) to primer names (column 2).
                                       For example:
                                            A1   RPL12A
                                            A2   RPS25A

    -well2strain_id <str>:             File <str> maps wells (column 1) to strain ids (column 2), which will be search for at ?? --> $ENV{DEVELOP_HOME}/Lab/Databases/Strains/StrainsTable.tab. 
                                       For example:
                                            A1   567
                                            A2   568

    -plates_template <str>:            Template row for each plate. First column should contain the plate number. Column with names starting with "_" will not appear in the plate tab file. 
                                       See example in ~/Lab/LibraryConstruction/plate_template.txt

                                       Plates template file columns are (keep the exact column name):
                                          1.      Plate no.
                                          2.      _MaxRow
                                          3.      _MaxColumn
                                          4.      Well
                                          5.      WellContentAlias
                                          6.      RelatedStrainID
                                          7.      ActualStrainID
                                          8.      Medium
                                          9.      Product
                                          10.     SourcePlates
                                          11.     SourceWell
                                          12.     Success
                                          13.     Comments
                                          14.     DateOfPreparation


                                       Columns 1-3 are used to produce the files and will not appear in the output files.
                          
                                       Any text in each field will be replicated to each row in the output table. The following key words 
                                       will be replaced by the matching value for the well_id from the given input files (well2primer_name 
                                       and well2strain_id): {PRIMER_NAME}, {STRAIN_ID}, {STRAIN_NAME}, {PLATE_NAME}

				       If ActualStrainID value is "INHERITED", the field will be taken from the matching line in the source plate.

                                       Possible values for the SourceWell field:
                                           1. A1 - source well is identical to current well id.
                                           2. Empty - do not fill source well, copy value of SourcePlates to all the rows.
                                           3. SepToPlates - Distribute source plate wells over several smaller plates (going from top left corner down and to the right)
                                           4. CollectFromPlates - Collect wells from several plates to a single one (going from top left corner down and to the right)
                                           5. SameFromRespectivePlate - if source plates number and size match current number and size of plates, match pairs of plates in 
                                                                        the SourcePlates field.

                                           In options 3-5 "Plate no." and "SourcePlates" fields must have this format: <first plate no.>-<last plate no.>


