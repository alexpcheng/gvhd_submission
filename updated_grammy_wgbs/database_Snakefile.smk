
##################################
# Creating the GRAMMy databases needed for metagenome analysis in wgbs
##################################

#CONFIG PARAMETERS

configfile: 'database_config.yaml'
CLUSTER = config['CLUSTER']
SGREP=config['SGREP']
GRAMMY_GDT= CLUSTER + config['GRAMMY_GDT']
HSBLAST = CLUSTER + config['HSBLAST']
#######################
rule all:
	input:
		expand('databases/blast/{conversion}_conversion/NCBIGenomes06_{conversion}.fna', conversion = ['CT', 'GA']),
		expand('databases/blast/NCBIGenomes06.{ext}', ext = ['gis', 'gis.taxids']),
		expand('logs/grammy/grammy_prompts_{conversion}', conversion=['CT', 'GA'])

########################
rule convert_reference:
	input:
		reference_fasta = 'databases/GenomeDB/NCBIGenomes06.fna'
	output:
		CT_ref_fasta = 'databases/blast/CT_conversion/NCBIGenomes06_CT.fna',
		GA_ref_fasta = 'databases/blast/GA_conversion/NCBIGenomes06_GA.fna',
		read_ids = 'databases/GenomeDB/NCBIGenomes06_readsIDs.txt'
	shell:
		"""
		python Bin/reference_conversion_wgbs.py {input.reference_fasta} {output.CT_ref_fasta} {output.GA_ref_fasta} {output.read_ids}
		"""

rule gi_to_taxid:
	input:
		database_read_ids='databases/GenomeDB/NCBIGenomes06_readsIDs.txt',
		dmp='databases/GenomeDB/gi_taxid_nucl.dmp'
	output:
		taxids='databases/blast/NCBIGenomes06.gis.taxids',
		just_gi = 'databases/blast/NCBIGenomes06.gis'
	shell:
		"""
		cat {input.database_read_ids} | while read gi
		do
			taxid=$({SGREP} -n $gi {input.dmp} | cut -f 2,3 || true)
			if [ ! -z "$taxid" ]
			then
				echo -e "$gi\t$taxid" >> {output.taxids}
			fi
		done
		cut -f1 {output.taxids} > {output.just_gi}
		"""

rule create_blast_database:
	input:
		taxids='databases/blast/NCBIGenomes06.gis.taxids',
		genome='databases/blast/{conversion}_conversion/NCBIGenomes06_{conversion}.fna',
		just_gi = 'databases/blast/NCBIGenomes06.gis'
	output:
		hs_blast = 'databases/blast/{conversion}_conversion/NCBIGenomes06_{conversion}.fna.header'
	log:
		'logs/databases/{conversion}_database.log'
	params:
		out_path = 'databases/blast/{conversion}_conversion/',
		out_prefix='NCBIGenomes06_{conversion}'
	shell:
		"""
		makeblastdb -in {input.genome} -out {params.out_path}{params.out_prefix} -dbtype nucl -parse_seqids -taxid_map {input.taxids} &>{log}
		cd databases/blast/{wildcards.conversion}_conversion/
		blastdb_aliastool -db {params.out_prefix} -gilist ../../../{input.just_gi} -dbtype nucl -out {params.out_prefix}.curated
		cd ../../../
		{HSBLAST} index {input.genome} &>>{log}
		"""

rule create_grammy_database:
	input:
		genome='databases/blast/{conversion}_conversion/NCBIGenomes06_{conversion}.fna',
		taxids='databases/blast/NCBIGenomes06.gis.taxids',
		hs_blast = 'databases/blast/{conversion}_conversion/NCBIGenomes06_{conversion}.fna.header'
	output:
		prompt='logs/grammy/grammy_prompts_{conversion}',
		taxids='grefs/{conversion}/gid_tid.dmp'
	threads: 12
	params:
		genome_prefix='databases/blast/{conversion}_conversion/NCBIGenomes06_{conversion}',
		genome='NCBIGenomes06_{conversion}'
	shell:
		"""
		rm -f {output.prompt}
		mkdir -p grefs
		mkdir -p grefs/{wildcards.conversion}
		blastdbcmd -db {params.genome_prefix}.curated -entry all -outfmt "%T" | sort | uniq | while read taxid
		do
			echo "./Bin/build.grefs.sh {params.genome_prefix} $taxid {input.taxids} {wildcards.conversion}" >> {output.prompt}
		done
#		perl_fork_univ.pl {output.prompt} {threads}

		cp {input.taxids} {output.taxids}
		TIDS=$(cat {input.taxids} | cut -f2 | sort -u | tr '\n' ',')
		TAXIDS=${{TIDS::-1}}

		python2.7 {GRAMMY_GDT} -p 200000 -d {output.taxids} -r grefs/{wildcards.conversion} {params.genome} $TAXIDS
		mkdir -p grammy
		mv {params.genome}.gdt grammy
		"""
