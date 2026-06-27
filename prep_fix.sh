#!/usr/bin/env bash
set -u
cd /data/screen
mkdir -p ligands
# rebuild the worklist: only compounds without a finished .pdbqt
: > todo.tsv
while IFS=, read -r id smi; do
  if [ ! -s "ligands/${id}.pdbqt" ]; then printf '%s\t%s\n' "$id" "$smi"; fi
done < index.csv
echo "remaining to prep: $(wc -l < todo.tsv)  (all 16 cores)"
xargs -P 16 -a todo.tsv -d '\n' -I{} bash -c '
  line="$1"; id="${line%%	*}"; smi="${line#*	}"
  obabel -:"$smi" --gen3d -h -O "ligands/${id}.pdbqt" >/dev/null 2>&1 || rm -f "ligands/${id}.pdbqt"
' _ {}
echo "DONE. total ready: $(ls ligands/*.pdbqt 2>/dev/null | wc -l)"
