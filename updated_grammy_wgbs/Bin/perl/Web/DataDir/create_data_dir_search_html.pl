#!/usr/bin/perl

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

# Open output files
open (LEG_ORG_FILE, ">legend_organisms.html") or die ("Failed to open file:'legend_organisms.html'\n");
my $leg_org_file = \*LEG_ORG_FILE;

open (NON_LEG_ORG_FILE, ">non_legend_organisms.html") or die ("Failed to open file:'non_legend_organisms.html'\n");
my $non_leg_org_file = \*NON_LEG_ORG_FILE;

open (TECHNOLOGY_FILE, ">technology.html") or die ("Failed to open file:'technology.html'\n");
my $technology_file = \*TECHNOLOGY_FILE;

open (DATA_SOURCE_FILE, ">data_sources.html") or die ("Failed to open file:'data_sources.html'\n");
my $data_source_file = \*DATA_SOURCE_FILE;

open (FILE_FORMATS_FILE, ">file_formats.html") or die ("Failed to open file:'file_formats.html'\n");
my $file_formats_file = \*FILE_FORMATS_FILE;

# Open input files
open (IN_ORG_FILE, "OrganismListForWeb") or die ("Failed to open file:'OrganismListForWeb'\n");
my $in_org_file = \*IN_ORG_FILE;

open (IN_TECHNOLOGY_FILE, "TechnologyList") or die ("Failed to open file:'TechnologyList'\n");
my $in_technology_file = \*IN_TECHNOLOGY_FILE;

open (IN_DATA_SOURCE_FILE, "DataSourceListForWeb") or die ("Failed to open file:'DataSourcesList'\n");
my $in_data_source_file = \*IN_DATA_SOURCE_FILE;

open (IN_FILE_FORMATS_FILE, "FileFormatsList") or die ("Failed to open file:'FileFormatsList'\n");
my $in_file_formats_file = \*IN_FILE_FORMATS_FILE;

# Main
&insertRegularCB ($in_technology_file, $technology_file, "Technology");
&insertRegularCB ($in_data_source_file, $data_source_file, "DataSources");
&insertRegularCB ($in_file_formats_file, $file_formats_file, "FileFormats");

# Create Organism files
print $non_leg_org_file ("<td>\n<select id=\"OrganismsSelect\" name=\"OrganismsDD\" size=\"6\">\n");
while (<$in_org_file>)
  {
    chop;
    my $line = $_;
    my $name;
    
    if ($line =~ /^m /) # Legend organism
      {
	my @strs = split(/ /,$line);
	$name = $strs[1];
	my @versions = @strs[3 .. $#strs];

	if ($line =~ / - /) # Organism has versions
	  {
	    &insertCB ("Organisms", "parent", "", $name, $leg_org_file);
	    print $leg_org_file ("<td>\n");
	    foreach my $ver (@versions)
	      {
		&insertCB ("Organisms", "version", $name, $ver, $leg_org_file);
	      } 
	    print $leg_org_file ("</td>\n</th>\n<th> &nbsp; &nbsp; &nbsp; &nbsp; </th>\n");
	  }
	else
	  {
	    &insertCB ("Organisms", "regular", "", $name, $leg_org_file);
	  }
      }
    else
      {
	print $non_leg_org_file ("<option value=\"".$line."\">".$line."</option>\n");
      }
  }
print $non_leg_org_file ("</select>\n</td>\n");
# Arguments: input_file_ref, output_file_ref, fieldsetName
sub insertRegularCB
  {
    my $input_file_ref  = @_[0];
    my $output_file_ref = @_[1];
    my $fieldsetName    = @_[2];

    my $i = 1;
    while (<$input_file_ref>)
      {
	if ($i % 15 == 0)
	  {
	    print $output_file_ref("</tr>\n<tr>\n");
	  }
	chop;
	&insertCB ($fieldsetName, "regular", "", $_, $output_file_ref);
	$i = $i + 1;
      }
  }
# Arguments: fieldsetName, type, parentName, name, output_file_ref
sub insertCB 
  {
    my $fieldsetName = @_[0];
    my $type         = @_[1];
    my $parentName   = @_[2];
    my $name         = @_[3];
    my $output_file  = @_[4];

    if ($type eq "regular")
      {
	print $output_file ("<td align=\"left\">\n<input type=\"checkbox\" name=\"".$fieldsetName."CB\" value=\"".$name."\">".$name."\n</td>\n");
      }
    elsif ($type eq "parent")
      {
	print $output_file ("<th align=\"left\">\n<input type=\"checkbox\" name=\"".$fieldsetName."CB\" id=\"".$name."Parent\" value=\"".$name."\" onclick=\"checkVersions('".$name."')\">".$name."\n");
      }
    elsif ($type eq "version")
      {
	print $output_file ("<input type=\"checkbox\" name=\"".$parentName."VerCB\" value=\"".$name."\" onclick=\"checkParent('".$parentName."')\">".$name."\n");
      }
  }

__DATA__

   create_data_dir_search_html.pl

   Create small html files that are meant to be integrated into search_data_dir.html file. The files are dynamically built from the lists of organisms, 
   data sources, file formats and technology.
