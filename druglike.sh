#!/usr/bin/env bash
set -u
cd /data/screen
echo "filtering to drug-like size (18-45 heavy atoms), then ranking by score..."
awk -F, '$3>=18 && $3<=45' le_sorted.csv | sort -t, -k2 -g > druglike_sorted.csv
{ echo "rank,id,affinity,heavy_atoms,lig_eff,smiles"
  awk -F, '{printf "%d,%s,%s,%s,%s,%s\n",NR,$1,$2,$3,$4,$5}' druglike_sorted.csv; } > ranked_druglike.csv
echo "=== TOP 20 (drug-like size, best score) ==="
head -21 ranked_druglike.csv
