#!/usr/bin/env bash
set -u
cd /data/screen
# join scores with smiles
awk -F, 'NR==FNR{s[$1]=$2; next} FNR>1 && $2!="NA"{print $1","$2","s[$1]}' index.csv results.csv > j.csv
echo "computing ligand efficiency for $(wc -l < j.csv) compounds..."
: > le_tmp.csv
while IFS=, read -r id aff smi; do
  hev=$(printf '%s' "$smi" | grep -oiE 'Cl|Br|[CNOSPFI]' | wc -l)
  [ "$hev" -lt 1 ] && hev=1
  le=$(awk "BEGIN{printf \"%.3f\", $aff/$hev}")
  echo "$id,$aff,$hev,$le,$smi" >> le_tmp.csv
done < j.csv
sort -t, -k4 -g le_tmp.csv > le_sorted.csv
{ echo "rank,id,affinity,heavy_atoms,lig_eff,smiles"
  awk -F, '{printf "%d,%s,%s,%s,%s,%s\n",NR,$1,$2,$3,$4,$5}' le_sorted.csv; } > ranked_LE.csv
echo "=== TOP 20 by LIGAND EFFICIENCY ==="
head -21 ranked_LE.csv
