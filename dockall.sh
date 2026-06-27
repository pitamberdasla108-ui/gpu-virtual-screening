#!/usr/bin/env bash
set -u
cd /data; mkdir -p screen/out
RESULTS=screen/results.csv; echo "id,affinity_kcal_per_mol" > "$RESULTS"
total=$(ls screen/ligands/*.pdbqt 2>/dev/null | wc -l)
echo "docking $total ligands on the GPU..."; i=0
for lig in screen/ligands/*.pdbqt; do
  i=$((i+1)); id=$(basename "$lig" .pdbqt)
  e=$(timeout 120 autodock_gpu_128wi --lfile "$lig" --ffile receptor.maps.fld --nrun 10 --resnam screen/out/"$id" 2>/dev/null \
      | grep "best inter + intra" | tail -1 | grep -oE '\-?[0-9]+\.[0-9]+')
  [ -z "$e" ] && e="NA"
  echo "$id,$e" >> "$RESULTS"; rm -f screen/out/"$id".dlg screen/out/"$id".xml
  [ $((i % 50)) -eq 0 ] && echo "  docked $i/$total ..."
done
echo "DONE."
