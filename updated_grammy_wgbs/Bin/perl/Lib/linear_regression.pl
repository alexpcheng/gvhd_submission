#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
#require "$ENV{PERL_HOME}/Lib/format_number.pl";
#require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $matrix_file = $ARGV[0];
my $matrix_file_ref;

if (length($matrix_file) < 1 or $matrix_file =~ /^-/) 
{
  $matrix_file_ref = \*STDIN;
}
else
{
  open(MATRIX_FILE, $matrix_file) or die("Could not open the tab-delimited matrix file '$matrix_file'.\n");
  $matrix_file_ref = \*MATRIX_FILE;
}

my $vector_file = get_arg("b", "", \%args);
my $vector_file2 = get_arg("b2", "", \%args);
my $vector_file_ref;
my $vector_file_ref2;

if (length($vector_file) < 1 )
{
  die("The b vector is not specified.\n");
}
else
{
  open(VECTOR_FILE, $vector_file) or die("Could not open the tab-delimited vector file '$vector_file'.\n");
  $vector_file_ref = \*VECTOR_FILE;
}

my $output_residuals = get_arg("res", 0, \%args);
my $add_constant_column = get_arg("w0", 0, \%args);
my $non_negative_solution = get_arg("nneg", 0, \%args);

if ($output_residuals == 0 and length($vector_file2) > 0)
{
   print STDERR "-b2 must be specified together with -res parameter.\n";
   exit 1;
}

if (length($vector_file2) > 0)
{
  open(VECTOR_FILE2, $vector_file2) or die("Could not open the tab-delimited vector file '$vector_file2'.\n");
  $vector_file_ref2 = \*VECTOR_FILE2;
}

my $r = int(rand(1000000));
my $matrix_for_matlab_file_name = "tmp_linear_regression_mat_" . "$r";
my $vector_for_matlab_file_name = "tmp_linear_regression_vec_" . "$r";
my $vector2_for_matlab_file_name = "tmp_linear_regression_vec2_" . "$r";
my $result_file_name = "tmp_linear_regression_res_" . "$r";
open(MATRIX_FOR_MATLAB, ">$matrix_for_matlab_file_name") or die("Could not open a temporary file for writing: '$matrix_for_matlab_file_name'.\n");
open(VECTOR_FOR_MATLAB, ">$vector_for_matlab_file_name") or die("Could not open a temporary file for writing: '$vector_for_matlab_file_name'.\n");
open(VECTOR2_FOR_MATLAB, ">$vector2_for_matlab_file_name") or die("Could not open a temporary file for writing: '$vector2_for_matlab_file_name'.\n");
open(RESULT, ">$result_file_name") or die("Could not open a temporary file for writing: '$result_file_name'.\n");

my $tmp_row = <$matrix_file_ref>;
chomp($tmp_row);
my @r = split(/\t/,$tmp_row);

if (! $output_residuals)
{
   if ($add_constant_column)
   {
      print RESULT "W0\n";
   }

   for (my $i=1; $i<@r; $i++)
   {
      print RESULT "$r[$i]\n";
   }
}

while($tmp_row = <$matrix_file_ref>)
{
  chomp($tmp_row);
  @r = split(/\t/,$tmp_row,2);
  if ($add_constant_column)
  {
     print MATRIX_FOR_MATLAB "1\t$r[1]\n";
  }
  else
  {
     print MATRIX_FOR_MATLAB "$r[1]\n";
  }

  if ($output_residuals)
  {
      print RESULT "$r[0]\n";
  }
}

$tmp_row = <$vector_file_ref>;
chomp($tmp_row);
@r = split(/\t/,$tmp_row,2);

while($tmp_row = <$vector_file_ref>)
{
  chomp($tmp_row);
  @r = split(/\t/,$tmp_row,2);
  print VECTOR_FOR_MATLAB "$r[1]\n";
}

$tmp_row = <$vector_file_ref2>;
chomp($tmp_row);
@r = split(/\t/,$tmp_row,2);

while($tmp_row = <$vector_file_ref2>)
{
  chomp($tmp_row);
  @r = split(/\t/,$tmp_row,2);
  print VECTOR2_FOR_MATLAB "$r[1]\n";
}

close(MATRIX_FOR_MATLAB);
close(VECTOR_FOR_MATLAB);
close(VECTOR2_FOR_MATLAB);
close(RESULT);

my $arg_matrix_file_name = "$matrix_for_matlab_file_name";
my $arg_vector_file_name = "$vector_for_matlab_file_name";
my $arg_vector2_file_name = "$vector2_for_matlab_file_name";
my $arg_output_file_name = "tmp_linear_regression_out" . "$r";
my $arg_nneg = $non_negative_solution;
my $arg_residules = $output_residuals;

my $params = "(\'$arg_matrix_file_name\',\'$arg_vector_file_name\',".(length($vector_file2) > 0 ? "\'$arg_vector2_file_name\'" : "0").",\'$arg_output_file_name\',$arg_nneg,$arg_residules)";

my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
my $mfile = "linear_regression";
my $matlabPath = "matlab";

my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";

print STDERR "Calling Matlab with: $command\n";

system ($command) == 0 || die "Failed to run Matlab\n";

my $str = "";
if ($output_residuals)
{
   $str = `paste $result_file_name $arg_output_file_name | cap.pl "","Residules"`;
}
else
{
   $str = `paste $result_file_name $arg_output_file_name | cap.pl "","X"`;
}

my @lines = split(/\n/,$str);
for(my $i=0; $i < @lines; $i++)
{
  my $line = $lines[$i];
  chomp($line);
  print STDOUT "$line\n";
}

system ("rm -f tmp_linear_regression*$r");

__DATA__

Syntax:
    
    linear_regression.pl <A.tab> -b <b.tab>

Description:

    Given a matrix A (tab file with 1 row header and 1 column header), and a vector b
    (same format as A, given as a column), calculate the least square problem:

    solution = argmin_{x}{|A*x-b|} which is the closets solution in L2 norm for A*x=b.

    Can extend matrix A by a constant column to allow a constant coefficient in the linear model.

    Can constrain to a non-negative solution, i.e. x >= 0.

    Can output the residule vector b-A*x (instead of x).

    IMPORTANT! assumes a full matrix, with no empty entries.

Output: 
    
    A tab delimited file of the solution x, with row header "X" and column header 
    by the row header of input matrix A.

Flags:
    
    -b <b.tab>  The column vector b.

    -w0         Add a constant coefficient to the linear model as a first column in A (default: do not add)

    -nneg       Constrain for a non negative solution, i.e. x >= 0 (default: do not constrain)

    -res        Output the residule vector b-A*x (default: output x)

    -b2 <file>  Column vector like b, when -res specified, Output the residule vector b2-A*x
