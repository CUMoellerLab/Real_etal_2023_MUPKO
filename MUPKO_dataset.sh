# Bash script to taxonomically classify raw FASTQ sequence data

## Download FASTQ sequence data from NCBI’s Sequence Read Archive under accession no. PRJNA995784.
## Only samples from Timepoint "HC" were included in this analysis

screen -S MUPKO

cd /path/to/directory/with/data

## The Moeller Lab Metagenomics Processing Pipeline was used for quality control and host filtering
### Please refer to sn-mg-pipeline.git README.md on how to use pipeline

## Get snakemake pipeline ready
git clone https://github.com/CUMoellerLab/sn-mg-pipeline.git
cd sn-mg-pipeline

  ### Edit samples.txt and units.txt
  ### Edit config.yaml

## Make copy of zipped sequences folder to keep as a backup
cp -r /path/to/directory/with/data/original_unrarefied /path/to/directory/with/data/original_unrarefied_backup

## Unzip data (.gz --> .fastq) --> may take some time
gzip -d /path/to/directory/with/data/original_unrarefied/*.gz

## Quality control and host filter unrarefied reads

conda activate snakemake

cd /path/to/directory/with/data/sn-mg-pipeline

### Create a samplelist.txt where each line is the Sample_ID and *the last line is empty*; if there is no line under the last sample, it might not be included in the analysis

cat samplelist.txt | while read -r LINE;
  do
    sample=$LINE;

    nice -n 10 snakemake -c all --use-conda --conda-prefix ~/snakemake_envs \
    -k output/qc/host_filter/nonhost/$sample.{R1,R2}.fastq.gz \
    --rerun-incomplete --restart-times 5 -n
done

### Make a backup copy of the QC and host filtered sequences
#### *This is important!* MetaPhlan 4 tends to rewrite original .fastq files with the profiles.txt

cp -r output/qc/host_filter/nonhost output/qc/host_filter/nonhost_unraref_backup


## Make Metaphlan 4 profiles from unrarefied reads
### Please refer to https://huttenhower.sph.harvard.edu/metaphlan/ and https://github.com/biobakery/MetaPhlAn/wiki/MetaPhlAn-4#installation for more information on MetaPhlan 4.0

### Install Metaphlan 4.0

conda activate
conda install -c bioconda metaphlan
conda create --name mpa -c conda-forge -c bioconda python=3.7 metaphlan
conda update -n base -c defaults conda

### Before using MetaPhlAn, you should activate the mpa environment:
conda activate mpa

### If you have installed MetaPhlAn using Anaconda, it is advised to install the database in a folder outside the Conda environment.

metaphlan --install --bowtie2db /local/workdir/dbs/metaphlan4

### We had metaphlan 4 installed on our lab server too, and we included it in our PATH like this:
export PYTHONPATH=/programs/metaphlan-4.0.3/lib/python3.9/site-packages:/programs/metaphlan-4.0.3/lib64/python3.9/site-packages
export PATH=/programs/metaphlan-4.0.3/bin:$PATH

### Create the necessary directories
cd /path/to/directory/with/data/sn-mg-pipeline/output/profile/metaphlan/metaphlan4/unraref

mkdir bowtie2s
mkdir sams
mkdir profiles
mkdir consensus_markers

### Run while loop for every row in your samplelist.txt
cat samplelist.txt | while read -r LINE;
  do
    sample=$LINE;
    echo "Processing Sample ${sample}";

    file1="${sample}.R1.fastq.gz";
    echo "Reading in R1 ${file1}";

    file2="${sample}.R2.fastq.gz";
    echo "Reading in R2 ${file2}"

    metaphlan -v

    file_bowtie2="${sample}.bowtie2.bz2"
    file_sam="${sample}.sam.bz2"
    file_profile="${sample}.txt"

    nice -n 5 metaphlan output/qc/host_filter/nonhost/$file1 output/qc/host_filter/nonhost/$file2 \
    --input_type fastq --nproc 50 --add_viruses --unclassified_estimation \
    --bowtie2out output/profile/metaphlan/metaphlan4/unraref/bowtie2s/${file_bowtie2}  \
    -s output/profile/metaphlan/metaphlan4/unraref/sams/${file_sam}  \
    -o output/profile/metaphlan/metaphlan4/unraref/profiles/${file_profile} \
    --bowtie2db /local/workdir/dbs/metaphlan4

    sample2markers.py -i output/profile/metaphlan/metaphlan4/unraref/sams/${file_sam} \
     -o output/profile/metaphlan/metaphlan4/consensus_markers -n 8
done >> output/logs/profile/metaphlan/metaphlan4/metaphlan4_230711_log.txt 2>&1

### The profiles.txt will not be found in the profiles directory but in output/qc/host_filter/nonhost/
### This is why it is crucial to backup the QC and host-filtered fastq files
### Move profiles from output/qc/host_filter/nonhost/ to output/profile/metaphlan/metaphlan4/profiles/

cd /path/to/directory/with/data/sn-mg-pipeline/output/profile/metaphlan/metaphlan4/unraref/profiles

find . -wholename "*.R2.fastq.gz" | sed "p;s/.R2.fastq.gz/.txt/" | xargs -d '\n' -n 2 mv

### Merge profiles into abundance table

merge_metaphlan_tables.py *.txt > Stress_mpa4_unraref_hostfilter.txt


## Rarefy
### We rarefied fastq to 1 million reads before taxonomically classifying them with MetaPhlan 4.0
### The rarefied profiles were used for alpha and beta diversity analyses
### Refer to https://github.com/lh3/seqtk

### Install seqtk
git clone https://github.com/lh3/seqtk.git;
cd seqtk; make
export PATH=/programs/seqtk:$PATH

mkdir /path/to/directory/with/data/rarefied

cd /path/to/directory/with/data

### Create a file listofprefixes.txt with the file name prefixes (shared portion of the name between R1 and R2)

### Run while loop
cat listofprefixes.txt | while read -r LINE;
  do
    file=$LINE;

    file1="${file%_*}_R1.fastq";

    file2="${file%_*}_R2.fastq";

    seqtk sample -s100 original_unrarefied/${file1} 1000000 > rarefied/${file%_*}_raref_R1.fastq
    seqtk sample -s100 original_unrarefied/${file2} 1000000 > rarefied/${file%_*}_raref_R2.fastq
done

### Repeat previously described quality control, holst-filtering, and MetaPhlan 4.0 classification for rarefied reads!