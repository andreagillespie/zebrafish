#!/bin/bash
 
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=2G
#SBATCH --time=0-2:00:00
#SBATCH --output=logs/DTBamCov%j.stdout
#SBATCH --mail-user=andrea.gillespie@petermac.org
#SBATCH --mail-type=END
#SBATCH --job-name="DTBamCov"
#SBATCH --partition=prod_short

module load deeptools/3.0.0
module load samtools/1.17

bname=`basename $1 .trim.fq_slamdunk_mapped_filtered.bam`

# convert to bedgraph
bamCoverage -b $1 -o bedgraphs/${bname}.bdg -bs 1 -of bedgraph

# gzip and tabindex for faster loading
gzip bedgraphs/${bname}.bdg
tabix -p bed bedgraphs/${bname}.bdg.gz
