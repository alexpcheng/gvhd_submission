#!/usr/bin/perl

while (<STDIN>)
{
  chop;
  if(/\S/)
  {
    ($name,$seq,$qual) = split("\t");
    print "@" . "$name\n$seq\n+\n$qual\n";
  }
}

