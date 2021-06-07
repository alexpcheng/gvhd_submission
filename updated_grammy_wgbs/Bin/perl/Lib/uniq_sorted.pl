#!/usr/bin/perl

#use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $MAX_BUFFERED_LINES = 1000000;

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

my $source_key_str = get_arg("k", 0, \%args);
my $print_fields_str = get_arg("p", "", \%args);

my $split_to_files_field = get_arg("split_by_field", -1, \%args);
my $split_to_files_sub_field = get_arg("split_by_sub_field", -1, \%args);
my $split_to_files_sub_field_delim = get_arg("split_to_files_sub_field_delim", " ", \%args);

my $skip_num = get_arg("skip", 0, \%args);
my $n_occurs = get_arg("n", 1, \%args);

my $f_pos = get_arg("f_pos", "", \%args);
my $f_neg = get_arg("f_neg", "", \%args);

my $prefix = get_arg("prefix", "tmp_", \%args);
if ($prefix eq "1") { $prefix = ""}

my $suffix = get_arg("suffix", ".tab", \%args);
if ($suffix eq "1") { $suffix = ""}

my $append_mode = get_arg("append", ">", \%args);
if ($append_mode eq "1") { $append_mode = ">>"}

my @source_key = split(/\,/, $source_key_str);
my @print_key = split(/\,/, $print_fields_str);

my %sub_files_hash;
my %neg_sub_files_hash;
my %sub_files_print_counter_hash;
my %neg_sub_files_print_counter_hash;
my @print_buffers;
my @neg_print_buffers;
my $n_output_files = 0;
my $n_neg_output_files = 0;

if ($n_occurs >= $MAX_BUFFERED_LINES)
{
   print STDERR "Error: number of occurances considered as passing the filter (-n parameter) are bigger then the maximal buffered lines ($MAX_BUFFERED_LINES), exiting.\n";
   exit 1;
}

if ($split_to_files_field < 0)
{
   for (my $i = 0; $i < $skip_num; $i++) { my $line = <$file_ref>; print "$line"; }
}

if (length($f_pos) > 0 and $split_to_files_field < 0)
{
   open (POS_FILE, "${append_mode}$f_pos") or die "Failed to open file $f_pos for writing";
}

if (length($f_neg) > 0 and $split_to_files_field < 0)
{
   open (NEG_FILE, "${append_mode}$f_neg") or die "Failed to open file $f_neg for writing";
}


my $prev_key = "";
my $curr_str = "";
my $counter = 0;
my $print_counter = 0;

my $passed_num = 0;
my $scanned_num = 0;

while(<$file_ref>)
{
    chop;
    
    $scanned_num++;
    if ($scanned_num % 100000 == 0)
    {
       print STDERR "$passed_num / $scanned_num\n";
    }

    my @row = split(/\t/);
    
    my $key = &GetKey(\@row);

    if ($key eq $prev_key and $print_counter < $MAX_BUFFERED_LINES)
    {
       $curr_str .= "$_\n";
       $counter++;
       $print_counter++;
    }
    else
    {
       if ($counter == $n_occurs or $n_occurs == 0)
       {
	  $passed_num += $counter;
	  if ($split_to_files_field < 0)
	  {
	     if (length($f_pos) > 0)
	     {
		print POS_FILE "$curr_str";
	     }
	     else
	     {
		print "$curr_str";
	     }
	  }
	  else
	  {
	     &PrintToSubFile($curr_str, 1);
	  }
       }
       else
       {
	  if ($split_to_files_field < 0)
	  {
	     if (length($f_neg) > 0)
	     {
		print NEG_FILE "$curr_str";
	     }
	  }
	  else
	  {
	     &PrintToSubFile($curr_str, 0);
	  }
       }


       $counter = 1;
       $print_counter = 1;
       $curr_str = "$_\n";
       $prev_key = $key;
    }
}

if ($counter == $n_occurs or $n_occurs == 0)
{
   if ($split_to_files_field < 0)
   {
      if (length($f_pos) > 0)
      {
	 print POS_FILE "$curr_str";
      }
      else
      {
	 print "$curr_str";
      }
   }
   else
   {
      &PrintToSubFile($curr_str, 1);
   }
}
else
{
   if ($split_to_files_field < 0)
   {
      if (length($f_neg) > 0)
      {
	 print NEG_FILE "$curr_str";
      }
   }
   else
   {
      &PrintToSubFile($curr_str, 0);
   }
}

&FlashBuffers();

if ($split_to_files_field >= 0)
{
   my @keys = keys %sub_files_hash;
   foreach my $sub (@keys)
   {
      my $fh = "FILE".$sub;
      close $fh;
   }

   if (length($f_neg) > 0)
   {
      @keys = keys %neg_sub_files_hash;
      foreach my $sub (@keys)
      {
	 my $fh = "FILE".$sub."NEG";
	 close $fh;
      }
   }
}

sub GetKey (\@)
{
    my ($row_str) = @_;

    my @row = @{$row_str};

    my $res = $row[$source_key[0]];

    for (my $i = 1; $i < @source_key; $i++)
    {
      $res .= "\t$row[$source_key[$i]]";
    }

    return $res;
}

sub GetPrintStr (\@)
{
    my ($row_str) = @_;
    my $res;

    my @row = @{$row_str};

    if (length ($print_fields_str) == 0) 
    {
       $res = join ("\t", @row);
    } 
    else 
    {
       $res = $row[$print_key[0]];

       for (my $i = 1; $i < @print_key; $i++) 
       {
	  $res .= "\t$row[$print_key[$i]]";
       }
    }

    return $res;
}

