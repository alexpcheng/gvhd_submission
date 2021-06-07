#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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


my $separator_prefix = get_arg("separator_prefix", "", \%args);
my $separator_num_in_file = get_arg("separator_num_in_file", 1, \%args);
my $file_prefix = get_arg("file_prefix", "", \%args);
my $file_suffix = get_arg("file_suffix", "", \%args);
my $file_prefix_in_file = get_arg("file_prefix_in_file", "", \%args);
my $file_suffix_in_file = get_arg("file_suffix_in_file", "", \%args);
my $out_file_name_prefix = get_arg("out_file_name_prefix", "split_by_separator", \%args);
my $out_file_name_suffix = get_arg("out_file_name_suffix", ".m", \%args);
my $str_in_file_prefix_suffix_to_replace_by_file_num = get_arg("str_in_file_prefix_suffix_to_replace_by_file_num", "FILE_NUM", \%args);

print STDERR "file_prefix:$file_prefix\n";

 
my $cur_out_file_num = 1;

open ("OUTFILE", ">${out_file_name_prefix}_split${cur_out_file_num}${out_file_name_suffix}");

my $file_fix_prefix;
my $file_fix_suffix;

$file_fix_prefix = $file_prefix;
$file_fix_prefix =~ s/$str_in_file_prefix_suffix_to_replace_by_file_num/$cur_out_file_num/g;

#print STDERR "$str_in_file_prefix_suffix_to_replace_by_file_num\n";
#print STDERR "$cur_out_file_num\n";
#print STDERR "$file_fix_prefix\n";

print OUTFILE "${file_fix_prefix}\n";
&AppendFile(*OUTFILE, $file_prefix_in_file, $str_in_file_prefix_suffix_to_replace_by_file_num, $cur_out_file_num);

my $cur_separator_num = 0;


while(<$file_ref>)
{
  chop;
  
  my $line = $_;
  
  
  if(/^$separator_prefix/)
  {
	$cur_separator_num = $cur_separator_num +1;
  }
  
  
  if ($cur_separator_num >= $separator_num_in_file)
  {
	$file_fix_suffix = $file_suffix;
	$file_fix_suffix =~ s/$str_in_file_prefix_suffix_to_replace_by_file_num/$cur_out_file_num/g;
	print OUTFILE "${file_fix_suffix}\n";
	
	&AppendFile(*OUTFILE, $file_suffix_in_file, $str_in_file_prefix_suffix_to_replace_by_file_num, $cur_out_file_num);
	close OUTFILE;
	
	$cur_separator_num = 0;
	$cur_out_file_num = $cur_out_file_num+1;
	
	open ("OUTFILE", ">${out_file_name_prefix}_split${cur_out_file_num}${out_file_name_suffix}");
	
	$file_fix_prefix = $file_prefix;
	$file_fix_prefix =~ s/$str_in_file_prefix_suffix_to_replace_by_file_num/$cur_out_file_num/g;
	
	print OUTFILE "${file_fix_prefix}\n";
	&AppendFile(*OUTFILE, $file_prefix_in_file, $str_in_file_prefix_suffix_to_replace_by_file_num, $cur_out_file_num);
  }
  print OUTFILE "${line}\n";
}

$file_fix_suffix = $file_suffix;
$file_fix_suffix =~ s/$str_in_file_prefix_suffix_to_replace_by_file_num/$cur_out_file_num/g;
print OUTFILE "${file_fix_suffix}\n";
&AppendFile(*OUTFILE, $file_suffix_in_file, $str_in_file_prefix_suffix_to_replace_by_file_num, $cur_out_file_num);
close OUTFILE;




# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub AppendFile
{

	my ($OUT_FILE, $in_file_name, $str_in_file_prefix_suffix_to_replace_by_file_num, $cur_out_file_num) = @_;
	
	if ($file_prefix_in_file eq "")
	{
		return;
	}
	
	print STDERR "--------------------------------- start appending file  -------------------------------------------------------------------------\n";


	open(APPENDED_FILE, "<$in_file_name") or die "AppendFile could not open in file: $in_file_name\n";

	
	my $line;
	while (<APPENDED_FILE>)
	{
	    $line = $_;
		$line =~ s/$str_in_file_prefix_suffix_to_replace_by_file_num/$cur_out_file_num/g;
		
		print $OUT_FILE $line;
	}
		
	close(APPENDED_FILE);
	
	print STDERR "--------------------------------- end appending file  -------------------------------------------------------------------------\n";

}


__DATA__

split_file_by_separator_line.pl <file>

   Splits a file by a given separator line

   -separator_prefix	<string>  seperator line prefix

   -separator_num_in_file  <#>	 how many separator lines to include in each file
   
   -file_prefix <string> string added at the start of each file
   
   -file_suffix <string> string added at the end of each file
   
   -file_prefix_in_file <string> a name of a file that is appended at the start of each file
   
   -file_suffix_in_file <string> a name of a file that is appended at the end of each file
   
   -out_file_name_prefix <string> the name of the out files will be <out_file_prefix>_split#out_file_name_suffix defult split_by_separator
   
   -out_file_name_suffix <string> the name of the out files will be <out_file_prefix>_split#out_file_name_suffix defult split_by_separator
    
   -str_in_file_prefix_suffix_to_replace_by_file_num <string>  that way you can add action specific to files defualt FILE_NUM

   
