#!/usr/bin/perl

use strict;

my $head_start = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n".
"<html>\n".
"  <head>\n".
"    <title>Segal LabPAGE_TITLE</title>\n".
"    <link rel=\"stylesheet\" type=\"text/css\" href=\"/style/group.css\" />\n".
"    <link rel=\"shortcut icon\" href=\"/favicon.ico\" type=\"image/x-icon\" />\n".
"    <link rel=\"icon\" href=\"/favicon.ico\"  type=\"image/x-icon\" />\n".
"      <script src=\"/javascript/group.js\" type=\"text/javascript\"></script>\n";

sub get_head_start
{
   return $head_start;
}

sub get_xennex_head_start
{
   my $xennex_head_start = $head_start;
   $xennex_head_start =~ s/Segal Lab//g;

   return $xennex_head_start; 
}

sub get_conf_head_start
{
   my $conf_head_start = $head_start;
   $conf_head_start =~ s/Segal Lab//g;
   $conf_head_start =~ s/group\.css/conf\.css/g;
   $conf_head_start =~ s/<link rel="shortcut icon" href="\/favicon.ico" type="image\/x-icon" \/>\n//g;
   $conf_head_start =~ s/<link rel="icon" href="\/favicon.ico"  type="image\/x-icon" \/>\n//g;

   return $conf_head_start;
}

sub get_parsed_head_start
{
   my ($page_title) = @_;

   my $head = &get_head_start();

   $head =~ s/PAGE_TITLE/${page_title}/g;

   return $head;
}

sub get_head_end
{
   my $head_end   = "  </head>\n".
	"  <body>\n".
	"    <div class=\"MAIN_DIV\">\n".
	"      <div class=\"perm-header\">\n".
	"	<img id=\"obj-left\" src=\"/images/site_logo.gif\"/>\n".
	"	  <img id=\"obj-right\" src=\"/images/weizman_logo.gif\"/>\n".
	"      </div>\n";
   return $head_end;
}

sub get_xennex_head_end
{
   my $head_end = "  </head>\n  " .
   "<body>\n".
   "<div class=\"MAIN_DIV\">\n".
   "      <div class=\"perm-header\">\n".
   "   <img id=\"obj-left\" src=\"/images/xennex.jpg\"/>\n".
   "   <img id=\"obj-left\" src=\"/images/genomica.gif\"/>\n".
   "    <img id=\"obj-right\" src=\"/images/weizman_logo.gif\"/>\n".
   "      </div>\n";

   return $head_end;
}

sub get_conf_head_end
{
   my $head_end = "  </head>\n  " .
   "<body>\n".
   "<div class=\"MAIN_DIV\">\n".
   "      <div class=\"perm-header\">\n".
   "    <img id=\"obj-right\" src=\"/images/weizman_logo.gif\"/>\n".
   "      </div>\n";

   return $head_end;
}

sub get_parsed_head_end
{
   my ($main_div) = @_;
   
   my $head = &get_head_end();

   $head =~ s/MAIN_DIV/${main_div}/g;

   return $head;
}

