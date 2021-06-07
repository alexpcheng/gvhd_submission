#! /usr/bin/perl 

use strict;

require "$ENV{PERL_HOME}/Lib/system.pl";
require "$ENV{PERL_HOME}/Lib/c_bio_tokens_2_hash.pl";


sub get_bio_tokens_hash
{
  my $bio_tokens_h_file_name = "$ENV{HOME}/Develop/genie/Common/bio_tokens.h";
  my $bio_tokens_hash_ptr = &c_bio_tokens_2_hash($bio_tokens_h_file_name);
  my %bio_tokens_hash = %$bio_tokens_hash_ptr;
  return \%bio_tokens_hash;
}

sub set_filed_in_xml_str
{
  my ($xml_str, $token ,$filed_new_value,@elements_tokens_in_converge_order) = @_;

  my $bio_tokens_hash_ptr = &get_bio_tokens_hash();
  my %bio_tokens_hash = %$bio_tokens_hash_ptr;

  my $token_str = $bio_tokens_hash{$token};

  
  my $reg_str = $token_str . "=\"([\\w|\\.|\\s]*)\"" ;

  my $elements_count = 1;

  for (my $i = $#elements_tokens_in_converge_order; $i >= 0; --$i)
  {
    my $cur_element_token = $elements_tokens_in_converge_order[$i];
    my $cur_element_token_str = $bio_tokens_hash{$cur_element_token};

    $reg_str = "<" .$cur_element_token_str . "(.*)" . $reg_str . "(.*)" . "</" . $cur_element_token_str;
    $elements_count = $elements_count + 2;
  }
  $reg_str = "(.*)" . $reg_str ."(.*)";
  $elements_count = $elements_count + 2;

  my $main_element = (int ($elements_count/2));

  my @xml_parts = ($xml_str =~ m/$reg_str/s);

  #$xml_str =~ m/(.*)S(.*)/s;
  #(.*)<Step(.*)<TrainingProcedureParameters(.*)TrainingProcedureType="(.*)"(.*)</TrainingProcedureParameters(.*)</Step(.*)/;

  #print $xml_str . "\n";
  #print "-------------------------------------------------------------------------\n";
  #print $reg_str . "\n" . $elements_count . "\n" . $main_element . "\n";
  #print "-------------------------------------------------------------------------\n";
  #print $1 . "\n";
  #print "-------------------------------------------------------------------------\n";
  #print $2 . "\n";
  #print "-------------------------------------------------------------------------\n";
  #print $3 . "\n";
  #print "-------------------------------------------------------------------------\n";
  #print $4 . "\n";
  #print "-------------------------------------------------------------------------\n";
  #print $5 . "\n";
  #print "-------------------------------------------------------------------------\n";
  #print $6 . "\n";
  #print "-------------------------------------------------------------------------\n";
  #print $7 . "\n";
  
  my $new_xml_str = $token_str . "=\"" . $filed_new_value . "\"" ;

  for (my $i = $#elements_tokens_in_converge_order; $i >= 0; --$i)
  {
    my $cur_element_token = $elements_tokens_in_converge_order[$i];
    my $cur_element_token_str = $bio_tokens_hash{$cur_element_token};

    $new_xml_str = "<" .$cur_element_token_str .$xml_parts[$main_element - ($#elements_tokens_in_converge_order - $i + 1)] .
                   $new_xml_str .
	           $xml_parts[$main_element + ($#elements_tokens_in_converge_order - $i + 1)]. "</" . $cur_element_token_str;
  }

  $new_xml_str = $xml_parts[0] .
                 $new_xml_str .
	         $xml_parts[$#xml_parts];

  #print "-------------------------------------------------------------------------\n";
  #print $new_xml_str . "\n";

  return $new_xml_str;

}


sub get_fieled_in_xml_str
{
  my ($xml_str, $token ,@elements_tokens_in_converge_order) = @_;

  my $bio_tokens_hash_ptr = &get_bio_tokens_hash();
  my %bio_tokens_hash = %$bio_tokens_hash_ptr;

  my $token_str = $bio_tokens_hash{$token};

  my $reg_str = $token_str . "=\"([\\w|\\.|\\s]*)\"" ;

  my $elements_count = 1;

  for (my $i = $#elements_tokens_in_converge_order; $i >= 0; --$i)
  {
    my $cur_element_token = $elements_tokens_in_converge_order[$i];
    my $cur_element_token_str = $bio_tokens_hash{$cur_element_token};

    $reg_str = "<" .$cur_element_token_str . "(.*)" . $reg_str . "(.*)" . "</" . $cur_element_token_str;
    $elements_count = $elements_count + 2;
  }
  $reg_str = "(.*)" . $reg_str ."(.*)";
  $elements_count = $elements_count + 2;

  my $main_element = (int ($elements_count/2));

  my @xml_parts = ($xml_str =~ m/$reg_str/s);

  print $xml_str . "\n";
  print "-------------------------------------------------------------------------\n";
  print $reg_str . "\n" . $elements_count . "\n" . $main_element . "\n";
  print "-------------------------------------------------------------------------\n";
  print $xml_parts[$main_element] . "\n";
  
  return $xml_parts[$main_element];

}

