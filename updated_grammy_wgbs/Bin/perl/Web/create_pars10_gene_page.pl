#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $table_name = get_arg("genes_table", "$ENV{TEMPLATES_HOME}/Web/pars10_web_index.txt", \%args);
my $template_file = get_arg("genes_table", "$ENV{TEMPLATES_HOME}/Web/pars10_gene_page.center", \%args);
my $base_url = get_arg("base_url", "genie.weizmann.ac.il", \%args);

if (! -f $template_file)
{
    die "Failed to find page template file: $template_file";
}

open (WEB_INFO_TABLE, "<$table_name") or die "Failed to open: $table_name";

my $template_html = `cat $template_file`;

while (<WEB_INFO_TABLE>)
{
    chop;
    my ($id, $name, $nicknames, $transcript_type, $desc, $length, $load) = split (/\t/);

#    print STDERR "processing $id\n";

    my $curr_html = $template_html;

    $curr_html =~ s/__SYS_NAME__/$id/g;
    $curr_html =~ s/__TRANSCRIPT_TYPE__/$transcript_type/g;
    $curr_html =~ s/__LENGTH__/$length/g;
    $curr_html =~ s/__GENE_LOAD__/$load/g;

    if ($name)
    {
	$curr_html =~ s/__GENE_NAME__/$name/g;
    }
    else
    {
	$curr_html =~ s/<tr><td class=\"PARS10-color\" width=120px><b>Standard Name<\/b><\/td><td class=\"PARS10\">__GENE_NAME__<\/td><\/tr>//g;
    }

    if ($nicknames)
    {
	$nicknames =~ s/\|/, /g;
	$curr_html =~ s/__ALIAS__/$nicknames/g;
    }
    else
    {
	$curr_html =~ s/<tr><td class=\"PARS10-color\"><b>Alias<\/b><\/td><td class=\"PARS10\">__ALIAS__<\/td><\/tr>//g;
    }

    if ($desc)
    {
	$curr_html =~ s/__DESC__/$desc/g;
    }
    else
    {
	$curr_html =~ s/<tr><td class=\"PARS10-color\"><b>Description<\/b><\/td><td class=\"PARS10\">__DESC__<\/td><\/tr>//g;
    }

    if ($load < 1)
    {
	my $start_table_idx = index ($curr_html, "<tr><td class=\"PARS10-color\"><b>PARS readout");
	my $new_curr_html = substr ($curr_html, 0, $start_table_idx) . "</table><br><br><table border=0 width=100%><tr><td><b class=\"red\">Gene load too low. Structural information unavailable.</b></td></tr></table></div>\n";
	$curr_html = $new_curr_html;
    }

    open (GENE_PAGE, ">${id}.center") or die "Failed to open ${id}.center for writing";
    print GENE_PAGE $curr_html;
    close GENE_PAGE;
    
    system ("create_group_html.pl -base_url '$base_url' -page_name $id -title 'PARS 2010 - Browse catalog - $id ' -left_menu pars10 -left_on pars10_browse");
    unlink "$id.center";
    
    
}

close WEB_INFO_TABLE;

 
__DATA__

create_pars10_gene_pages.pl

   Create the html files for PARS10 gene pages

   -genes_table <STR>  :  Name of the table with the genes information (default: $TEMPLATES_HOME/Web/pars10_web_index.txt)

   -page_template <STR>:  Name of the page template file (default: $TEMPLATES_HOME/Web/pars10_gene_page.center) 

   -base_url <STR>     :  Web site domain (default: genie.weizmann.ac.il)

