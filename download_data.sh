#!/bin/bash

#Set the project accession
ACCESSION=PRJEB22384

#Put everything in a folder
mkdir -p sequence_data
cd sequence_data

#Fetch the project file manifest
curl -sLo MANIFEST.txt "http://www.ebi.ac.uk/ena/data/warehouse/search?query=%22study_accession%3D%22${ACCESSION}%22%22&result=read_run&fields=fastq_ftp,sample_alias,sample_accession&display=report"
sed -i "s/;/\t/g" MANIFEST.txt

parallel wget ::: `cut -f 2 MANIFEST.txt | tail -n +2`
parallel wget ::: `cut -f 3 MANIFEST.txt | tail -n +2`

awk 'BEGIN{FS="\t"; print "sample-id\tdata\tlocation\tdate\tsubject\tsampletype\treplicate\tfull_name"}{if (NR>1) {col=$5; loc=substr(col,1,1); if (loc=="S" || loc == "L") { date=substr(col,2,4); subj=substr(col,7,2); stype=substr(col,9,1); rep=substr(col,10,1); print $1 "\t" "data\t" loc "\t" date "\t" subj "\t" stype "\t" rep "\t" $5;} else {print $1 "\tcontrol\t" "NA\tNA\tNA\tNA\tNA\t" $5;}}}' MANIFEST.txt > METADATA.txt
#Fetch the metadata for each sample
mkdir -p import_to_qiime

#Put the data into a QIIME-importable format
cd import_to_qiime
for accession in `cut -f 1 ../METADATA.txt | tail -n +2 | xargs`; do 
    ln -s ../${accession}_1.fastq.gz ${accession}_S0_L001_R1_001.fastq.gz
    ln -s ../${accession}_2.fastq.gz ${accession}_S0_L001_R2_001.fastq.gz 
done
ls -l *.fastq.gz | cut -d " " -f 9 | awk 'BEGIN{ORS=""; print "sample-id,filename,direction\n";} {if ($0~/R1/) {dir="forward"} else {dir="reverse"}; split($0, y, "_"); print y[1] "," $0 "," dir "\n";}' > MANIFEST
	echo "{'phred-offset': 33}" > metadata.yml
