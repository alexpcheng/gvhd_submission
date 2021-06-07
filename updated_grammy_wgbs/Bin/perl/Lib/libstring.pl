use strict;

# Copy the string
sub replicate # ($str, $num)
{
   my ($str, $num) = @_;
   my $replicates;
   for(my $i = 0; $i < $num; $i++)
   {
      $replicates .= $str;
   }
   return $replicates;
}

sub remExtraSpaces
{
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  $string =~ s/(\s)\s+//g;
  return $string;
}

1
