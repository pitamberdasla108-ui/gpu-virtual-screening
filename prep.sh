#!/usr/bin/env bash
set -u
cd /data/screen
curl -sSL "https://raw.githubusercontent.com/SculpturatusLabs/FDA-approved_SMILES/main/FDA-approved_1951-2021.csv" -o fda_raw.csv
tr -d '\r' < fda_raw.csv | grep -viE '^smiles$' | grep -v '^[[:space:]]*$' > fda.smi
total=$(wc -l < fda.smi); echo "compounds to prep: $total"
mkdir -p ligands; : > index.csv; i=0; ok=0
while IFS= read -r smi; do
  i=$((i+1)); id=$(printf "cpd%05d" "$i")
  echo "$id,$smi" >> index.csv
  if obabel -:"$smi" --gen3d -h -O "ligands/${id}.pdbqt" >/dev/null 2>&1 && [ -s "ligands/${id}.pdbqt" ]; then
    ok=$((ok+1)); else rm -f "ligands/${id}.pdbqt"; fi
  [ $((i % 50)) -eq 0 ] && echo "  prepped $i/$total ..."
done < fda.smi
echo "DONE prep: $ok of $total ligands ready"
