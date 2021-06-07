#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

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

my $last_row = get_arg("l", "2", \%args);
my $add_str = get_arg("s", "", \%args);
my $make_uniq = get_arg("u", "0", \%args);
my $delim = get_arg("d", " ", \%args);
my $skip = get_arg("skip", "0", \%args);

my $line = 1;
my $in_zone = 0;
my $col_count = 1;
my $max_header_cols = 0;
my @headers;

while(<$file_ref>)
{
  chop;

  my @row = split (/\t/);

  if ($line == 1)
  {
     $in_zone = 1;
     @headers = &concat_row (\@headers, \@row, $delim);
  }
  elsif ($line == $last_row)
  {
     $in_zone = 0;

     @headers = &concat_row (\@headers, \@row, $delim);

     if (length($add_str) > 0)
     {
	for ($i = $skip; $i < @headers; $i++)
	{
	   $headers[$i] .= $delim.$add_str;
	}

     }

     if ($make_uniq > 0)
     {
	my $counter = 1;
	my @tmp_headers;
	for ($j = 0; $j < @headers; $j++)
	{
	   if ($j < $skip)
	   {
	      push (@tmp_headers, $headers[$j]);
	   }
	   else
	   {
	      if ($j > 0)
	      {
		 if ($headers[$j] ne $headers[$j-1])
		 {
		    $counter = 1;
		 }
	      }
	      push (@tmp_headers,  $headers[$j].$delim.$counter);
	      $counter++;
	   }
	}
	@headers = @tmp_headers;
     }
     
     my $joined = join ("\t", @headers);
     print "$joined\n";
  }
  elsif ($in_zone == 1)
  {
     @headers = &concat_row (\@headers, \@row, $delim);     
  }
  else
  {
     print "$_\n";
  }

  $line++;
}

sub concat_row
{
   my $base_tmp = @_[0];
   my $line_tmp = @_[1];
   my $delim    = @_[2];

   my @base = @$base_tmp;
   my @line = @$line_tmp;

   if ($#line > $#base)
   {
      my $last_val = $base[$#base];

      for ($i = $#base + 1; $i <= $#line; $i++)
      {
	 push (@base, $last_val);
      } 
   }

   my $last_val = "";
   for ($i = 0; $i < @line; $i++)
   {
      if (length($line[$i]) > 0)
      {
	 $last_val = $line[$i];
      }
      if (length($base[$i]) > 0)
      {
	 $base[$i] .= $delim;
      }
      $base[$i] .= $last_val;
   }   

   return @base;
}
__DATA__

combine_header_rows.pl <source file>

   Combine given header rows into a single row by concating the values of the columns. If one column is empty, the preceeding value in the same row will be concatinated.

   -l NUM:   Number of last row to combine (One based), default value is 2.
   -s STR:   Add STR to the end of each heading
   -u NUM:   Add a counter to each header to make it unique, starting from column NUM (default - 0, add no counter).
   -d DEL:   The delimiter to use in the concatination (default: ' ');
   -skip NUM: In case -s option is used, do not add STR to first NUM columns (default: 0).
