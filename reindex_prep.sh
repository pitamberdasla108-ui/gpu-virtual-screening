#!/usr/bin/env bash
set -u
cd /data/screen
# rebuild a clean index straight from the source, skipping any header
i=0; : > index.csv
while IFS= read -r smi; do
  [ -z "$smi" ] && continue
  case "$smi" in SMILES|smiles) continue;; esac
  i=$((i+1)); printf 'cpd%05d,%s\n' "$i" "$smi" >> index.csv
done < fda.smi
echo "clean index entries: $(wc -l < index.csv)"
mkdir -p ligands
# worklist = anything in the clean index without a finished file
: > todo.tsv
while IFS=, read -r id smi; do
  [ -s "ligands/${id}.pdbqt" ] || printf '%s\t%s\n' "$id" "$smi"
done < index.csv
echo "remaining to prep: $(wc -l < todo.tsv)  (all 16 cores)"
xargs -P 16 -a todo.tsv -d '\n' -I{} bash -c '
  line="$1"; id="${line%%	*}"; smi="${line#*	}"
  obabel -:"$smi" --gen3d -h -O "ligands/${id}.pdbqt" >/dev/null 2>&1 || rm -f "ligands/${id}.pdbqt"
' _ {}
echo "DONE. total ready: $(ls ligands/*.pdbqt 2>/dev/null | wc -l)"
