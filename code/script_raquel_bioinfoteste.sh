#!/bin/bash
#Desenvolvido por Raquel Caldas
#v 1.0

#Comando: bash script_bioinfoteste.sh >> script_raquel_bioinfoteste.log 2>&1

sample_id="510-7-BRCA_S8_L001"

# Criando estrutura de pastas
mkdir -p 0.dados_brutos/fastqc 1.arquivos_trimados 2.alinhamento 3.vcf 4.anotacao_variantes

# Analisar a qualidade dos arquivos fastq
echo "Analisando a qualidade dos reads"
cd 0.dados_brutos
fastqc -o ./fastqc *.fastq.gz
if [ $? -eq 0 ]; then
    echo "Análise do FastQC concluída"
else
    echo "Erro na análise do FastQC"
    exit 1
fi

# Trimar os arquivos fastq
cd ../1.arquivos_trimados
echo "Filtrando reads com baixa qualidade"
cutadapt -q 30 -o "${sample_id}_R1_001_trimado.fastq.gz" "../0.dados_brutos/${sample_id}_R1_001.fastq.gz" 
cutadapt -q 30 -o "${sample_id}_R2_001_trimado.fastq.gz" "../0.dados_brutos/${sample_id}_R2_001.fastq.gz" 
if [ $? -eq 0 ]; then
    echo "Filtragem do Cutadapt concluída"
else
    echo "Erro na filtragem do Cutadapt"
    exit 1
fi

# Alinhando os arquivos fastq com o arquivo de referência
cd ../2.alinhamento
echo "Mapeando reads com a referência"
bwa mem -t 10 -R "@RG\tID:510-7\tSM:${sample_id}\tPL:ILLUMINA\tPU:unit1\tLB:lib1" ../bwa/hg19.fasta "../1.arquivos_trimados/${sample_id}_R1_001_trimado.fastq.gz" "../1.arquivos_trimados/${sample_id}_R2_001_trimado.fastq.gz" | samtools sort > "${sample_id}.bam" && samtools index "${sample_id}.bam"
if [ $? -eq 0 ]; then
    echo "Mapeamento com BWA concluído"
else
    echo "Erro no mapeamento com BWA"
    exit 1
fi

# Chamar as variantes com o Freebayes
cd ../3.vcf
echo "Chamando variantes com o Freebayes"
freebayes -f ../bwa/hg19.fasta --targets ../data/BRCA.list "../2.alinhamento/${sample_id}.bam" > "${sample_id}.vcf" 
if [ $? -eq 0 ]; then
    echo "Chamada de variantes com Freebayes concluída"
else
    echo "Erro na chamada de variantes com Freebayes"
    exit 1
fi

# Rodando o vcf no SnpEff
cd ../4.anotacao_variantes
echo "Anotando o vcf com o SnpEff"
snpEff -v hg19 "../3.vcf/${sample_id}.vcf" > "${sample_id}.ann.vcf"
if [ $? -eq 0 ]; then
    echo "Anotação com SnpEff concluída"
else
    echo "Erro na anotação com SnpEff"
    exit 1
fi
echo "Processamento concluído com sucesso"