#! /usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";

# consts
my $FASTA_SUFFIX = ".fa";
my $ALIGNMENT_SUFFIX = ".alignment";
my $LABELS_SUFFIX = ".labels";
my $CROSS_VALIDATION_MID_DIR_STR = "cross_validation";
my $XML_SUFFIX = ".map";
#my $ALIGNMENT_NAME_TRAIN = "align_train";
#my $ALIGNMENT_NAME_TEST  = "align_test";

#train 
my $ALL_DATA_NAME_PREFIX                       = "TrainDataAll";
my $ALL_OUTPUT_FILE_PREFIX_PREFIX              = "train_data_all";
my $TRAIN_DATA_NAME_PREFIX                     = "TrainData";
my $TRAIN_OUTPUT_FILE_PREFIX_PREFIX            = "train_data";
my $TRAIN_POSITIVE_DATA_NAME_PREFIX            = "TrainDataPositive";
my $TRAIN_POSITIVE_OUTPUT_FILE_PREFIX_PREFIX   = "train_data_positive";
my $TEST_POSITIVE_DATA_NAME_PREFIX             = "TestDataPositive";
my $TEST_POSITIVE_OUTPUT_FILE_PREFIX_PREFIX    = "test_data_positive";
my $TEST_DATA_NAME_PREFIX                      = "TestData";
my $TEST_OUTPUT_FILE_PREFIX_PREFIX             = "test_data";



my $FASTA_NUM_LINES_OF_HEADER = 0;
my $ALIGNMENT_NUM_LINES_OF_HEADER = 1;
my $LABELS_NUM_LINES_OF_HEADER = 1;

my $FASTA_NUM_LINES_OF_FOOTER = 0;
my $ALIGNMENT_NUM_LINES_OF_FOOTER = 1;
my $LABELS_NUM_LINES_OF_FOOTER = 0;

my $FASTA_NUM_LINES_OF_ITEM = 2;
my $ALIGNMENT_NUM_LINES_OF_ITEM = 1;
my $LABELS_NUM_LINES_OF_ITEM = 1;

