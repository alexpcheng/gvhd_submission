#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{GENIE_HOME}/WWW/html/software/lib/group_site_utils.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $page_name = get_arg("page_name", "", \%args);
my $title     = get_arg("title", "", \%args);
my $page_type = get_arg("page_type", "inner", \%args);
my $nav_on    = get_arg("nav_on", "", \%args);
my $left_menu = get_arg("left_menu", "", \%args);
my $left_on = get_arg("left_on", "", \%args);
my $main_div  = get_arg("main_div", "main", \%args);
my $footer_class = get_arg("footer", "footer", \%args);
my $base_url  = get_arg("base_url", "genie.weizmann.ac.il", \%args);
my $onload_func = get_arg("onload_func", "", \%args);
my $conf = get_arg("conf_css", 0, \%args);


my $head_start = $conf ? get_conf_head_start() : get_head_start();
my $head_end   = $conf ? get_conf_head_end() : get_head_end();

my $nav_table  = $conf ? get_conf_nav_table() : get_nav_table();
my $main_table = get_main_table();
my $submenus   = get_submenus();
my $footer     = $conf ? get_conf_footer() : get_footer();
my $pubs_left_menu = get_left_menu("pubs");
my $nucleosomes06_left_menu = get_left_menu("nucleosomes06");
my $segnet08_left_menu = get_left_menu("segnet08");
my $wong08_left_menu = get_left_menu("wong08");
my $field08_left_menu = get_left_menu("field08");
my $nucleosomes08_left_menu = get_left_menu("nucleosomes08");
my $nucleosomes09_left_menu = get_left_menu("nucleosomes09");
my $nucleosomes10_left_menu = get_left_menu("nucleosomes10");
my $tf_nuc_model09_left_menu = get_left_menu("tf_nuc_model09");
my $linker09_left_menu = get_left_menu("linker09");
my $pars10_left_menu = get_left_menu("pars10");
my $nucleo_pred_left_menu = get_left_menu("nucleo_pred");
my $motifs07_left_menu = get_left_menu("motifs07");
my $genomica_web_left_menu = get_left_menu("genomica_web");
my $genomica_left_menu = get_left_menu("genomica");
my $imaging07_left_menu = get_left_menu("imaging07");
my $mir07_left_menu = get_left_menu("mir07");
my $fmm08_left_menu = get_left_menu("fmm08");
my $rnamotifs08_left_menu = get_left_menu("rnamotifs08");
my $conf_chromatin08_left_menu = get_left_menu("conf_chromatin08");
my $people_left_menu = get_left_menu("people");
my $cancer07_left_menu = get_left_menu("cancer07");

if (($page_type ne "home") and 
    ($page_type ne "inner") and
    ($page_type ne "gbrowse"))
{
   print STDERR "Error: Wrong page type ($page_type). Expects home/inner.\n";
   exit 1;
}

if (length($title) > 0)
{
   if ($conf)
   {
      $head_start =~ s/PAGE_TITLE/$title/g;
   }
   else
   {
      $head_start =~ s/PAGE_TITLE/: $title/g;
   }
}
else
{
   $head_start =~ s/PAGE_TITLE//g;
}

$head_end   =~ s/MAIN_DIV/${main_div}/g;
if (length($onload_func) > 0)
{
   $head_end =~ s/<body>/<body onload=\'${onload_func}();\'>/g;
}

if (length($left_on) == 0)
{
    $left_on = $page_name;
}

$footer     =~ s/FOOTER_CLASS/${footer_class}/g;

$main_table =~ s/BASE_FILE_NAME/${page_name}/g;
$submenus   =~ s/BASE_FILE_NAME/${page_name}/g;

$nav_table  =~ s/PAGE_TYPE/${page_type}/g;
$main_table =~ s/PAGE_TYPE/${page_type}/g;
$submenus   =~ s/PAGE_TYPE/${page_type}/g;