sub get_nav_table
{
   my $nav_table  = "    <table class=\"PAGE_TYPE-nav\" border=0 cellpadding=0 cellspacing=0>\n".
	"	<tr>\n".
	"	  <td class=\"left\">&nbsp;</td>\n".
	"	  <td><a class=\"main-menu\" href=\"http://genie.weizmann.ac.il/index.html\"/><img src=\"/images/home_bt.gif\" onmouseover=\"src='/images/home_bt_roll.gif'\" onmouseout=\"src='/images/home_bt.gif'\"/></a></td>\n".
	"	  <td><a class=\"main-menu\" href=\"http://genie.weizmann.ac.il/research.html\"/><img src=\"/images/research_bt.gif\" onmouseover=\"src='/images/research_bt_roll.gif'\" onmouseout=\"src='/images/research_bt.gif'\"/></a></td>\n".
	"	  <td><a class=\"main-menu\" href=\"http://genie.weizmann.ac.il/people.html\"/><img src=\"/images/people_bt.gif\" onmouseover=\"src='/images/people_bt_roll.gif'\" onmouseout=\"src='/images/people_bt.gif'\"/></a></td>\n".
	"	                                                                                                          <td><img id=\"publications-bt\" src=\"/images/publications_bt.gif\"  onmouseover=\"showSubMenu('publications-submenu')\" onmouseout=\"hideSubMenu('publications-submenu')\"/></td> \n".
	"	  <td><a class=\"main-menu\" href=\"http://genomica.weizmann.ac.il\"/><img src=\"/images/genomica_bt.gif\" onmouseover=\"src='/images/genomica_bt_roll.gif'\" onmouseout=\"src='/images/genomica_bt.gif'\"/></a></td>\n".
	"	  <td><img id=\"software-bt\" src=\"/images/software_bt.gif\" onmouseover=\"showSubMenu('software-submenu')\" onmouseout=\"hideSubMenu('software-submenu')\"/></td>\n".
	"	  <td><a class=\"main-menu\" href=\"http://www.weizmann.ac.il/genie-wiki\"/><img src=\"/images/internal_bt.gif\" onmouseover=\"src='/images/internal_bt_roll.gif'\" onmouseout=\"src='/images/internal_bt.gif'\"/></a></td>\n".
	"	  <td class=\"filler\">&nbsp;</td>\n".
	"	  <td class=\"right\">&nbsp;</td>\n".
	"	</tr>\n".
	"      </table>\n";
   return $nav_table;
}

sub get_xennex_nav_table
{
   my $nav_table = "    <table class=\"PAGE_TYPE-nav\" border=0 cellpadding=0 cellspacing=0>\n".
   "   <tr>\n".
   "    <td class=\"left\">&nbsp;</td>\n".
   "        <td class=\"nomenucenter\">&nbsp;</td>\n".
   "      <td class=\"right\">&nbsp;</td>\n".
   "     </tr>\n".
   "      </table>\n";

   return $nav_table;
}

sub get_conf_nav_table
{
   return get_xennex_nav_table();
}


sub get_parsed_nav_table
{
   my ($page_type) = @_;

   my $res = &get_nav_table();

   $res =~ s/PAGE_TYPE/${page_type}/g;

   return $res;
}


sub get_main_table
{
   my $main_table = "      <table class=\"main\" width=\"100%\" cellpadding=\"0px\" cellspacing=\"0px\" border=\"0\"><tr>\n".
	"	  <td class=\"PAGE_TYPE-left\">\n".
	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.left\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	  <td class=\"PAGE_TYPE-center\">\n".
	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.center\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	  <td class=\"PAGE_TYPE-right\">\n".
	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.right\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	</tr>\n".
	"      </table> \n".
	"\n".
	"    </div>\n";
   return $main_table;
}

sub get_main_table_start
{
   my $main_table = "      <table class=\"main\" width=\"100%\" cellpadding=\"0px\" cellspacing=\"0px\" border=\"0\"><tr>\n".
	"	  <td class=\"PAGE_TYPE-left\">\n".
	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.left\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	  <td class=\"PAGE_TYPE-center\">\n";
   return $main_table;
}

sub get_main_table_start2
{
   my $main_table = "      <table class=\"main\" width=\"100%\" cellpadding=\"0px\" cellspacing=\"0px\" border=\"0\"><tr>\n".
	"	  <td class=\"PAGE_TYPE-left\">\n";
   return $main_table;
}

sub get_main_table_mid2a
{
   my $main_table = 	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.left\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	  <td class=\"PAGE_TYPE-center\">\n";

   return $main_table;
}

sub get_main_table_mid2b
{
   my $main_table = 	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.center\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	  <td class=\"PAGE_TYPE-right\">\n";
   return $main_table;
}

sub get_main_table_end2
{
   my $main_table =    "<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.right\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	</tr>\n".
	"      </table> \n".
	"\n".
	"    </div>\n";

   return $main_table;
}

sub get_parsed_main_table_start2
{
   my ($page_type) = @_;

   my $res = &get_main_table_start2();

   $res =~ s/PAGE_TYPE/${page_type}/g;

   return $res;

}

