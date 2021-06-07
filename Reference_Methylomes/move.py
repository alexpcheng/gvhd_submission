import os
with open('old_lookup_table.txt') as old_file:
    for old_line in old_file:
        old_download = old_line.strip().split('\t')[3]
        old_name = old_line.strip().split('\t')[2]
        with open('lookup_table.txt') as new_file:
            for new_line in new_file:
                #print(new_line)
                #print(old_line)
                new_download = new_line.strip().split('\t')[3]
                if old_download == new_download:
                    new_name = new_line.strip().split('\t')[2]
                    old_sbp_file = f'preprocessing_references/old_singleBP_bedGraph/{old_name}.singlebp.bedGraph'
                    new_sbp_file = f'preprocessing_references/singleBP_bedGraph/{new_name}.singlebp.bedGraph'
                    print(old_download)
                    print(new_download)
                    print(old_name)
                    print(new_name)
                    os.system(f'cp {old_sbp_file} {new_sbp_file}')
print('done!')
