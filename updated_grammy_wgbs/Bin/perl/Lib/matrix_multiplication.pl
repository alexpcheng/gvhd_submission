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

my $matrix_file1 = get_arg("A", "", \%args);
my $matrix_file2 = get_arg("B", "", \%args);

my $r = int(rand(1000000));
my $output_file = "tmp_matrix_multiplication_$r.out";

my $params = "(\'$matrix_file1\',\'$matrix_file2\',\'$output_file\')";

my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
my $mfile = "matrix_multiplication";
my $matlabPath = "matlab";

my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";

print STDERR "Calling Matlab with: $command\n";

system ($command) == 0 || die "Failed to run Matlab\n";

open (OUTPUT_FILE, "<$output_file");
while (<OUTPUT_FILE>)
{
   chop;
   print STDOUT "$_\n";
}

system ("rm -f $output_file");

__DATA__

Syntax:
    
    matrix_multiplication.pl -A <A.tab> -B <B.tab>

Description:

    Multiply Matrices: prints A * B
