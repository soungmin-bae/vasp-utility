#!/bin/sh

if [ $# -lt 1 ]; then
cat <<_eot_
#-------------------------------------------------
#  splitchg chgfile(s) --> chgfile_up & chgfile_dn
#  (C version for multiple files)
#
#  Usage:
#     splitchg PARCHG-*   # process multiple files
#-------------------------------------------------
_eot_
    exit
fi

for chgcar in "$@"; do
    echo "Processing $chgcar ..."

    blank_line=(`awk 'NF==0 {print NR}' $chgcar`)
    let FFT_line=blank_line[0]+1

    FFT=`sed -n "$FFT_line p" $chgcar`
    NUM=`awk -v FFT_line=$FFT_line 'NR==FFT_line  {print $1*$2*$3}' $chgcar`
    column=`awk -v FFT_line=$FFT_line 'NR==FFT_line+1{print NF}' $chgcar`
    start_line=(`awk -v FFT="$FFT" '$0==FFT{printf "%d\n" ,NR+1}' $chgcar`)

    sed -n "1,$FFT_line p" $chgcar > ${chgcar}_up
    sed -n "1,$FFT_line p" $chgcar > ${chgcar}_dn
    sed -n "${start_line[0]},$ p" $chgcar > upd_$chgcar
    sed -n "${start_line[1]},$ p" $chgcar > umd_$chgcar

    cat > edit_$chgcar.c <<EOT
#include <stdio.h>
#include <stdlib.h>
#define NUM    $NUM
#define column $column
int main(){
    int i;
    double upd, umd;
    FILE *fin1,*fin2,*fout1,*fout2;
    fin1 = fopen("upd_$chgcar","r");
    fin2 = fopen("umd_$chgcar","r");
    fout1 = fopen("${chgcar}_up","a");
    fout2 = fopen("${chgcar}_dn","a");
    for(i=1;i<=NUM;i++){
        if(fscanf(fin1,"%lf",&upd)!=1) break;
        if(fscanf(fin2,"%lf",&umd)!=1) break;
        fprintf(fout1," %10.5f",(upd+umd)/2.0);
        fprintf(fout2," %10.5f",(upd-umd)/2.0);
        if(!(i%column)){ fprintf(fout1,"\n"); fprintf(fout2,"\n"); }
    }
    fclose(fin1); fclose(fin2); fclose(fout1); fclose(fout2);
    return 0;
}
EOT

    gcc -o edit_$chgcar edit_$chgcar.c
    ./edit_$chgcar
    rm edit_$chgcar* u*d_$chgcar
done
