#!/usr/bin/perl
# The Missing Textutils, Ondrej Bojar, obo@cuni.cz
# http://www.cuni.cz/~obo/textutils
#
# 'see' is nearly equivalent to "sort | uniq -c". Nearly, because some 'uniq's
# tend to use space instead of tab as the delimiter.
#
# $Id: see.pl,v 1.1 2006/05/23 09:52:05 kertesz Exp $
#


while (<>) {
  $cnt{$_} ++;
}

foreach my $k ( sort {$cnt{$b} <=> $cnt{$a}} keys %cnt) {
  print "$cnt{$k}\t$k";
}
