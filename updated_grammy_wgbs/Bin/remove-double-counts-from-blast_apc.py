#!/usr/bin/env python
# Selects only one read from a pair from BLAST results
# Usage: ./<this>.py <blast file> <orphan list>

import sys
from collections import defaultdict

blast1 = defaultdict(lambda: defaultdict(list))
blast2 = defaultdict(lambda: defaultdict(list))

def rm_suffix(name):
    return name[:-2]

def get_suffix(name):
    return name[-1]

tblat0=sys.argv[1]
tblat1=sys.argv[2]

with open(tblat0) as f, open(tblat1, 'w') as w:
    for line in f:
        parts = line.split()
        query = parts[0]
        target = parts[1]
        suffix = get_suffix(query)
        if suffix == "C":
            w.write(line)
        else:
            if suffix == "1":
                blast1[target][rm_suffix(query)].append(line)
            elif suffix == "2":
                blast2[target][rm_suffix(query)].append(line)

    for target in blast1:
        for query in blast1[target]:
            if len(blast2[target][query]) >= 1:
                w.write(blast1[target][query][0])
