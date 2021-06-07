#! /usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

#---------------------------------------------------------------------------
# remove_illegal_chars
#---------------------------------------------------------------------------
sub remove_illegal_xml_chars
{
  my $str = $_[0];
  $str =~ s/\&/&amp;/g;
  $str =~ s/\"/&quot;/g;
  $str =~ s/\'/&apos;/g;
  $str =~ s/\</&lt;/g;
  $str =~ s/\>/&gt;/g;
  return $str;
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub fix_object_name
{
  my $str = $_[0];
#  $str =~ s/[\.]/_/g;
  return $str;
}

#--------------------------------------------------------------------------------
# print_matrix
#--------------------------------------------------------------------------------
sub to_gx_attributes
{
    my ($attributes_file, $objects_type, $object_type, $object_id, $attributes_names, $org, $gene_namespace, $description, $attribute_threshold, $colors) = @_;
    if (length($colors) > 0) { $colors = "Colors=\"$colors\""; }

    my @columnid_to_attribute;
    my @rowid_to_object_id;
    my @object_assignments;
    my %attributes_domains;
    my %attributes_domains_cache;

    open(ATTRIBUTES_FILE, "<$attributes_file");
    my $line = <ATTRIBUTES_FILE>;
    chop $line;
    my @desc = split(/\t/, $line);
    my $num_columns = @desc;
    
    my %matrix;



    my %exclude_attributes;
    
    # exclude columns that don't have enough diversity
    my %columns_passing_threshold;
    my %attribute_counts_str;
    my @attribute_counts;

    open(ATTRIBUTES_FILE, "<$attributes_file");
    my $line = <ATTRIBUTES_FILE>;

    my @row;
    my @value_to_index;
    my @index_to_value;
    my @num_values;
    for (my $i = 0; $i < $num_columns; $i++)
    {
       push (@value_to_index, {});
       push (@index_to_value, {});
       push (@num_values, 0);
    }

    while (<ATTRIBUTES_FILE>)
    {
       chop;
       @row = split (/\t/);
       for (my $i = 1; $i < $num_columns; $i++)
       {
	  my $value = $row[$i];
	  if (length($value_to_index[$i]{$value}) == 0)
	  {
	     $value_to_index[$i]{$value} = $num_values[$i];
	     $index_to_value[$i]{$num_values[$i]} = $value;
	     $attribute_counts[$i][$num_values[$i]] = 1;
	     $num_values[$i]++;
	  }
	  else
	  {
	     $attribute_counts[$i][$value_to_index[$i]{$value}]++;
	  }
       }
    }
    close ATTRIBUTES_FILE;
    
    for (my $i = 1; $i < $num_columns; $i++)
    {
	my $num_values_passing = 0;
	my $counts_str = "";
	for (my $j = 0; $j < $num_values[$i]; $j++)
	{
	    if ($j > 0 and length($counts_str) > 0 and length($index_to_value[$i]{$j}) > 0) { $counts_str .= " "; }
	    
	    if (length($index_to_value[$i]{$j}) > 0) { $counts_str .= "$attribute_counts[$i][$j]"; }
	    
	    if ($attribute_counts[$i][$j] >= $attribute_threshold)
	    {
		$num_values_passing++;
	    }
	}
	
	if ($num_values_passing >= 2)
	{
	    $columns_passing_threshold{$i} = "1";
	    $attribute_counts_str{$i} = $counts_str;
	}
    }

    open(ATTRIBUTES_FILE, "<$attributes_file");
    
    my $line = <ATTRIBUTES_FILE>;
    chop $line;
    my @desc = split(/\t/, $line);
    for (my $i = 0; $i < @desc; $i++)
    {
	$columnid_to_attribute[$i] = $desc[$i];
    }
    
    my %object_assignments;
    my %rowid_to_object_id;
    my $counter = 0;
    while(<ATTRIBUTES_FILE>)
    {
	chop;

	my @row = split(/\t/);
	my $value_str = "";
	my $first_attribute = 1;
	
	for (my $i = 1; $i < $num_columns; $i++)
	{
	    if ($columns_passing_threshold{$i} eq "1" && $exclude_attributes{$columnid_to_attribute[$i]} ne "1")
	    {
		if ($first_attribute == 0) { $value_str .= ";"; } else { $first_attribute = 0; }
		$value_str .= "$row[$i]";
		
		my $attribute = $columnid_to_attribute[$i];
		my $key = "${attribute}_$row[$i]";
		if ($attributes_domains_cache{$key} ne "1")
		{
		    $attributes_domains_cache{$key} = "1";
		    
		    if (length($attributes_domains{$attribute}) > 0 and length($row[$i]) > 0) { $attributes_domains{$attribute} .= " "; }
		    
		    $attributes_domains{$attribute} .= "$row[$i]";
		}
	    }
	}
	
	$rowid_to_object_id[$counter] = $row[0];
	
	$object_assignments[$counter] = $value_str;
	
	$counter++;
    }
    
    $description = &remove_illegal_xml_chars ($description);
    $description =~ s/\t/ /g;


    my $annotations_str;
    my $n_annotations = 0;
    for (my $i = 1; $i < @columnid_to_attribute; $i++)
    {
	if ($columns_passing_threshold{$i} eq "1" && $exclude_attributes{$columnid_to_attribute[$i]} ne "1")
	{
	    my $attribute = $columnid_to_attribute[$i];
	    my $legal_attribute_name = remove_illegal_xml_chars($attribute);

	    my $attribute_domain = $attributes_domains{$attribute};
	    my $counts_str = $attribute_counts_str{$i};
	    if ($attribute_domain eq "1 0")
	    {
		$attribute_domain = "0 1";
		
		my @row = split(/\s/, $counts_str);
		$counts_str = "$row[1] $row[0]";
	    }
	    
	    $annotations_str .= "    <Attribute Name=\"$legal_attribute_name\" Id=\"$i\" Counts=\"$counts_str\" $colors Value=\"$attribute_domain\" />\n";
	    $n_annotations++;
	}
    }
    undef %attributes_domains;
    undef %attribute_counts_str;;
    
    print "<GeneXPress>\n";
    
    print "<GeneXPressAttributes>\n";
    print "  <Attributes Id=\"0\" Name=\"$attributes_names\" Description=\"$description\" Organism=\"$org\" GeneNamespace=\"$gene_namespace\" NumAnnotations=\"$n_annotations\">\n";

    print $annotations_str;

    print "  </Attributes>\n";
    print "</GeneXPressAttributes>\n";
    
    print "<GeneXPressObjects>\n";
    print "  <Objects Type=\"$objects_type\">\n";
    
    for (my $i = 0; $i < @object_assignments; $i++)
    {
	my $fixed_object_id = fix_object_name($rowid_to_object_id[$i]);
	print "    <$object_type Id=\"$i\" $object_id=\"$fixed_object_id\">\n";
	print "      <Attributes AttributesGroupId=\"0\" Type=\"Full\" Value=\"$object_assignments[$i]\"/>\n";
	print "    </$object_type>\n";
    }
    
    print "  </Objects>\n";
    print "</GeneXPressObjects>\n";
    
    print "</GeneXPress>\n";
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
    my %args = load_args(\@ARGV);
    
    to_gx_attributes($ARGV[0],
		     get_arg("o", "Genes", \%args),
		     get_arg("ot", "Gene", \%args),
		     get_arg("oi", "ORF", \%args),
		     get_arg("n", "Gene Attributes", \%args),
		     get_arg("org", "", \%args),
		     get_arg("gns", "", \%args),
		     get_arg("d", "", \%args),
		     get_arg("t", 5, \%args),
		     get_arg("c", "", \%args));
}
else
{
    print "Usage: tab2gxa.pl <tab file>\n\n";
    print "      -o  <objects_type>:   The type of the objects (default Genes)\n";
    print "      -ot <object_type>:    The type of the object (default Gene)\n";
    print "      -oi <object_id>:      The identifier name of the object (default ORF)\n";
    print "      -n  <name>:           Name of the attributes (default: Genes)\n";
    print "      -org <name>:          Name of the organism\n";
    print "      -gns <name>:          Gene Namespace\n";
    print "      -d  <desc>:           Description of the gene set (default: empty)\n";
    print "      -t  <threshold>:      Only attributes above this threshold will enter the attribute list (default 5)\n";
    print "      -c  <color>:          If specified, add Color=\"<color>\" for each attribute\n\n";
}

1