sub get_parsed_main_table_mid2a
{
   my ($page_type) = @_;

   my $res = &get_main_table_mid2a();

   $res =~ s/PAGE_TYPE/${page_type}/g;

   return $res;

}

sub get_parsed_main_table_mid2b
{
   my ($page_type) = @_;

   my $res = &get_main_table_mid2b();

   $res =~ s/PAGE_TYPE/${page_type}/g;

   return $res;

}

sub get_parsed_main_table_end2
{
   my ($page_type) = @_;

   my $res = &get_main_table_end2();

   $res =~ s/PAGE_TYPE/${page_type}/g;

   return $res;

}

sub get_main_table_end
{
   my $main_table = 	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.center\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	  <td class=\"PAGE_TYPE-right\">\n".
	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.right\">\n".
	"</MAP_HTML_INCLUDE>\n".
	"</td>\n".
	"	</tr>\n".
	"      </table> \n".
	"\n".
	"    </div>\n";

   return $main_table;
}

sub get_parsed_main_table
{
   my ($page_type) = @_;

   my $res = &get_main_table();

   $res =~ s/PAGE_TYPE/${page_type}/g;

   return $res;
}

sub get_parsed_main_table_start
{
   my ($page_type) = @_;

   my $res = &get_main_table_start();

   $res =~ s/PAGE_TYPE/${page_type}/g;

   return $res;
}

sub get_parsed_main_table_end
{
   my ($page_type) = @_;

   my $res = &get_main_table_end();

   $res =~ s/PAGE_TYPE/${page_type}/g;

   return $res;
}

sub get_submenus
{
   my $submenus   = "    <div id=\"publications-submenu\" class=\"PAGE_TYPE-publications-submenu\">\n".
	"      <table class=\"submenu\" width=\"100%\" cellpadding=0 cellspacing=0 onmouseover=\"showSubMenu('publications-submenu')\" onmouseout=\"hideSubMenu('publications-submenu')\"> \n".
	"	<tr><td class=\"submenu\"><a href=\"http://genie.weizmann.ac.il/pubs/pubsall.html\">All</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2010.html\">2010</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2009.html\">2009</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2008.html\">2008</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2007.html\">2007</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2006.html\">2006</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2005.html\">2005</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2004.html\">2004</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2003.html\">2003</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2002.html\">2002</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/pubs2001.html\">2001</a></td></tr>\n".
	"      </table>\n".
	"    </div>\n".
	"    <div id=\"software-submenu\" class=\"PAGE_TYPE-software-submenu\">\n".
	"      <table class=\"submenu\" width=\"250px\" cellpadding=0 cellspacing=0 onmouseover=\"showSubMenu('software-submenu')\" onmouseout=\"hideSubMenu('software-submenu')\"> \n".
	"	<tr><td class=\"submenu\"><a href=\"http://genomica.weizmann.ac.il\" >Genomica</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/software/nucleo_prediction.html\">Nucleosomes Positioning</a></td></tr>\n".	
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/genomica_web/enrichment/gene_sets.jsp\">Gene Set Enrichment</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/mir07/mir07_prediction.html\">Predict microRNA targets</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/genomica_web/module_map/module_map.jsp\">Create Module Map</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/fmm08/fmm08_learn_unalign.html\">Find DNA Motifs in unaligned DNA sequences</a></td></tr>\n".
	"	<tr><td class=\"submenu\" ><a href=\"http://genie.weizmann.ac.il/pubs/rnamotifs08/rnamotifs08_predict.html\">Find RNA Motifs in unaligned RNA sequences</a></td></tr>\n".
	"      </table>\n".
	"    </div>\n".
	"\n".
	"<MAP_HTML_INCLUDE file=\"BASE_FILE_NAME.outside\">\n".
	"</MAP_HTML_INCLUDE>\n";
   return $submenus;
}

