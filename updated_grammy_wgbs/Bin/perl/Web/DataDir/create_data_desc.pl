#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/libfile.pl";

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

# This script should be executed from $HOME_GENIE/Data directory
my $temp = `pwd`;
chop ($temp);
if ( $temp ne $ENV{GENIE_HOME}."/Data")
  {
    print ("The script should be executed from $ENV{GENIE_HOME}/Data directory\n");
    exit 1;
  }

my $BASE_FILES = $ENV{DEVELOP_HOME}."/perl/Web/DataDir/lists";
my $ORGANISM_LIST    = $BASE_FILES."/OrganismList";
my $DATA_SOURCE_LIST = $BASE_FILES."/DataSourceList";
my $DESCRIPTION_LIST = $BASE_FILES."/Description";
my $VERSION_LIST     = $BASE_FILES."/VersionList";

my %Organisms;
my %DataSources;
my %Versions;
my @description_files;

# Read lists
%Organisms    = &FileList2Hash ($ORGANISM_LIST);
%DataSources  = &FileList2Hash ($DATA_SOURCE_LIST);
%Versions     = &FileList2Hash ($VERSION_LIST);

# Main Loop - traverse over each directory
@description_files = `find . -name description.desc`;
foreach my $file (@description_files)
  {
    my $curr_dir = &getPathPrefix($file);
    $curr_dir = substr($curr_dir, 2, length($curr_dir)-3);

    my @organisms = ();
    my @data_sources = ();
    my @versions = ();
    my @descriptions = ();

    &traverseDir ($curr_dir, \@organisms, \@data_sources, \@versions, \@descriptions);
  }

# Usage: traverseDir (currentDir, Organisms, DataSource, Version, Description)
sub traverseDir 
  {
    my $curr_dir     = @_[0];
    my $organisms    = @_[1];
    my $data_sources = @_[2];
    my $versions     = @_[3];
    my $description  = @_[4];

#    print ("\n=========================================\nTraversing on: $curr_dir\n");
#    print "@$organisms\n";
#    print "@$data_sources\n";
#    print "@$versions\n";
#    print "@$description\n";

    # Search for a description of current dir
    my $match_desc = `grep '$curr_dir' $DESCRIPTION_LIST | cut -f2- -d':'`;
    push (@$description, $match_desc);

    # Traverse over children files
    my @paths_list = &getAllFiles($curr_dir);
    foreach my $path (@paths_list)
      {
	my @split_path = split (/\//, $path);
	my $file = @split_path[$#split_path];

	if ((-d $path) && ($file ne ".") && ($file ne ".."))
	  {
	    if ($Organisms{$file}) # File is an organism
	      {
		push(@$organisms, $file);
		&traverseDir ($path, \@$organisms, \@$data_sources, \@$versions, \@$description);
		pop(@$organisms);
	      }
	    elsif ($DataSources{$file}) # File is a data source
	      {
		push(@$data_sources, $file);		
		&traverseDir ($path, \@$organisms, \@$data_sources, \@$versions, \@$description);
		pop(@$data_sources);
	      }
	    elsif ($Versions{$file}) # File is a known version
	      {
		push(@$versions, $file);
		&traverseDir ($path, \@$organisms, \@$data_sources, \@$versions, \@$description);
		pop(@$versions);
	      }
	    elsif (not($file =~ /Local/) && not($file =~ /Remote/)) # Continue traversing
	      {
		&traverseDir ($path, \@$organisms, \@$data_sources, \@$versions, \@$description);
	      }
	  }
	elsif ($file =~ /\.(tab|lst|nbhd|fas|chr|aln|gxp|gxt|gxw|gxa)$/) # Reached the dataset, create or append data to the file
	  {
	    my $file_ref;
	    my $output_file = &getPathPrefix($path)."desc.txt";

	    if (-e $output_file)
	      {
		open (OUTFILE, ">>".$output_file) or die ("Failed to open file:'$output_file'\n");
		$file_ref = \*OUTFILE;
	      }
	    else
	      {
		open (OUTFILE, ">".$output_file) or die ("Failed to open file:'$output_file'\n");
		$file_ref = \*OUTFILE;

		print $file_ref ("Description: @$description\n");
		print $file_ref ("Organism:    @$organisms\n");
		print $file_ref ("Data Source: @$data_sources\n");
		print $file_ref ("Versions:    @$versions\n");
		
	      }

	    print $file_ref ("File: $file\n");	    
	    close ($file_ref);
	  }
      }
  }

# Usage: output_hash = FileList2Hash (file_name);
sub FileList2Hash 
{

  open (INPUT_FILE, @_[0]) or die("Could not open file '@_[0]'.\n");
  my $file_ref = \*INPUT_FILE;

  my %res;

  while (<$file_ref>)
    {
      chop;
      $res{$_} = 1;
    }

  return %res;
}

__DATA__

create_data_desc.pl 

   Creates or updates the description files of the datasets (desc.txt). It should be executed at $GENIE_HOME/Data directory.
   This script goal was to create the first version of the description files, if needed to be executed again, its input files
   need to be checked and updated (look at the script body).





