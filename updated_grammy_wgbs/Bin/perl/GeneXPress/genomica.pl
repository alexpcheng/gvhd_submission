#!/usr/bin/perl

use strict;
use File::Spec;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $JAR_FILE = "$ENV{DEVELOP_HOME}/Genomica/Genomica.jar";
my $SETTINGS = "$ENV{DEVELOP_HOME}/Genomica/genomica_settings.dat";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $max_mb = get_arg("m", 512, \%args);
my $gxp_file = get_arg("gxp", "", \%args);
my $jar_file = get_arg("jar", $JAR_FILE, \%args);
my $settings_file = get_arg("-settings", $SETTINGS, \%args);

my $abs_gxp = "";
my $abs_jar = File::Spec->rel2abs( $jar_file );
my $abs_settings = File::Spec->rel2abs( $settings_file );

if ($gxp_file)
{
   $abs_gxp = File::Spec->rel2abs( $gxp_file ) ;
}

chdir "$ENV{GENOMICA_HOME}/Release";

print "$ENV{JAVA_HOME}/bin/java -Xmx${max_mb}m -jar $abs_jar $abs_gxp $settings_file\n";
system ("$ENV{JAVA_HOME}/bin/java -Xmx${max_mb}m -jar $abs_jar $abs_gxp $settings_file");

__DATA__

genomica.pl

    Opens the Genomica application Creates vector file from a chr file. The vector file has the format 
	
        -gxp <str>:      Load <str> upon launch (Optional)
        -jar <str>:      Use <str> as the jar file instead the default jar: $JAR_FILE
        -m <num>:        Set Genomica maximum memory to <num> mb. 
        -settings <str>: Settings file to use (default: ${DEVELOP_HOME}/Genomica/genomica_settings.dat)


