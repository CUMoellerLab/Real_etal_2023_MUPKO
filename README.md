# Real_etal_2023_MUPKO
Reproducibility data and code for [Real et al. 2023, "Major urinary protein (_Mup_) gene family deletion drives sex-specific alterations in the house mouse gut microbiota"](https://doi.org/10.1128/spectrum.03566-23).

## Raw data
FASTQ sequence data and the associated metadata can be found in NCBI’s Sequence Read Archive under accession no. [PRJNA995784](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA995784).

## MUPKO_dataset.sh
Bash script used to get MetaPhlan 4.0 taxonomic profiles from raw FASTQ sequence data and to functionally annotate MAGs with Bakta.

## MUPKO_analyses.Rmd
R markdown file with code used to produce the figures and tables included in Real et al. 2023.

## Supplemental_Tables
Supplemental tables not included in the main body of Real et al. 2023.

**Table S1** Results from PERMANOVA and PERMDISP testing the effect of mouse sex on the taxonomic and functional composition of the gut microbiota.

**Table S2** Results from PERMANOVA and PERMDISP testing the effect of _Mup_ genotype on the taxonomic and functional composition of the gut microbiota.

**Table S3** Results from Procrustes testing the correspondence between the taxonomic and functional profiles.

**Table S4** Results from linear mixed-effects models testing the effect of _Mup_ genotype on the taxonomic and functional diversity of the gut microbiota.

**Table S5** Results from ANCOM-BC2 testing the differential abundance of specific taxa and/or functions between _Mup_ KO and WT mice.

**Table S6** Results from hypergeometric tests of COG Category enrichment.
