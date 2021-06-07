#!/bin/tcsh
source /home/genie/.cshrc_shared;
cd $DEVELOP_HOME/perl/Help;
make help;
rm -f *.html;
make help;
chmod 664 *html;
scp -i ~/.ssh/id_dsa_gweb-02 * root@gweb-02:/var/www/html/PerlHelp;
rm *.html