sub PrintToSubFile ($,$)
{
   my @lines = split (/\n/, @_[0]);
   my $pos = @_[1];
   my $res = "";
   foreach my $line (@lines)
   {
      my @row = split (/\t/, $line);
      my $file_key = ($split_to_files_sub_field < 0) ? $row[$split_to_files_field] : (split ($split_to_files_sub_field_delim,$row[$split_to_files_field]))[$split_to_files_sub_field];

      if ($pos)
      {
	 if (! exists $sub_files_hash{$file_key})
	 {
	    $sub_files_hash{$file_key} = $n_output_files;

	    $sub_files_print_counter_hash{$sub_files_hash{$file_key}} = 0;
	    
	    push (@print_buffers, "");
	    if (length($f_pos) > 0)
	    {
	       open ("FILE".$file_key, "${append_mode}${prefix}${f_pos}_${file_key}${suffix}") or die("Could not open file ${prefix}${f_pos}_${file_key}${suffix}: $!\n"); 
	    }
	    else
	    {    	
	       open ("FILE".$file_key, "${append_mode}${prefix}${file_key}${suffix}") or die("Could not open file ${prefix}${file_key}${suffix}: $!\n"); 
	    }
	 }
	 else
	 {
	    $sub_files_print_counter_hash{$sub_files_hash{$file_key}} = $sub_files_print_counter_hash{$sub_files_hash{$file_key}} + 1;
	 }

	 $n_output_files++;
      }
      elsif (length($f_neg) > 0)
      {
	 if (! exists $neg_sub_files_hash{$file_key})
	 {
	    $neg_sub_files_hash{$file_key} = $n_neg_output_files;

	    $neg_sub_files_print_counter_hash{$neg_sub_files_hash{$file_key}} = 0;
	    
	    push (@neg_print_buffers, "");

	    open ("FILE".$file_key."NEG", "${append_mode}${prefix}${f_neg}_${file_key}${suffix}") or die("Could not open file ${prefix}${f_neg}_${file_key}${suffix}: $!\n"); 

	 }
	 else
	 {
	    $neg_sub_files_print_counter_hash{$neg_sub_files_hash{$file_key}} = $neg_sub_files_print_counter_hash{$neg_sub_files_hash{$file_key}} + 1;
	 }

	 $n_neg_output_files++;
      }


      if ($pos)
      {
	 if ($sub_files_print_counter_hash{$sub_files_hash{$file_key}} < 150)
	 {
	    $print_buffers[$sub_files_hash{$file_key}] .= &GetPrintStr(\@row) ."\n";
	 }
	 else
	 {
	    $print_buffers[$sub_files_hash{$file_key}] .= &GetPrintStr(\@row) ."\n";
	    my $fh = "FILE".$file_key;

	    print $fh $print_buffers[$sub_files_hash{$file_key}];
	    $print_buffers[$sub_files_hash{$file_key}] = "";
	    $sub_files_print_counter_hash{$sub_files_hash{$file_key}} = 0;
	 }
      }
      elsif (length($f_neg) > 0)
      {
	 if ($neg_sub_files_print_counter_hash{$neg_sub_files_hash{$file_key}} < 150)
	 {
	    $neg_print_buffers[$neg_sub_files_hash{$file_key}] .= &GetPrintStr(\@row) ."\n";
	 }
	 else
	 {
	    $neg_print_buffers[$neg_sub_files_hash{$file_key}] .= &GetPrintStr(\@row) ."\n";
	    my $fh = "FILE".$file_key."NEG";

	    print $fh $neg_print_buffers[$neg_sub_files_hash{$file_key}];
	    $neg_print_buffers[$neg_sub_files_hash{$file_key}] = "";
	    $neg_sub_files_print_counter_hash{$neg_sub_files_hash{$file_key}} = 0;
	 }
      }
   }
}

sub FlashBuffers
{
   foreach my $file_key (keys %sub_files_hash)
   {
      my $fh = "FILE".$file_key;
      print $fh $print_buffers[$sub_files_hash{$file_key}];
      close $fh;
   }

   if (length($f_neg) > 0)
   {
      foreach my $file_key (keys %neg_sub_files_hash)
      {
	 my $fh = "FILE".$file_key."NEG";
	 print $fh $neg_print_buffers[$neg_sub_files_hash{$file_key}];
	 close $fh;
      }
   }
}

__DATA__

uniq_sorted.pl <source file>

   "Uniquify" rows in <source file> that have the same key (see -k) and which appear a certain number of times (see -n)

   -k <num range>:    Columns range of the key (default is 0)
                      NOTE: an index of multiple keys may be specified with commas (e.g., -k 1,4,5)
   -n <num>:          Print rows which their key appears <NUM> times (if <num> equals 0, print all the rows - usufull with -split_by_field option)
   -skip <num>:       Skip num rows in the source file and just print them (default: 0)

   -p <num range>:    Columns range to print (default is all)

   -split_by_field <num>:                   Print output to files splitted by field <num> (default: print to STDOUT);
   -split_by_sub_field <num>:               Use sub-field of the -split_by_field as the file splitter.
   -split_to_files_sub_field_delim <str>:   Delimiter to use on -split_by_field to get -split_by_sub_field (default: " ")

   -f_pos <str>:      Output the rows that pass the filter into file named <str>. If -split_by_field was supplied, <str> is used as the prefix of the output files.
   -f_neg <str>:      Output the rows that do not pass the filter into file named <str>. If -split_by_field was supplied, <str> is used as the prefix of the output files.

   -prefix <str>:     Prefix of the generated files (default: tmp_)
   -suffix <str>:     Suffix of the generated files (default: .tab)
   
   -append:           Open all files for appending (default: open for write, overwriting existing files)

   
   
