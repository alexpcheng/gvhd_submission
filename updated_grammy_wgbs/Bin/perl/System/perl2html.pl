#!/usr/bin/perl
##---------------------------------------------------------------------------##
##  File:
##	@(#) perl2html 1.1 97/10/15 12:50:48 @(#)
##  Author:
##	Earl Hood, ehood@medusa.acs.uci.edu
##  Description:
##	Program to convert Perl code into "pretty" HTML.
##---------------------------------------------------------------------------##
##    Copyright (C) 1997	Earl Hood, ehood@medusa.acs.uci.edu
##
##    This program is free software; you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation; either version 2 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program; if not, write to the Free Software
##    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
##    02111-1307, USA
##---------------------------------------------------------------------------##

package Perl2Html;

use Getopt::Long;

my $ColorComment;
my $ColorKeyword;
my @Keywords = qw(
    -A -B -C -M -O -R -S -T -W -X -b -c -d -e -f -g -k -l -o -p
    -r -s -t -u -w -x -z
    ARGV DATA ENV SIG STDERR STDIN STDOUT
    atan2
    bind binmode bless
    caller chdir chmod chomp chop chown chr chroot close closedir
    cmp connect continue cos crypt
    dbmclose dbmopen defined delete die do dump
    each else elsif endgrent endhostent endnetent endprotoent
    endpwent endservent eof eq eval exec exists exit exp
    fcntl fileno flock for foreach fork format formline
    ge getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname
    gethostent getlogin getnetbyaddr getnetbyname getnetent getpeername
    getpgrp getppid getpriority getprotobyname getprotobynumber
    getprotoent getpwent getpwnam getpwuid getservbyname getservbyport
    getservent getsockname getsockopt glob gmtime goto grep gt
    hex
    if
    import index int ioctl
    join
    keys kill
    last lc lcfirst le length link listen local localtime log lstat lt
    m map mkdir msgctl msgget msgrcv msgsnd my
    ne next no
    oct open opendir ord
    pack package pipe pop pos print printf push
    q qq quotemeta qw qx
    rand read readdir readlink recv redo ref rename require reset
    return reverse rewinddir rindex rmdir
    s scalar seek seekdir select semctl semget semop send setgrent
    sethostent setnetent setpgrp setpriority setprotoent setpwent
    setservent setsockopt shift shmctl shmget shmread shmwrite shutdown
    sin sleep socket socketpair sort splice split sprintf sqrt srand
    stat study sub substr symlink syscall sysopen sysread system
    syswrite
    tell telldir tie tied time times tr truncate
    uc ucfirst umask undef unless unlink unpack unshift untie until
    use utime
    values vec wait
    waitpid wantarray warn while write
    y
);
my %Keywords;
@Keywords{@Keywords} = (1) x scalar(@Keywords);

my %options;
my $ret = GetOptions(
    \%options,
    "keywordcolor=s",
    "commentcolor=s",
    "commentfont=s",
    "help"
);
if (!$ret or $options{"help"}) {
    print_usage();
    exit !$ret;
}

$ColorComment	= $options{"commentcolor"} || "#ff0000";
$ColorKeyword	= $options{"keywordcolor"} || "#0000ff";
$FontComment	= $options{"commentfont"}  || "#00ff00";

my($code, $comment);
print "<PRE>\n";
while (<>) {
    ($code, $comment) = split(/#/, $_, 2);
    if ($code ne '') {
	$code =~ s/(<|&|\b\w+\b|-\w\b)/highlight_keyword($1)/ge;
	print $code;
    }
    if ($comment ne '') {
	print qq(<FONT );
	print qq(FACE="$FontComment" )  if $FontComment;
	print qq(COLOR="$ColorComment"><I>),
	      '#', $comment,
	      qq(</I></FONT>);
    }
}
print "</PRE>\n";

sub highlight_keyword {
    my $word = shift;

    if ($word eq '<') {
	return "&lt;";
    }
    if ($word eq '&') {
	return "&amp;";
    }
    if ($Keywords{$word}) {
	return qq(<FONT COLOR="$ColorKeyword"><B>$word</B></FONT>);
    }
    $word;
}

sub print_usage {
    my $prog = "perl2html";
    print <<"EndOfUsage";
Usage: $prog [options] file.pl > file.html
Options:
  -commentcolor <color> : Color of comments (def: "#555500")
  -commentfont <font>   : Font of comments (no default)
  -help                 : This message
  -keywordcolor <color> : Color of Perl keywords (def: "#000055")
Description:
  $prog converts Perl source code into HTML.  Attempts are made
  to "pretty" up the code to make it more readable.  Perl keywords
  and comments are highlighted during the conversion.

EndOfUsage
}