#----------------------------------------------------------------
# replace_alignment_name_in_alignment_file_header
#----------------------------------------------------------------
sub replace_alignment_name_in_alignment_file_header
{ 
  my ($header_line, $alignment_name) = @_;
  print "before fix alignment header:$header_line";
  $header_line =~ s/SequenceAlignment Name=".*"/SequenceAlignment Name="$alignment_name" Type="GaplessAlignment"/;

  print "fixed alignment header:$header_line|SequenceAlignment Name=\"Takiya03Align\"\n";
  return $header_line;
}
#----------------------------------------------------------------
# create_train_and_test_file_for_cross_validation_set
#----------------------------------------------------------------
sub create_train_and_test_file_for_cross_validation_set
{
  my ($infile_prefix,
      $outfile_directory_name, $file_suffix,
      $num_lines_of_header,$num_lines_of_item,$num_lines_of_footer,
      $to_which_group_record_belong_ptr,$group_num,$background_infile_prefix,$background_records_num,
	  $alignment_name_train,$alignment_name_test) = @_;
	  
  print "create_train_and_test_file_for_cross_validation_set:
	  infile_prefix=$infile_prefix,
      outfile_directory_name=$outfile_directory_name, file_suffix=$file_suffix,
      num_lines_of_header=$num_lines_of_header,num_lines_of_item=$num_lines_of_item,num_lines_of_footer=$num_lines_of_footer,
      to_which_group_record_belong_ptr=$to_which_group_record_belong_ptr,group_num=$group_num,background_infile_prefix=$background_infile_prefix,background_records_num=$background_records_num,
	  alignment_name_train=$alignment_name_train,alignment_name_test=$alignment_name_test\n\n";
  
  my @to_which_group_record_belong = @$to_which_group_record_belong_ptr;

  my $in_file_name = $infile_prefix . $file_suffix;
  
  my $out_file_name_train;
  my $out_file_name_test;
  if ($background_records_num > 0)
  {
	$out_file_name_train = $outfile_directory_name . "/" . $TRAIN_OUTPUT_FILE_PREFIX_PREFIX . $file_suffix;
	$out_file_name_test  = $outfile_directory_name . "/" . $TEST_OUTPUT_FILE_PREFIX_PREFIX  . $file_suffix;
  }
  else
  {
    $out_file_name_train = $outfile_directory_name . "/" . $TRAIN_POSITIVE_OUTPUT_FILE_PREFIX_PREFIX . $file_suffix;
	$out_file_name_test  = $outfile_directory_name . "/" . $TEST_POSITIVE_OUTPUT_FILE_PREFIX_PREFIX  . $file_suffix;
  }
  open(INFILE, "<$in_file_name") or die "could not open in file: $in_file_name\n";
  open(OUTFILE_TRAIN, ">$out_file_name_train") or die "could not open train out file: $out_file_name_train\n";
  open(OUTFILE_TEST, ">$out_file_name_test") or die "could not open test out file: $out_file_name_test\n";

  if ($background_infile_prefix ne "")
  {
	open(BACKGROUND_INFILE, "<$background_infile_prefix$file_suffix") or die "could not open in file: $background_infile_prefix$file_suffix\n";
  }
  # copying header
  my $line = "";
  my $background_line = "";
  for (my $i = 0; $i < $num_lines_of_header; $i++)
  {
    $line .= <INFILE>;
	
	if ($background_infile_prefix ne "")
	  {
		$background_line .= <BACKGROUND_INFILE>;
	  }
  }

  if ($line ne "")
  {
    # patch for alignment - need to change the name in the header (same like in xml)
    if ($file_suffix eq $ALIGNMENT_SUFFIX)
    {
      my $train_header_line = &replace_alignment_name_in_alignment_file_header($line, $alignment_name_train);
      my $test_header_line  = &replace_alignment_name_in_alignment_file_header($line, $alignment_name_test);
      print OUTFILE_TRAIN $train_header_line ; 
      print OUTFILE_TEST $test_header_line;

    }
    else
    {
      print OUTFILE_TRAIN $line; 
      print OUTFILE_TEST $line;
    }
  }

  #sorting the items between test and train
  my $num_of_records = @to_which_group_record_belong;
  for (my $i = 0; $i < $num_of_records; ++$i)
  {
    my $cur_line = "";

    for (my $j = 0; $j < $num_lines_of_item; ++$j)
    {
      $cur_line .= <INFILE>;
    }

    #print "choosing train or test: $to_which_group_record_belong[$i], $group_num \n";
    if ($to_which_group_record_belong[$i] == $group_num)
    {
      #print "print to test: $cur_line";
      print OUTFILE_TEST $cur_line;
    }
    else
    {
      #print "print to train: $cur_line";
      print OUTFILE_TRAIN $cur_line;
    }
  }
  
  # concat background
  if ($background_infile_prefix ne "")
  {
	  $background_line = "";
	  for (my $i = 0; $i < ($background_records_num*$num_lines_of_item); ++$i)
	  {
		$background_line = <BACKGROUND_INFILE>;
		print OUTFILE_TRAIN $background_line;
		print OUTFILE_TEST $background_line;
	  }
  }
  
  # copying footer
  $line = "";
  for (my $i = 0; $i < $num_lines_of_footer; $i++)
  {
    $line .= <INFILE>;
  }

  if ($line ne "")
  {
    print OUTFILE_TRAIN $line;
    print OUTFILE_TEST $line;
  }
  close(INFILE);
  close(OUTFILE_TRAIN);
  close(OUTFILE_TEST);
  
  if ($background_infile_prefix ne "")
  {
	close(BACKGROUND_INFILE);
  }

}
#----------------------------------------------------------------
# create_labeled_cross_validation_sets (parameters,main)
#----------------------------------------------------------------
sub create_labeled_cross_validation_sets
{
  my ($records_infile_prefix,  
      $num_cross_validation_groups, 
      $xml_prefix, $background_infile_prefix,
	  $out_dir_prefix,
	  $alignment_name_train_positive,$alignment_name_test_positive,
	  $alignment_name_train_all,$alignment_name_test_all) = @_;
  
  print "DEBUG:create_labeled_cross_validation_sets:
	records_infile_prefix=$records_infile_prefix, 
	num_cross_validation_groups=$num_cross_validation_groups, xml_prefix=$xml_prefix, background_infile_prefix=$background_infile_prefix,
	 out_dir_prefix=$out_dir_prefix,
	alignment_name_train_positive=$alignment_name_train_positive,alignment_name_test_positive=$alignment_name_test_positive,
	alignment_name_train_all=$alignment_name_train_all,alignment_name_test_all=$alignment_name_test_all\n";
  my $num_records = &GetNumLinesInFile($records_infile_prefix . $FASTA_SUFFIX  );

  
  
  ($num_records % 2 == 0) or die "fasta file:$records_infile_prefix, number of lines ($num_records) mudule 2 is not zero"; 
  $num_records /= 2;
  
  my $background_records_num = 0;
  if ($background_infile_prefix ne "")
  {
	$background_records_num = &GetNumLinesInFile($background_infile_prefix . $FASTA_SUFFIX  );
  }
  ($background_records_num % 2 == 0) or die "fasta file:$background_infile_prefix, number of lines ($num_records) mudule 2 is not zero"; 
  $background_records_num /= 2;
  
  my $max_records_per_cv_group = int($num_records / $num_cross_validation_groups) + 1;
  
  my @records_per_cv_group;
  my @to_which_group_record_belong;

  my @file_directory_names_per_cv_group;

  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
    $records_per_cv_group[$i] = 0;
  }
  
  
  my $mixing_constant = 100;
  
  my @rand_ind_vec;
  
  for (my $i = 0; $i < $num_records; $i++)
  {
	$rand_ind_vec[$i] = $i;
  }
  
  for (my $i = 0; $i < $num_records*$mixing_constant; $i++)
  {
	my $r_ind_1 = int rand ($num_records-1); # 0 .. ($num_records-1)
	my $r_ind_2 = int rand ($num_records-1); # 0 .. ($num_records-1)
	my $tmp_rand_ind = $rand_ind_vec[$r_ind_1];
	$rand_ind_vec[$r_ind_1] = $rand_ind_vec[$r_ind_2];
	$rand_ind_vec[$r_ind_2] = $tmp_rand_ind;
  }
  
  my $c = 0;
  for (my $i = 0; $i < $num_records; $i++)
  {
  
	$to_which_group_record_belong[$rand_ind_vec[$i]] = $c;
	$records_per_cv_group[$c]++;
	
	$c++;
	
	if ($c >= $num_cross_validation_groups)
	{
		$c = 0;
	}
  }

  # for (my $i = 0; $i < $num_records; $i++)
  # {
    # my $done = 0;

    # while(!$done)
    # {
      # my $r = int rand $num_cross_validation_groups; # 0 .. num_cross_validation_groups

      # if ($records_per_cv_group[$r] < $max_records_per_cv_group)
      # {
        # $records_per_cv_group[$r]++;
        # $to_which_group_record_belong[$i] = $r;
        # $done = 1;
      # }
    # }
    # print "random choose for record:$i, group:$to_which_group_record_belong[$i]\n";  
  # }


  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
    $file_directory_names_per_cv_group[$i] = $out_dir_prefix  . $i;
    if (!(&FileExists($file_directory_names_per_cv_group[$i])  && &FileIsADirectory($file_directory_names_per_cv_group[$i])))
    {
	  if (!( (-e $file_directory_names_per_cv_group[$i]) && (-d $file_directory_names_per_cv_group[$i]) ))
	  {
		mkdir($file_directory_names_per_cv_group[$i]);
	  }
      #print("created directory: ", $file_directory_names_per_cv_group[$i], "\n");
    }

  }

  for (my $i = 0; $i < $num_cross_validation_groups; $i++)
  {
    create_train_and_test_file_for_cross_validation_set($records_infile_prefix,
							$file_directory_names_per_cv_group[$i],$FASTA_SUFFIX,
							$FASTA_NUM_LINES_OF_HEADER,$FASTA_NUM_LINES_OF_ITEM,$FASTA_NUM_LINES_OF_FOOTER,
							\@to_which_group_record_belong,$i,"",0,$alignment_name_train_positive,$alignment_name_test_positive);
    create_train_and_test_file_for_cross_validation_set($records_infile_prefix,
							$file_directory_names_per_cv_group[$i],$ALIGNMENT_SUFFIX,
							$ALIGNMENT_NUM_LINES_OF_HEADER,$ALIGNMENT_NUM_LINES_OF_ITEM,$ALIGNMENT_NUM_LINES_OF_FOOTER,
							\@to_which_group_record_belong,$i,"",0,$alignment_name_train_positive,$alignment_name_test_positive);
    create_train_and_test_file_for_cross_validation_set($records_infile_prefix,
							$file_directory_names_per_cv_group[$i],$LABELS_SUFFIX,
							$LABELS_NUM_LINES_OF_HEADER,$LABELS_NUM_LINES_OF_ITEM,$LABELS_NUM_LINES_OF_FOOTER,
							\@to_which_group_record_belong,$i,"",0,$alignment_name_train_positive,$alignment_name_test_positive);
							
	if ($background_infile_prefix ne "")
	{
	    create_train_and_test_file_for_cross_validation_set($records_infile_prefix,
								$file_directory_names_per_cv_group[$i],$FASTA_SUFFIX,
								$FASTA_NUM_LINES_OF_HEADER,$FASTA_NUM_LINES_OF_ITEM,$FASTA_NUM_LINES_OF_FOOTER,
								\@to_which_group_record_belong,$i,$background_infile_prefix,$background_records_num,
								$alignment_name_train_all,$alignment_name_test_all);
	    create_train_and_test_file_for_cross_validation_set($records_infile_prefix,
								$file_directory_names_per_cv_group[$i],$ALIGNMENT_SUFFIX,
								$ALIGNMENT_NUM_LINES_OF_HEADER,$ALIGNMENT_NUM_LINES_OF_ITEM,$ALIGNMENT_NUM_LINES_OF_FOOTER,
								\@to_which_group_record_belong,$i,$background_infile_prefix,$background_records_num,
								$alignment_name_train_all,$alignment_name_test_all);
	    create_train_and_test_file_for_cross_validation_set($records_infile_prefix,								
								$file_directory_names_per_cv_group[$i],$LABELS_SUFFIX,
								$LABELS_NUM_LINES_OF_HEADER,$LABELS_NUM_LINES_OF_ITEM,$LABELS_NUM_LINES_OF_FOOTER,
								\@to_which_group_record_belong,$i,$background_infile_prefix,$background_records_num,
								$alignment_name_train_all,$alignment_name_test_all);
	}
	else
	{
		create_train_and_test_file_for_cross_validation_set($records_infile_prefix,
							$file_directory_names_per_cv_group[$i],$FASTA_SUFFIX,
							$FASTA_NUM_LINES_OF_HEADER,$FASTA_NUM_LINES_OF_ITEM,$FASTA_NUM_LINES_OF_FOOTER,
							\@to_which_group_record_belong,$i,"",1,$alignment_name_train_all,$alignment_name_test_all);
	    create_train_and_test_file_for_cross_validation_set($records_infile_prefix,
							$file_directory_names_per_cv_group[$i],$ALIGNMENT_SUFFIX,
							$ALIGNMENT_NUM_LINES_OF_HEADER,$ALIGNMENT_NUM_LINES_OF_ITEM,$ALIGNMENT_NUM_LINES_OF_FOOTER,
							\@to_which_group_record_belong,$i,"",1,$alignment_name_train_all,$alignment_name_test_all);
	    create_train_and_test_file_for_cross_validation_set($records_infile_prefix,
							$file_directory_names_per_cv_group[$i],$LABELS_SUFFIX,
							$LABELS_NUM_LINES_OF_HEADER,$LABELS_NUM_LINES_OF_ITEM,$LABELS_NUM_LINES_OF_FOOTER,
							\@to_which_group_record_belong,$i,"",1,$alignment_name_train_all,$alignment_name_test_all);
	
	}
	
    if ($xml_prefix ne "")
    {
      my $xml_file_name = $xml_prefix . $XML_SUFFIX;
      my $group_xml_file_name = "./" . $file_directory_names_per_cv_group[$i] . "/" . $xml_prefix . $XML_SUFFIX;
      if(FileExists($group_xml_file_name))
      {
	  DeleteFile($group_xml_file_name);
      }
      CopyFile($xml_file_name,$group_xml_file_name );
    }
  }
}