$submenus   =~ s/Menu\(\'${page_name}/Menu2\(\'${page_name}/g;

$nav_table  =~ s/BASE_URL/${base_url}/g;
$submenus   =~ s/BASE_URL/${base_url}/g;
$pubs_left_menu   =~ s/BASE_URL/${base_url}/g;
$genomica_web_left_menu   =~ s/BASE_URL/${base_url}/g;
$nucleosomes06_left_menu   =~ s/BASE_URL/${base_url}/g;
$genomica_left_menu   =~ s/BASE_URL/${base_url}/g;
$segnet08_left_menu   =~ s/BASE_URL/${base_url}/g;
$wong08_left_menu   =~ s/BASE_URL/${base_url}/g;
$field08_left_menu   =~ s/BASE_URL/${base_url}/g;
$nucleosomes08_left_menu   =~ s/BASE_URL/${base_url}/g;
$nucleosomes09_left_menu   =~ s/BASE_URL/${base_url}/g;
$nucleosomes10_left_menu   =~ s/BASE_URL/${base_url}/g;
$tf_nuc_model09_left_menu   =~ s/BASE_URL/${base_url}/g;
$linker09_left_menu   =~ s/BASE_URL/${base_url}/g;
$pars10_left_menu   =~ s/BASE_URL/${base_url}/g;
$nucleo_pred_left_menu   =~ s/BASE_URL/${base_url}/g;
$motifs07_left_menu   =~ s/BASE_URL/${base_url}/g;
$imaging07_left_menu   =~ s/BASE_URL/${base_url}/g;
$mir07_left_menu   =~ s/BASE_URL/${base_url}/g;
$fmm08_left_menu   =~ s/BASE_URL/${base_url}/g;
$rnamotifs08_left_menu   =~ s/BASE_URL/${base_url}/g;
$conf_chromatin08_left_menu   =~ s/BASE_URL/${base_url}/g;
$people_left_menu   =~ s/BASE_URL/${base_url}/g;
$cancer07_left_menu   =~ s/BASE_URL/${base_url}/g;

if (length($nav_on) > 0 and length($left_menu) == 0)
{
   $nav_table =~ s/${nav_on}_bt.gif\" onmouseover=\"src='\/images\/${nav_on}_bt_roll.gif'\" onmouseout=\"src='\/images\/${nav_on}_bt.gif'\"/${nav_on}_bt_on.gif\"/g;
}

if (length($left_menu) > 0)
{
   if (length($nav_on) > 0)
   {
      $nav_table =~ s/${nav_on}_bt.gif/${nav_on}_bt_on.gif/g;
      $nav_table =~ s/SubMenu\(\'${nav_on}/SubMenu2\(\'${nav_on}/g;
   }

   my $left_menu_str;
   if ($left_menu eq "publications") {$left_menu_str = $pubs_left_menu; }
   elsif ($left_menu eq "nucleosomes06") {$left_menu_str = $nucleosomes06_left_menu; }
   elsif ($left_menu eq "genomica") {$left_menu_str = $genomica_left_menu; }
   elsif ($left_menu eq "genomica_web") {$left_menu_str = $genomica_web_left_menu; }
   elsif ($left_menu eq "segnet08") {$left_menu_str = $segnet08_left_menu; }
   elsif ($left_menu eq "wong08") {$left_menu_str = $wong08_left_menu; }
   elsif ($left_menu eq "motifs07") {$left_menu_str = $motifs07_left_menu; }
   elsif ($left_menu eq "imaging07") {$left_menu_str = $imaging07_left_menu; }
   elsif ($left_menu eq "mir07") {$left_menu_str = $mir07_left_menu; }
   elsif ($left_menu eq "cancer07") {$left_menu_str = $cancer07_left_menu; }
   elsif ($left_menu eq "field08") {$left_menu_str = $field08_left_menu; }
   elsif ($left_menu eq "nucleosomes08") {$left_menu_str = $nucleosomes08_left_menu; }
   elsif ($left_menu eq "nucleosomes09") {$left_menu_str = $nucleosomes09_left_menu; }
   elsif ($left_menu eq "nucleosomes10") {$left_menu_str = $nucleosomes10_left_menu; }
   elsif ($left_menu eq "tf_nuc_model09") {$left_menu_str = $tf_nuc_model09_left_menu; }
   elsif ($left_menu eq "linker09") {$left_menu_str = $linker09_left_menu; }
   elsif ($left_menu eq "pars10") {$left_menu_str = $pars10_left_menu; }
   elsif ($left_menu eq "fmm08") {$left_menu_str = $fmm08_left_menu; }
   elsif ($left_menu eq "rnamotifs08") {$left_menu_str = $rnamotifs08_left_menu; }
   elsif ($left_menu eq "conf_chromatin08") {$left_menu_str = $conf_chromatin08_left_menu; }
   elsif ($left_menu eq "people") {$left_menu_str = $people_left_menu; }
   elsif ($left_menu eq "nucleo_pred") {$left_menu_str = $nucleo_pred_left_menu; }

   $left_menu_str =~ s/submenu\"><a href=\"(.*\/)${left_on}\.html/submenu-on\"><a href=\"${1}${left_on}\.html/g;
   $left_menu_str =~ s/submenu-dark\"><a href=\"(.*\/)${left_on}\.html/submenu-dark-on\"><a href=\"${1}${left_on}\.html/g;

   open (LEFT_HTML, ">${page_name}.left") or die ("Error: Failed to open $page_name.left for writing\n");
   print LEFT_HTML $left_menu_str;
   close LEFT_HTML;
}

open (HTML_FILE, ">${page_name}.html") or die("Failed to open ${page_name}.html for writing\n");
print HTML_FILE $head_start, $head_end, $nav_table, $main_table, $submenus, $footer;
close HTML_FILE;

system "html_convert.pl ${page_name}.html";

exit 0;

__DATA__

create_group_html.pl

   Create an html file of the group web site.

   -page_name <STR> : Name of the html file (without the .html extension).
   -title <STR>     : Page title will be: "Segal Lab: <STR>". Default - empty.
   -page_type <STR> : STR may be "home" (for the home page), "inner" (for inner pages) or "gbrowse" (default is "inner").
   -nav_on <STR>    : The top navigation item to highlight, may be home/people/research/publications/genomica or none.
   -left_menu <STR> : Name of the left menu bar - either people/publications/genomica/nucleosomes06/segnet08/motifs07/imaging07/mir07/field08/fmm08/rnamotifs08/wong08/conf_chromatin08/nucleo_pred/nucleosomes08/nucleosomes09/nucleosomes10/tf_nuc_model09/linker09/pars10 (default - empty).
   -left_on <STR>   : Name of left submenu to highlight (defualt: Use the page_name).
   -main_div <STR>  : Class of the main div (Default is "main").
   -footer <STR>    : Class of the footer (Default is "footer").

   The script looks for files named <page_name>.right, <page_name>.center, <page_name>.left and <page_name>.outside for the content (which will be put in the main table right, center, left cells and outside the main div, respectively).
   All these files are optional.


