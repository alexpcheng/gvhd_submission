#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/libfile.pl";


my $features_xml_template = "$ENV{TEMPLATES_HOME}/FeaturesComputation/sequence_location_features_computation.xml";
my $features_xml_template_help_file = "$ENV{TEMPLATES_HOME}/FeaturesComputation/sequence_location_features_computation_xml_help.txt";



if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

if ($ARGV[0] eq "--fxml_help") {
  system("cat $features_xml_template_help_file");
  exit;
}


my $r = int(rand(100000));
my $tmp_map = "tmp_$r.map";
my $tmp_clu = "tmp_$r.clu";


#
# Loading args:
#

my %args = load_args(\@ARGV);


my $print_map_file = get_arg("map", 0, \%args);
my $log_file = get_arg("log", "", \%args);
my $save_map_file = get_arg("smap", "", \%args);

my $features_xml_file = get_arg("fxml", "", \%args);

if ( $features_xml_file ne "" ) {
  RunFeaturesComputation($features_xml_file);
  exit;
}

$features_xml_file = "tmp_features_$r.xml";

my $features_xml_output_file = get_arg("fxml_out", "", \%args);
my $only_generate_features_xml_file = get_arg("fxml_gen", 0, \%args);

if ( $only_generate_features_xml_file and $features_xml_output_file eq "" ) {
  die "ERROR - -fxml_gen flag is set, yet output features xml file not given (using -fxml_out).\n";
}


my $features_matrix_name = get_arg("fmat_name", "", \%args);
my $fmat_name = "fmatrix_name=$features_matrix_name";

my $features_matrix_val_type = get_arg("fmat_val_type", "", \%args);
my $fmat_val_type = "fmatrix_val_type=$features_matrix_val_type";

my $features_matrix_output_file = get_arg("fmat_out", "", \%args);
die "ERROR - output feature matrix file name not given.\n" if ( $features_matrix_output_file eq "" );
my $fmat_out = "fmatrix_outfile=$features_matrix_output_file";

# Input sequences:
my $seqs = get_arg("seqs", "", \%args);
die "ERROR - input sequences properties not given.\n" if ( $seqs eq "" );

# Input locations:
my $locations = get_arg("locations", "", \%args);

# Sliding window:
my $sliding_window = get_arg("sliding_window", "", \%args);
die "ERROR - input sliding window properties not given.\n" if ( $sliding_window eq "" );

# Data managers:
my $seq_vars_data = get_arg("seq_vars_data", "", \%args);
my $seq_annotations_data = get_arg("seq_annotations_data", "", \%args);
my $pos_stats_data = get_arg("pos_stats_data", "", \%args);
my $av_occ_data = get_arg("av_occ_data", "", \%args);

# Features to compute:
my $f_nucleotide_set_content = get_arg("f_nucleotide_set_content", "", \%args);
my $f_kmer_occ = get_arg("f_kmer_occ", "", \%args);
my $f_polyA_polyT = get_arg("f_polyA_polyT", "", \%args);
my $f_CpG_repeats = get_arg("f_CpG_repeats", "", \%args);
my $f_pos_stats = get_arg("f_pos_stats", "", \%args);
my $f_av_occ = get_arg("f_av_occ", "", \%args);
my $f_annotations = get_arg("f_annotations", "", \%args);
my $f_annotations_X_nfr = get_arg("f_annotations_X_nfr", "", \%args);
my $f_pos_stats_X_nuc_av_occ = get_arg("f_pos_stats_X_nuc_av_occ", "", \%args);
my $f_gev = get_arg("f_gev", "", \%args);
my $f_gev_X_annotations = get_arg("f_gev_X_annotations", "", \%args);


 
my $bindings_to_use = get_arg("bindings_to_use", "all", \%args);
my @bindings_to_use_list = ();

my $use_all = 0;
if ( $bindings_to_use eq "all" ) {
    $use_all = 1;
}
else {
    @bindings_to_use_list = split(/,/, $bindings_to_use);
}


#
# Done loading args
#

InitFeaturesXMLFromTemplate($features_xml_file);


my @strings_with_properties_to_bind = ();
my @data_managers_to_remove = ();
my @features_to_remove = ();

