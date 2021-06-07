#!/usr/bin/perl
 
use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

$|=1;

my %args_sort = load_args(\@ARGV);

my $pipe = get_arg("p", "", \%args_sort);
my $buffer_size = get_arg("b", 1, \%args_sort);
my $sleep_time = get_arg("s", 0, \%args_sort);

if ($pipe ne ""){
  my $buffer="";
  while (read STDIN,$buffer,$buffer_size){
    print $buffer;
    select (undef,undef,undef,$sleep_time);
  }
}


__DATA__

comment.pl

Pipes data from stdin to stdout. Used to control pipe action and/or put comments in the middle
of long pipes within makefile subroutines. comment should go in quotes.

-p          indicates that the pipe should be maintained. If -p is not specified, the pipe
            will be broken.
-b <int>    buffer size. script waits for buffer to fill before flushing. (default 1)
-s <real>   sleep this amount of seconds after every buffer flush. (default 0)


Examples of usage for placing a comment:

  ...blah | comment.pl -p 'my comment' | etc...

Without a pipe just use:

  comment.pl 'my comment'



