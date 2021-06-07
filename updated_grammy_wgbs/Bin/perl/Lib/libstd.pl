use strict;

# Possibly not necessary
sub myJoin
{
   my $delim  = shift @_;
   my $pad    = '';
   for(my $i = $#_; (($i >= 0) and (length($_[$i]) == 0)); $i--)
   {
      $pad .= $delim;
   }
   my $joined = join($delim, @_) . $pad;
   return $joined;
}


# Possibly not necessary...
sub capEnds # ($delim, $str)
{
   my $delim = $_[0];

   if(not(defined($delim)))
   {
      $delim = "\t";
   }

   if(not(defined($_[1])))
   {
      $_ = '{}' . $delim . $_ . $delim . '{}';
   }
   else
   {
      $_[1] = '{}' . $delim . $_ . $delim . '{}';
   }
}

sub decapEnds # ($delim, $str)
{
   my $delim = $_[0];

   if(not(defined($delim)))
   {
      $delim = "\t";
   }

   my @tuple;
   if(not(defined($_[1])))
     { @tuple = &mySplit($delim, $_); }
   else
     { @tuple = &mySplit($delim, $_[1]); }

   pop(@tuple);
   shift(@tuple);

   if(not(defined($_[1])))
     { $_ = join($delim,@tuple); }
   else
     { $_[1] = join($delim,@tuple); }
}

# Possibly not necessary...
sub myChop
{
   if($#_ >= 0)
     { $_[0] =~ s/[\n]$//; }
   else
     { s/[\n]$//; }
}


# Does not clobber the trailing blank entries like split() does.
sub mySplit
{
   my ($delim, $str, $num) = @_;

   if(not(defined($str)))
   {
      $str = $_;
   }

   # Stick a dummy on the beginning and end of the string.
   $str = '{}' . $delim . $str . $delim . '{}';

   my @tuple = split($delim, $str);

   # Remove the dummy.
   pop(@tuple);
   shift(@tuple);

   return @tuple;
}

# Returns a permutation of the list passed in as an argument.
sub permute
{
  my(@list) = @_;
  my(@p);
  my($i) = 0;

  while(@list)
  {
    my $r = int(($#list+1)*rand());
    $p[$i] = splice(@list, $r, 1);
    $i++;
  }

  return @p;
}

sub unlexifyNumber
{
  my $oldNum = shift @_;
  my $newNum = $oldNum;

  $newNum =~ s/([^0-9])0+([1-9])/\1\2/g;

  return $newNum;
}

1
