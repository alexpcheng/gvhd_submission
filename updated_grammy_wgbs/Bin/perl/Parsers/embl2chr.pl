#!/usr/bin/perl


# note: i take the gene coordinates and CDS to determine the UTR, right now don't look at the transcripts at all
# right now this only takes out the UTRs 



use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $file_ref;
my $file = $ARGV[0];

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

if (length($file) < 1 or $file =~ /^-/) 
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

#get args from user
my %args = load_args(\@ARGV);
my $format = get_arg("f", "features", \%args);
my $stat = get_arg("stat", "", \%args);
my $predict = get_arg("predict", "", \%args);
my $min = get_arg("min", 10, \%args);
my $len = get_arg("len", 300, \%args);

# global counters
my $gene_counter = 0;
my $real_3utr_counter = 0;
my $real_5utr_counter = 0;
my $in_gene = 0;

# statistic array
my @stats_3utr;
my @stats_5utr;

# the info array holding the info for each gene
my @info;

my $ENTITIES = 4;
my $CHR = 0;
my $GENE = 1;
my $MRNA = 2;
my $CDS = 3;

my $FEATURES = 3;
my $START = 0;
my $FINISH = 1;
my $ID = 2;

#init the array
for(my $i=0; $i<$ENTITIES; $i++){
    for(my $j=0; $j<$FEATURES; $j++){
	$info[$i][$j] = -1;
    }
}