push(@strings_with_properties_to_bind, $fmat_name) if ( $features_matrix_name ne "" );
push(@strings_with_properties_to_bind, $fmat_val_type) if ( $features_matrix_val_type ne "" );
push(@strings_with_properties_to_bind, $fmat_out);
push(@strings_with_properties_to_bind, $seqs);
push(@strings_with_properties_to_bind, $sliding_window);

if ( $locations eq "" ) {
  RemoveLocationsFromFeaturesXML($features_xml_file);
}
else {
  push(@strings_with_properties_to_bind, $locations);
}

CollectDataManagersToBindOrRemove();

CollectFeaturesToBindOrRemove();

BindPropertiesToFeaturesXML($features_xml_file);

RemoveUnwantedDataManagersFromFeaturesXML($features_xml_file);

RemoveUnwantedFeaturesFromFeaturesXML($features_xml_file);

RemoveUnboundPropertiesFromFeaturesXML($features_xml_file);

RunFeaturesComputation($features_xml_file) unless ( $only_generate_features_xml_file );

system("mv $features_xml_file $features_xml_output_file") if ( $features_xml_output_file ne "" );
unlink $features_xml_file;


# End of main script
#
#######################


#######################
#
# Subroutines:

sub InitFeaturesXMLFromTemplate
{
  my ($features_xml_file) = @_;
  system("cp $features_xml_template $features_xml_file");
}


sub RemoveLocationsFromFeaturesXML
{
  my ($features_xml_file) = @_;
  my $tmp_out_file = "tmp_" . $features_xml_file;
  system("extract_lines_by_regexp.pl $features_xml_file -from \"<SequenceLocations\" -to \"</SequenceLocations\" -from_inclusive false -to_inclusive false -remove -out_file $tmp_out_file");
  system("mv $tmp_out_file $features_xml_file");
}


sub BindOrRemoveDataManager
{
    my ($bind_properties_str, $bind_option_name, $xml_name, $use_all) = @_;
    
    if ( $bind_properties_str eq "" ) { push(@data_managers_to_remove, $xml_name); }
    elsif ( $use_all ) { push(@strings_with_properties_to_bind, $bind_properties_str); }
    else {
	my $size = @bindings_to_use_list;
	my $i = 0;
	for ( ; $i < $size ; $i++ ) {
	    last if ( $bindings_to_use_list[$i] eq $bind_option_name );
	}
	if ( $i < $size ) { push(@strings_with_properties_to_bind, $bind_properties_str); }
	else { push(@data_managers_to_remove, $xml_name); }
    }
}


sub BindOrRemoveFeature
{
    my ($bind_properties_str, $bind_option_name, $xml_name, $use_all) = @_;
    
    if ( $bind_properties_str eq "" ) { push(@features_to_remove, $xml_name); }
    elsif ( $use_all ) { push(@strings_with_properties_to_bind, $bind_properties_str); }
    else {
	my $size = @bindings_to_use_list;
	my $i = 0;
	for ( ; $i < $size ; $i++ ) {
	    last if ( $bindings_to_use_list[$i] eq $bind_option_name );
	}
	if ( $i < $size ) { push(@strings_with_properties_to_bind, $bind_properties_str); }
	else { push(@features_to_remove, $xml_name); }
    }
}


sub CollectDataManagersToBindOrRemove
{
    BindOrRemoveDataManager($seq_vars_data, "seq_vars_data", "SequenceVariationsDataManager", $use_all);
    BindOrRemoveDataManager($seq_annotations_data, "seq_annotations_data", "SequenceAnnotationsDataManager", $use_all);
    BindOrRemoveDataManager($pos_stats_data, "pos_stats_data", "WeightMatricesPositionStatsDataManager", $use_all);
    BindOrRemoveDataManager($av_occ_data, "av_occ_data", "WeightMatricesAverageOccupancyDataManager", $use_all);
}