sub get_parsed_submenus
{
   my ($page_name,$page_type,$base_url) = @_;

   my $submenu = &get_submenus();

   $submenu =~ s/BASE_FILE_NAME/${page_name}/g;
   $submenu =~ s/PAGE_TYPE/${page_type}/g;
   $submenu =~ s/BASE_URL/${base_url}/g;
   $submenu =~ s/Menu\(\'${page_name}/Menu2\(\'${page_name}/g;

   return $submenu;
}

sub get_parsed_footer
{
   my ($footer_class) = @_;

   my $footer = get_footer();

   $footer     =~ s/FOOTER_CLASS/${footer_class}/g;

   return $footer;
}


sub get_footer
{
   my $footer     = "    <div class=\"FOOTER_CLASS\">\n".
	"      <table id=\"txt-right\" width=\"100%\" height=\"20px\">\n".
	"	<tr>\n".
	"	  <td id=\"link\"><a class=\"gray\" href=\"http://www.saydigitaldesign.com\">Say Digital Design</a></td><td width=\"34px\"><a class=\"gray\" href=\"http://www.saydigitaldesign.com\"><img width=\"75%\" src=\"/images/helit_logo.gif\"/></a></td>\n".
	"	</tr>\n".
	"      </table>\n".
	"    </div>\n".
	"\n".
	"  </body>\n".
	"</html>\n";

   return $footer;
}

sub get_conf_footer
{
   my $footer     = "<div class=\"FOOTER_CLASS\">\n".
   "\n".
   "    </div>\n".
   "  </body>\n".
   "</html>\n";

   return $footer;
}

sub get_parsed_left_menu ($$$)
{
   my ($menu_name,$base_url,$page_name) = @_;

   my $menu = get_left_menu($menu_name);

   $menu =~ s/BASE_URL/${base_url}/g;
   $menu =~ s/submenu\"><a href=\"(.*\/)${page_name}\.html/submenu-on\"><a href=\"${1}${page_name}\.html/g;
   return $menu;
}

sub get_left_menu($)
{
   my $menu_name = $_[0];

   my $pubs_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubsall.html\">All</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2010.html\">2010</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2009.html\">2009</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2008.html\">2008</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2007.html\">2007</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2006.html\">2006</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2005.html\">2005</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2004.html\">2004</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2003.html\">2003</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2002.html\">2002</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/pubs2001.html\">2001</a></td></tr>\n".
	"	    </table> \n";
   my $nucleosomes06_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes06/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes06/segal06_data.html\">Download Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes06/segal06_genomica.html\">Visualize in Genomica</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes06/segal06_gbrowse.html\">Browse Online</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_prediction.html\">Predict your Sequence</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_exe.html\">Download executable</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes06/segal06_notes.html\">Implementation notes</a></td></tr>\n".
	"	    </table> \n";
   my $field08_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/field08/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/field08/field08_data.html\">Download Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/field08/field08_genomes.html\">Genome-Wide Predictions</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_prediction.html\">Predict your Sequence</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_exe.html\">Download executable</a></td></tr>\n".
	"	    </table> \n";
   my $nucleosomes08_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes08/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes08/nucleosomes08_data.html\">Download Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_genomes.html\">Genome-Wide Predictions</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_prediction.html\">Predict your Sequence</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_exe.html\">Download executable</a></td></tr>\n".
	"	    </table> \n";
   my $nucleosomes09_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes09/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes09/nucleosomes09_data.html\">Download Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_genomes.html\">Nucleosome Prediction Tools</a></td></tr>\n".
	"	    </table> \n";
   my $nucleosomes10_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes10/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/nucleosomes10/nucleosomes10_review.html\">Data for reviewers</a></td></tr>\n".
	"	    </table> \n";

   my $tf_nuc_model09_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/tf_nuc_model09/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/tf_nuc_model09/tf_nuc_model09_code.html\">Download Source</a></td></tr>\n".
	"	    </table> \n";

   my $linker09_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/linker09/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/linker09/linker09_predict.html\">Predict your Sequence</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/linker09/linker09_exe.html\">Download executable</a></td></tr>\n".
	"	    </table> \n";

   my $pars10_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/PARS10/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/PARS10/pars10_data.html\">Supplementary data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/PARS10/pars10_catalogs.html\">Download catalogs</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/PARS10/pars10_browse.html\">Browse catalog</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/PARS10/pars10_notes.html\">FAQ / Notes</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/PARS10/pars10_ipars.html\">iPARS</a></td></tr>\n".
	"	    </table> \n";

   my $segnet08_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/segnet08/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/segnet08/segnet08_data.html\">Download Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/segnet08/segnet08_genomica.html\">Visualize in Genomica</a></td></tr>\n".
	"	    </table> \n";
   my $wong08_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/wong08/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/wong08/wong08_data.html\">Supplemental Data</a></td></tr>\n".
	"	    </table> \n";
   my $motifs07_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
        "             <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/motifs07/index.html\">Main</a></td></tr>\n".
        "             <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/motifs07/motifs07_data.html\">Download motif map</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/motifs07/motifs07_prediction.html\">Predict your Sequence</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/motifs07/motifs07_exe.html\">Download executable</a></td></tr>\n".
	"	    </table> \n";
   my $imaging07_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
        "             <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/imaging06/index.html\">Main</a></td></tr>\n".
        "             <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/imaging06/imaging07_data.html\">Supplemental Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/imaging06/imaging07_genomica.html\">Visualize in Genomica</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/imaging06/imaging07_images.html\">Modules Images</a></td></tr>\n".
	"	    </table> \n";
   my $mir07_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/mir07/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/mir07/mir07_supplementary.html\">Supplementary Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/mir07/mir07_data.html\">Download Predictions</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/mir07/mir07_dyn_data.html\">Search Predictions</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/mir07/mir07_browse.html\">Browse Predictions</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/mir07/mir07_prediction.html\">Predict your UTR</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/mir07/mir07_exe.html\">Download executable</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/mir07/mir07_notes.html\">FAQ / Notes</a></td></tr>\n".
	"	    </table> \n";
   my $rnamotifs08_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/rnamotifs08/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/rnamotifs08/rnamotifs08_predict.html\">Predict Motif</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/rnamotifs08/rnamotifs08_exe.html\">Download Executable</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/rnamotifs08/rnamotifs08_notes.html\">Implementation Notes</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/rnamotifs08/rnamotifs08_faq.html\">FAQs</a></td></tr>\n".
	"	    </table> \n";

#	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/rnamotifs08/rnamotifs08_data.html\">Download Data</a></td></tr>\n".
#	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/rnamotifs08/rnamotifs08_search.html\">Search Motif in Sequence</a></td></tr>\n".

   my $conf_chromatin08_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/conferences/chromatin08/index.html\">Home</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/conferences/chromatin08/register.html\">Registration</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/conferences/chromatin08/program.html\">Program</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/conferences/chromatin08/info.html\">Travel and Accomodation</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/conferences/chromatin08/poster.html\">Conference Poster</a></td></tr>\n".
	"	    </table> \n";

   my $people_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/people.html\">Active Lab Members</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/alumni.html\">Former Lab Members</a></td></tr>\n".
	"	    </table> \n";


   my $fmm08_full_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_supplementary.html\">Supplementary Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-th\">Learn Motif</td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_learn_align.html\">&nbsp;&nbsp;From Aligned Sequences</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_learn_unalign.html\">&nbsp;&nbsp;From Unaligned Sequences</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_scan_seq.html\">Scan Sequence From Motif</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_exe.html\">Download executable</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_notes.html\">FAQ</a></td></tr>\n".
	"	    </table> \n";
   my $fmm08_left_menu = "     <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
        "             <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/index.html\">Main</a></td></tr>\n".
        "             <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_supplementary.html\">Supplementary Data</a></td></tr>\n".
        "             <tr><td class=\"left-submenu-th\">Learn Motif</td></tr>\n".
        "             <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_learn_unalign.html\">&nbsp;&nbsp;From Unaligned Sequences</a></td></tr>\n".
        "             <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_exe.html\">Download executable</a></td></tr>\n".
        "             <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/pubs/fmm08/fmm08_notes.html\">FAQ</a></td></tr>\n".
        "           </table> \n";


   my $cancer07_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/cancer07/index.html\">Main</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/pubs/cancer07/visualize_in_genomica.html\">Visualize in Genomica</a></td></tr>\n".
	"	    </table> \n";

   my $genomica_web_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/genomica_web/enrichment/gene_sets.jsp\">Find enriched gene sets</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/genomica_web/module_map/module_map.jsp\">Find co-expressed gene sets</a></td></tr>\n".
	"	    </table> \n";

   my $nucleo_pred_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_genomes.html\">Genome-Wide Predictions</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_prediction.html\">Predict your Sequence</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/software/nucleo_exe.html\">Download Executable</a></td></tr>\n".
	"	    </table> \n";

   my $genomica_web_xennex_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/genomica_web/enrichment/gene_sets.jsp\">Find enriched gene sets</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/genomica_web/module_map/module_map.jsp\">Find co-expressed gene sets</a></td></tr>\n".
	"	    </table> \n";

   my $genomica_left_menu = "	    <table width=\"100%\" cellspacing=0 cellpadding=0 border=0>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/download.html\">Download Genomica</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/Files/download_data.html\">Download Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/Files/gene_mapping_tables.html\">Gene Mapping Tables</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-dark\"><a href=\"http://BASE_URL/credits.html\">Credits</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-th\">Tutorial</td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/Tutorial/overview_and_faq.html\">Overview and FAQ</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/Tutorial/load_expression_data.html\">Load Expression Data</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/Tutorial/load_sets.html\">Load Sets</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/Tutorial/file_repository.html\">File Repository</a></td></tr>\n".
	"              <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/Tutorial/browse_in_genome_browser.html\">The Genome Browser</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/Tutorial/find_enriched_sets.html\">Find Enriched Sets</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/Tutorial/create_module_network.html\">Create a Module Network</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://BASE_URL/Tutorial/create_module_map.html\">Create a Module Map</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-th\">Related Sites</td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a target=\"_blank\" href=\"http://cs.stanford.edu/%7Eeran/module_nets\">Module Networks</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a target=\"_blank\" href=\"http://cs.stanford.edu/%7Eeran/cancer\">Cancer Module Map</a></td></tr>\n".
	"	      <tr><td class=\"left-submenu-th\">Internal Use</td></tr>\n".
	"	      <tr><td class=\"left-submenu\"><a href=\"http://www.weizmann.ac.il/genomica-wiki\">Genomica Wiki</a></td></tr>\n".
	"	    </table> \n";

   my %menus_map = {};
   $menus_map{"nucleosomes06"} = $nucleosomes06_left_menu;
   $menus_map{"pubs"} =          $pubs_left_menu;
   $menus_map{"segnet08"} =      $segnet08_left_menu;
   $menus_map{"wong08"} =      $wong08_left_menu;
   $menus_map{"motifs07"} =       $motifs07_left_menu;
   $menus_map{"imaging07"} =       $imaging07_left_menu;
   $menus_map{"mir07"} =       $mir07_left_menu;
   $menus_map{"fmm08"} =       $fmm08_left_menu;
   $menus_map{"rnamotifs08"} =       $rnamotifs08_left_menu;
   $menus_map{"conf_chromatin08"} =       $conf_chromatin08_left_menu;
   $menus_map{"cancer07"} =       $cancer07_left_menu;
   $menus_map{"genomica"} =      $genomica_left_menu;
   $menus_map{"genomica_web"} =  $genomica_web_left_menu;
   $menus_map{"genomica_web_xennex"} =  $genomica_web_xennex_left_menu;
   $menus_map{"field08"} = $field08_left_menu;
   $menus_map{"nucleosomes08"} = $nucleosomes08_left_menu;
   $menus_map{"nucleosomes09"} = $nucleosomes09_left_menu;
   $menus_map{"nucleosomes10"} = $nucleosomes10_left_menu;
   $menus_map{"tf_nuc_model09"} = $tf_nuc_model09_left_menu;
   $menus_map{"linker09"} = $linker09_left_menu;
   $menus_map{"pars10"} = $pars10_left_menu;
   $menus_map{"nucleo_pred"} = $nucleo_pred_left_menu;
   $menus_map{"people"} = $people_left_menu;
   
   return $menus_map{"$menu_name"};
}

sub get_digest ($)
{
   require Digest::MD5;

   my $str = $_[0];

   Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$str));
}

1
