#!/bin/bash
 
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=12G
#SBATCH --time=0-12:00:00
#SBATCH --output=../logs/slam%j.stdout
#SBATCH --mail-user=andrea.gillespie@petermac.org
#SBATCH --mail-type=END
#SBATCH --job-name="slamdunk"
#SBATCH --partition=prod_med

module load slamdunk/0.2.4
module load fastqc/0.11.6

bname=`basename $1 _R1_001.fastq.gz`
rl=75
Ref=/data/reference/dawson_labs/joint_genomes/Dm6Dr11/Dm6Dr11.fa
utr=/data/reference/dawson_labs/joint_genomes/Dm6Dr11/GRCz11Dm6allutrmerge.bed

mkdir ${bname}

java -jar /config/binaries/trimmomatic/0.39/trimmomatic-0.39.jar SE -threads 1 -phred33 $1 ${bname}/${bname}.trim.fq.gz ILLUMINACLIP:/config/binaries/trimmomatic/0.39/adapters/TruSeq3-SE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

fastqc -o ../fastqc $1

fastqc -o trim_fastqc/ ${bname}/${bname}.trim.fq.gz

srun -n 1 slamdunk all -r $Ref -b $utr -fb $utr -o ${bname}slamout -5 12 -n 100 -t 8 -m -mv 0.2 -mts -mbq 27 -rl $rl ${bname}/${bname}.trim.fq.gz

srun -n 1 alleyoop collapse -o collapse/ -t 1 ${bname}slamout/count/*tcount.tsv &

srun -n 1 alleyoop snpeval -o ${bname}slamout/ -s ${bname}slamout/snp/ -r $Ref -b $utr -l $rl -t 1 ${bname}slamout/filter/*_slamdunk_mapped_filtered.bam &
srun -n 1 alleyoop rates -o ${bname}slamout/ -r $Ref -t 1 ${bname}slamout/filter/*_slamdunk_mapped_filtered.bam &
srun -n 1 alleyoop tccontext -o ${bname}slamout/ -r $Ref -t 1 ${bname}slamout/filter/*_slamdunk_mapped_filtered.bam &
srun -n 1 alleyoop tcperutrpos -o ${bname}slamout/ -r $Ref -b $utr -s ${bname}slamout/snp/ -l $rl -t 1 ${bname}slamout/filter/*_slamdunk_mapped_filtered.bam &
srun -n 1 alleyoop tcperreadpos -o ${bname}slamout/ -r $Ref -s ${bname}slamout/snp/ -l $rl -t 1 ${bname}slamout/filter/*_slamdunk_mapped_filtered.bam &
srun -n 1 alleyoop utrrates -o ${bname}slamout/ -r $Ref -l $rl -t 1 -b $utr ${bname}slamout/filter/*_slamdunk_mapped_filtered.bam &

wait