sub CollectFeaturesToBindOrRemove
{
    BindOrRemoveFeature($f_nucleotide_set_content, "f_nucleotide_set_content", "NucleotideSetContent", $use_all);
    BindOrRemoveFeature($f_kmer_occ, "f_kmer_occ", "KmerOccurrence", $use_all);
    BindOrRemoveFeature($f_polyA_polyT, "f_polyA_polyT", "PolyAPolyTTractLength", $use_all);
    BindOrRemoveFeature($f_CpG_repeats, "f_CpG_repeats", "CpGRepeatsTractLength", $use_all);
    BindOrRemoveFeature($f_pos_stats, "f_pos_stats", "WeightMatrixPositionStatsFeature", $use_all);
    BindOrRemoveFeature($f_av_occ, "f_av_occ", "WeightMatricesAverageOccupancyFeature", $use_all);
    BindOrRemoveFeature($f_annotations, "f_annotations", "SequenceAnnotationsFeature", $use_all);
    BindOrRemoveFeature($f_annotations_X_nfr, "f_annotations_X_nfr", "CrossingGenomicAnnotationWithNucleosomeDepletedRegionFeature", $use_all);
    BindOrRemoveFeature($f_pos_stats_X_nuc_av_occ, "f_pos_stats_X_nuc_av_occ", "CrossingWeightMatricesStatsWithNucleosomeAverageOccupancyFeature", $use_all);
    BindOrRemoveFeature($f_gev, "f_gev", "IndividualGeneticVariationFeature", $use_all);
    BindOrRemoveFeature($f_gev_X_annotations, "f_gev_X_annotations", "CrossingIndividualGeneticVariationWithGenomicAnnotationFeature", $use_all);
}


sub BindPropertiesToFeaturesXML
{
  my ($features_xml_file) = @_;
  my $tmp_out_file = "tmp_" . $features_xml_file;
  my $num = @strings_with_properties_to_bind;
  for ( my $i=0 ; $i < $num ; $i++ ) {
    my @property_equals_value_elements = split(/;/, $strings_with_properties_to_bind[$i]);
    my $num_props = @property_equals_value_elements;
    for ( my $j=0 ; $j < $num_props ; $j++ ) {
      my @prop = split(/=/, $property_equals_value_elements[$j]);
      open(FIN, $features_xml_file) or die "ERROR - failed to open file '$features_xml_file'\n";
      my $in_file_ref = \*FIN;
      open (FOUT, ">$tmp_out_file") or die "ERROR - failed to open output file '$tmp_out_file'\n";
      my $out_file_ref = \*FOUT;
      if ( scalar(@prop) == 2 ) {
	&ReplaceStringInFile($in_file_ref, $out_file_ref, "\"&".$prop[0]."\"", "\"".$prop[1]."\"");
      }
      elsif ( scalar(@prop) == 1 ) {
	&ReplaceStringInFile($in_file_ref, $out_file_ref, "\"&".$prop[0]."\"", "\"\"");
      }
      close FIN;
      close FOUT;
      system("mv $tmp_out_file $features_xml_file");
    }
  }
}


sub RemoveUnwantedDataManagersFromFeaturesXML
{
  my ($features_xml_file) = @_;
  my $tmp_out_file = "tmp_" . $features_xml_file;
  my $num = @data_managers_to_remove;
  for ( my $i=0 ; $i < $num ; $i++ ) {
    system("extract_lines_by_regexp.pl $features_xml_file -from \"$data_managers_to_remove[$i]\" -to \"</DataManager>\" -from_inclusive false -to_inclusive false -remove -out_file $tmp_out_file");
    system("mv $tmp_out_file $features_xml_file");
  }
}


sub RemoveUnwantedFeaturesFromFeaturesXML
{
  my ($features_xml_file) = @_;
  my $tmp_out_file = "tmp_" . $features_xml_file;
  my $num = @features_to_remove;
  for ( my $i=0 ; $i < $num ; $i++ ) {
    system("extract_lines_by_regexp.pl $features_xml_file -from \"$features_to_remove[$i]\" -to \"</Feature>\" -from_inclusive false -to_inclusive false -remove -out_file $tmp_out_file");
    system("mv $tmp_out_file $features_xml_file");
  }
}


sub RemoveUnboundPropertiesFromFeaturesXML
{
  my ($features_xml_file) = @_;
  my $tmp_out_file = "tmp_" . $features_xml_file;
  system("cat $features_xml_file | grep -v \"&\" > $tmp_out_file");
  system("mv $tmp_out_file $features_xml_file");
}


