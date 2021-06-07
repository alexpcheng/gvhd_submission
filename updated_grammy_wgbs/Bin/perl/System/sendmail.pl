#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

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
my $to = get_arg("t", 0, \%args);
my $subject = get_arg("s", "", \%args);
my $message = get_arg("m", "", \%args);
my $file_attachment = get_arg("f", "", \%args);

if (!$to){die "use -t to specify subject!\n"}
if ($message eq ""){
  while(<$file_ref>){
    $message.=$_;
  }
}

my $sendmail = '/usr/lib/sendmail';
open(MAIL, "|$sendmail -oi -t");
print MAIL "To: $to\n";
print MAIL "Subject: $subject\n\n";
print MAIL "$message\n";
close(MAIL);


__DATA__

sendmail.pl

sends an email

  -t:   to (recipient email address).
  -s:   subject (optional).
  -m:   message. if not specified, reads message from standard input or specified file.