#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0 and $ARGV[0] ne "--help")
{
  my %args = load_args(\@ARGV);

  create_labeled_cross_validation_sets($ARGV[0],
				       get_arg("g", 5, \%args),
				       get_arg("x", "", \%args),
					   get_arg("b", "", \%args),
					   get_arg("od", $ARGV[0], \%args),
					   $ARGV[1],$ARGV[2],
					   $ARGV[3],$ARGV[4]);

  print "END make_labeled_cross_validation_sets\n\n";
}
else
{
  print "Usage: make_cross_labeled_validation_sets.pl <input_file_prefix>
													<alignment_name_train_positive> <alignment_name_test_positive>
													<alignment_name_train_all> <alignment_name_test_all> \n\n";
  print "      -g <cv number>:   number of cross validation groups to make (default 5)\n\n";
  print "      -x <template xml file name prefix>:   xml template file name prefix(prefix = file name without the .xml) (if non no xml files will be created)\n\n";
  print "      -b <background file name prefix>:   concatanate background file (prefix = file name without the .labels/.alignment/.fa)\n\n";
  print "      -od <output dir prefix>: prefix of the output directories (default is same as input file)\n";

# $alignment_name_train_positive,$alignment_name_test_positive,
#  $alignment_name_train_all,$alignment_name_test_all
  
  
}
