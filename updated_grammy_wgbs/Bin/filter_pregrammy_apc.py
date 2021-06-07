import sys
import pandas as pd
import numpy as np
import scipy as scp
import random as rd
from time import time
import multiprocessing as mp

def get_new_blast(paired_name):
    tmp_array = np.array([]) ;
    tmp_id_blast_1 = blast[blast.iloc[:,0].str.contains(paired_name+"-1")] ;
    tmp_id_blast_2 = blast[blast.iloc[:,0].str.contains(paired_name+"-2")] ;
    tmp_r1_taxids = tmp_id_blast_1.iloc[:,taxid_col] ;
    tmp_r2_taxids = tmp_id_blast_2.iloc[:,taxid_col] ;
    tmp_paired_ids = list(set(tmp_r1_taxids) & set(tmp_r2_taxids)) ;
    for j in tmp_paired_ids:
        min_r1_score = min(tmp_id_blast_1[tmp_id_blast_1.iloc[:,taxid_col] == j][eval_col]) ;
        min_r2_score = min(tmp_id_blast_2[tmp_id_blast_2.iloc[:,taxid_col] == j][eval_col]) ;
        r1_stpos = np.unique(np.array(tmp_id_blast_1[(tmp_id_blast_1.iloc[:,taxid_col] == j)&(tmp_id_blast_1.iloc[:,eval_col] == min_r1_score)][st_col])) ;
        r2_stpos = np.unique(np.array(tmp_id_blast_2[(tmp_id_blast_2.iloc[:,taxid_col] == j)&(tmp_id_blast_2.iloc[:,eval_col] == min_r2_score)][st_col])) ;
        r1_endpos = np.unique(np.array(tmp_id_blast_1[(tmp_id_blast_1.iloc[:,taxid_col] == j)&(tmp_id_blast_1.iloc[:,eval_col] == min_r1_score)][end_col])) ;
        r2_endpos = np.unique(np.array(tmp_id_blast_2[(tmp_id_blast_2.iloc[:,taxid_col] == j)&(tmp_id_blast_2.iloc[:,eval_col] == min_r2_score)][end_col])) ;
        score = (min_r1_score+min_r2_score)/2 ;
        vec = ([r1_stpos, r2_stpos],
               [r1_stpos, r2_endpos],
               [r1_endpos, r2_stpos],
               [r1_endpos, r2_endpos]) ;
        distance = ([np.min(np.absolute(np.sum(np.array(np.meshgrid(r1_stpos, -1*r2_stpos)).T.reshape(-1,2),axis=1))),
                        np.min(np.absolute(np.sum(np.array(np.meshgrid(r1_stpos, -1*r2_endpos)).T.reshape(-1,2),axis=1))),
                        np.min(np.absolute(np.sum(np.array(np.meshgrid(r1_endpos, -1*r2_stpos)).T.reshape(-1,2),axis=1))),
                        np.min(np.absolute(np.sum(np.array(np.meshgrid(r1_endpos, -1*r2_endpos)).T.reshape(-1,2),axis=1)))]) ;
        dist = max(distance) ;
        stvector = vec[distance.index(max(distance))][0] ;
        endvector = vec[distance.index(max(distance))][1][:, np.newaxis] ;

        logic = (abs(stvector - endvector) == dist) ;
        if any(np.array(logic.shape) == 1) :
            start = np.asscalar(stvector[np.asscalar(np.array(np.where(logic))[1])])
            end = np.asscalar(endvector[np.asscalar(np.array(np.where(logic))[0])])
        else :
            lnum = rd.sample(range(0,np.count_nonzero(logic)),1)
            start = np.asscalar(stvector[np.asscalar(np.array(np.where(logic))[:,lnum][1])])
            end = np.asscalar(endvector[np.asscalar(np.array(np.where(logic))[:,lnum][0])])
        #result = [paired_name+"-M", "gi", "100.0", dist+1, "0", "0", "1", "76", start, end, score, dist, j, "common_name" , "kingdom", dist+1]
        result = [paired_name+"-M", "gi", "100.0", dist+1, "0", "0", "1", "76", start, end, score, dist, dist+1, "strand", j]
        tmp_array = np.append(tmp_array, result)
    return(tmp_array)

st_col,end_col,eval_col,taxid_col = 8,9,10,14 ;

#path = str(sys.argv[1]) ;
#sample = str(sys.argv[2]) ;

tblat0 = sys.argv[1]
match = sys.argv[2]
combo = sys.argv[3]
threads = int(sys.argv[4])

# read input from blast
blast = pd.read_table(tblat0, sep='\t', header=None) ;

#subset full file to r1, r2, -c
blast_r1 = blast[blast.iloc[:,0].str.contains('-1')] ;
blast_r2 = blast[blast.iloc[:,0].str.contains('-2')] ;
blast_c = blast[blast.iloc[:,0].str.contains('-C')] ;
# Get r1 and r2 names
r1_names = list(map(lambda i: i[ : -2], blast_r1.iloc[:,0].unique())) ;
r2_names = list(map(lambda i: i[ : -2], blast_r2.iloc[:,0].unique())) ;
# Intersection of set names. (Only r1 that is common in r2 and vice versa)
paired_names = list(set(r2_names) & set(r1_names)) ;
print(len(paired_names))
#pool = mp.Pool(mp.cpu_count())
pool = mp.Pool(threads)

results = pool.map(get_new_blast, paired_names)
# I assume results is a list of lists that get concatenated

pool.close()

# Not sure what this is
finalarray = np.concatenate( results, axis=0 ).T.reshape(-1,15) ;
final = pd.DataFrame(data=finalarray[0:,0:]) ;

# -c is not touched and is concatenated in later steps
# -1 and -2 are now in a matched dataframe.
final.to_csv(match, header=False, index=False) ;
blast_c.to_csv(combo, header=False, index=False) ;
