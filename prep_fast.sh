#!/usr/bin/env bash
set -u
cd /data/screen
[ -f fda.smi ] || { tr -d '\r' < fda_raw.csv | grep -viE '^smiles$' | grep -v '^[[:space:]]*$' > fda.smi; }
[ -f index.csv ] || { i=0; : > index.csv; while IFS= read -r s; do i=$((i+1)); printf "cpd%05d,%s\n" "$i" "$s" >> index.csv; done < fda.smi; }
mkdir -p ligands
# build worklist of only the ones not already done
awk -F, '{print $1","$2}' index.csv | while IFS=, read -r id smi; do
  [ -s "ligands/${id}.pdbqt" ] || printf '%s\t%s\n' "$id" "$smi"
done > todo.tsv
echo "remaining to prep: $(wc -l < todo.tsv)  (using all cores)"
cat todo.tsv | xargs -P 16 -d '\n' -I{} bash -c '
  id=$(printf "%s" "{}" | cut -f1); smi=$(printf "%s" "{}" | cut -f2-)
  obabel -:"$smi" --gen3d -h -O "ligands/${id}.pdbqt" >/dev/null 2>&1 || rm -f "ligands/${id}.pdbqt"
'
echo "DONE. total ready: $(ls ligands/*.pdbqt 2>/dev/null | wc -l)"