while(my $l=<$file_ref>){
    my @arr = split(" ", $l);
    if ($arr[0] eq "ID"){ #chr line
	$info[$CHR][$START] = $arr[1];	
    }
    if ($arr[0] eq "FT"){ #other entities
	if ($arr[1] eq "gene"){
	    $in_gene = 1;
	    $gene_counter++;
	    $arr[2] =~ s/\./ /g;
	    my @arr_gene = split(" ", $arr[2]);
	    if ($arr[2] =~ m/complement/){
		my @tmp = split(/\(/, $arr_gene[0]);
		$info[$GENE][$FINISH] = $tmp[1];	
		@tmp = split(/\)/, $arr_gene[1]);
		$info[$GENE][$START] = $tmp[0];	
	    }
	    else{
		$info[$GENE][$START] = $arr_gene[0];	
		$info[$GENE][$FINISH] = $arr_gene[1];	
	    }
	    $l=<$file_ref>;
	    my @arr_id = split("=", $l);
	    chomp($arr_id[1]);
	    $info[$GENE][$ID] = $arr_id[1];
	}
	if (($arr[1] eq "CDS") && ($in_gene)){
	    if ($arr[2] =~ m/complement/){
		my @tmp = split(/,/, $arr[2]);
		$tmp[0] =~ s/\./ /g;
		#print "start seq = ".$tmp[0]."\n";
		my @tmp1 = split(" ", $tmp[0]);
		my @tmp2 = split(/\)/, $tmp1[1]);
		$info[$CDS][$START] = $tmp2[0];
		my $last_line = $l;
		while(!(($l=<$file_ref>) =~ m/gene/)){
		    $last_line = $l;
		}
		#print "end seq = ".$last_line."\n";
		@tmp = split("t", $last_line);
		$tmp[scalar(@tmp)-1] =~ s/\./ /g;
		@tmp1 = split(" ", $tmp[scalar(@tmp)-1]);
		@tmp2 = split(/\(/, $tmp1[0]);
		$info[$CDS][$FINISH] = $tmp2[1];

	    }
	    else{
		my @tmp = split(/,/, $arr[2]);
		$tmp[0] =~ s/\./ /g;
		#print "start seq = ".$tmp[0]."\n";
		my @tmp1 = split(" ", $tmp[0]);
		$info[$CDS][$START] = $tmp1[1];
		my $last_line = $l;
		while(!(($l=<$file_ref>) =~ m/gene/)){
		    $last_line = $l;
		}
		#print "end seq = ".$last_line."\n";
		$last_line =~ s/\./ /g;
		@tmp = split(" ", $last_line);
		@tmp1 = split(/\)/, $tmp[scalar(@tmp)-1]);
		$info[$CDS][$FINISH] = $tmp1[0];
	    }

	    #finish and print data out
	    if ($format eq "features"){ #print features format
		print $info[$CHR][$START]."\t".$info[$GENE][$ID]."\t".$info[$GENE][$START]."\t".$info[$GENE][$FINISH]."\t"."mRNA"."\n";
		print $info[$CHR][$START]."\t".$info[$GENE][$ID]."\t".$info[$CDS][$START]."\t".$info[$CDS][$FINISH]."\t"."Coding"."\n";
		#print 5UTR
		if ((abs($info[$CDS][$START] - $info[$GENE][$START]) >= $min) || (!$predict)){ #real 5UTR or don't predict
		    print $info[$CHR][$START]."\t".$info[$GENE][$ID]."\t".$info[$GENE][$START]."\t".$info[$CDS][$START]."\t"."5UTR"."\n";
		}
		else{ #predict 5UTR
		    my $prediction = ($info[$GENE][$START] < $info[$GENE][$FINISH])? ($info[$GENE][$START]-$len) : ($info[$GENE][$START]+$len);
		    print $info[$CHR][$START]."\t".$info[$GENE][$ID]."\t".$prediction."\t".$info[$GENE][$START]."\t"."5UTR"."\n";
		}
		#print 3UTR
		if ((abs($info[$CDS][$FINISH] - $info[$GENE][$FINISH]) >= $min) || (!$predict)){ #real 3UTR or don't predict
		    print $info[$CHR][$START]."\t".$info[$GENE][$ID]."\t".$info[$CDS][$FINISH]."\t".$info[$GENE][$FINISH]."\t"."3UTR"."\n";
		}
		else{ #predict 3UTR
		    my $prediction = ($info[$GENE][$START] < $info[$GENE][$FINISH])? ($info[$GENE][$FINISH]+$len) : ($info[$GENE][$FINISH]-$len);
		    print $info[$CHR][$START]."\t".$info[$GENE][$ID]."\t".$info[$CDS][$FINISH]."\t".$prediction."\t"."3UTR"."\n";
		}
	    }
	    else { #print "data" format
		print $info[$CHR][$START]."\t".$info[$GENE][$ID]."\t".$info[$GENE][$START]."\t".$info[$GENE][$FINISH]."\n";
	    }
	    if ($stat){ #record statistics
		if (abs($info[$CDS][$FINISH] - $info[$GENE][$FINISH]) > 10){
		    $stats_3utr[$real_3utr_counter] = abs($info[$CDS][$FINISH] - $info[$GENE][$FINISH]);
		    $real_3utr_counter++;
		}
		if (abs($info[$CDS][$START] - $info[$GENE][$START]) > 10){
		    $stats_5utr[$real_5utr_counter] = abs($info[$CDS][$START] - $info[$GENE][$START]);
		    $real_5utr_counter++;
		}
	    }
	    #step out of gene (don't record more CDS in the same gene...)
	    $in_gene = 0;
	}
    }
}

if ($stat){ #output statistics
    my $sum3 = 0;
    my $sum5 = 0;
    for(my $j=0; $j<$real_3utr_counter; $j++){
	$sum3 += $stats_3utr[$j];
    }
    for(my $j=0; $j<$real_5utr_counter; $j++){
	$sum5 += $stats_5utr[$j];
    }
    my @sorted3 = sort(@stats_3utr);
    my $median3 = $sorted3[$real_3utr_counter/2];
    my $avg3 = $sum3/$real_3utr_counter;
    my @sorted5 = sort(@stats_5utr);
    my $median5 = $sorted5[$real_5utr_counter/2];
    my $avg5 = $sum5/$real_5utr_counter;
    
    print STDERR "5UTR: average = ".$avg5." median = ".$median5."\n";
    print STDERR "3UTR: average = ".$avg3." median = ".$median3."\n";
}




__DATA__

embl2chr.pl <file>

   Parses an EMBL format file into chr files

   -f <data|features>: format of output (default features)
   -stat: print statistics to standart error (default FALSE)
   -predict: boolean for predicting UTRs which are shorter than minimal (defualt FALSE)
   -min <num>: the minimal length of UTR to consider as a real UTR (default 10)
   -len <num>: length of UTR to predict when UTR is shorter than minimal (default 300)