sub RunFeaturesComputation
{
  my ($features_xml_file) = @_;

  my $exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/run_compute_features.map");
  $exec_str .= &AddStringProperty("FEATURES_XML_FILE", $features_xml_file);
  &RunGenie($exec_str, $print_map_file, $tmp_map, $tmp_clu, $log_file, $save_map_file);
}

# End of subroutines
#
#######################



#
# END
#


__DATA__

compute_sequence_features.pl

  Computes sequence sliding window features of given (locations on) sequences.
  Outputs the computed feature matrix.

  Input to this script includes "regular" options, and options that detail properties to be bound
  into a template xml file that defines the features computations (see below).


  "Regular" Options:
  ------------------

  --help:                    prints this message.
  --fxml_help:               prints a help message describing the features xml template (see below) in detail.

  -map:                      print only the map file
  -log <str>:                print the stdout and stderr of the program into the file <str>
  -smap <str>:               save the map file into <str>

  -fxml <str>:               name of input features xml file to use. if given, no other input
                             is required, as this file includes all data required for the computation.

  -fxml_out <str>:           name of file to which the features xml that is generated will be written
  -fxml_gen:                 if set, then will only generate the features xml file (and write it to the
                             file given by '-fxml_out').

  -fmat_name <str>:          name of computed features matrix.
  -fmat_out <str>:           name of computed features matrix output file.

  -fmat_val_type <str>:      type of value of the features.
                             one of: AnyValue/Double/Int/Boolean/Char/String.


  Binding Options:
  ----------------
  The following options are used for binding of property values in the features xml file.
  The features xml template is in:
    Develop/Templates/FeaturesComputation/sequence_location_features_computation.xml

  For instance, consider the xml element in the template file that describes the input sequences
  (notice that property value strings to be bound are prefixed by a '&' character):

      <Sequences
                 File="&fasta"
                 Alphabet="&seqs_alphabet"
                 EffectiveAlphabetSize="&seqs_alphabet_size"
                 PreloadSequences="&preload_seqs"
      >
      </Sequences>

  An example of a command line input that binds its properties:
      -seqs "fasta=sequences.fa;seqs_alphabet=ACGT;seqs_alphabet_size=4;preload_seqs=false"

  Unbound elements will be removed.


  -seqs <str>:                     binding the input sequences properties. OBLIGATORY.

  -locations <str>:                binding the input locations properties. if not given, then features will be
                                   computed over entire input sequences.

  -sliding_window <str>:           binding the sliding window properties. OBLIGATORY.


  +++ 
  -seq_vars_data <str>:            binding properties for the sequence variations data manager.
  -seq_annotations_data <str>:     binding properties for the sequence annotations data manager.
  -pos_stats_data <str>:           binding properties for the weight matrices position stats data manager.
  -av_occ_data <str>:              binding properties for the weight matrices average occupancy data manager.

  -f_nucleotide_set_content <str>: binding properties for nucleotide set content features (e.g., GC-content).
  -f_kmer_occ <str>:               binding properties for kmer occurrence features.
  -f_polyA_polyT <str>:            binding properties for polyA/polyT max tract length features.
  -f_CpG_repeats <str>:            binding properties for CpG repeats max tract length features.
  -f_pos_stats <str>:              binding properties for features of weight matrix position stats.
  -f_av_occ <str>:                 binding properties for features of weight matrix/matrices average occupancy.
  -f_annotations <str>:            binding properties for features of genomic annotations.
  -f_annotations_X_nfr <str>:      binding properties for features of genomic annotations crossed with nucleosome depleted region.
  -f_pos_stats_X_nuc_av_occ <str>: binding properties for features of weight matrices position stats crossed with nucleosome average occupancy.
  -f_gev <str>:                    binding properties for features of genetic variations.
  -f_gev_X_annotations <str>:      binding properties for features of genetic variations crossed with genomic annotations.
  +++ 

  -bindings_to_use <str list>:     a comma seperated list of binding options to use.
                                   this allows to define only one makefile target that calls this script,
                                   with all binding options preset.
                                   Then, small makefile targets on top of it can tune the bindings_to_use list
                                   and define what subset of features (along with the relevant subset of data)
                                   to actually compute.
                                   to use all, use the "all" string as the bindings_to_use list (this is the default).

