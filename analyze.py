import csv
from rdkit import Chem
from rdkit.Chem import Descriptors

smi = {}
with open('/data/screen/index.csv') as f:
    for row in csv.reader(f):
        if len(row) >= 2:
            smi[row[0]] = row[1]

rows = []
with open('/data/screen/results.csv') as f:
    r = csv.reader(f); next(r, None)
    for row in r:
        if len(row) < 2 or row[1] == 'NA':
            continue
        try: a = float(row[1])
        except: continue
        s = smi.get(row[0])
        if not s: continue
        m = Chem.MolFromSmiles(s)
        if m is None: continue
        mw = Descriptors.MolWt(m)
        hev = m.GetNumHeavyAtoms()
        le = a / hev if hev else 0
        ik = Chem.MolToInchiKey(m)
        rows.append((a, row[0], mw, hev, le, ik, s))

print(f"parsed {len(rows)} docked compounds with valid structures")
dl = [x for x in rows if 250 <= x[2] <= 600]
print(f"drug-like (MW 250-600): {len(dl)} compounds\n")
dl.sort(key=lambda x: x[0])

print("=== TOP 25 DRUG-LIKE HITS (by docking score) ===")
print(f"{'rk':<4}{'id':<10}{'score':<8}{'MW':<8}{'HA':<5}{'LE':<8}{'InChIKey':<29}smiles")
for i,(a,cid,mw,hev,le,ik,s) in enumerate(dl[:25],1):
    print(f"{i:<4}{cid:<10}{a:<8.2f}{mw:<8.1f}{hev:<5}{le:<8.3f}{ik:<29}{s[:38]}")

with open('/data/screen/ranked_final.csv','w') as out:
    out.write("rank,id,affinity,MW,heavy_atoms,lig_eff,inchikey,smiles\n")
    for i,(a,cid,mw,hev,le,ik,s) in enumerate(dl,1):
        out.write(f"{i},{cid},{a:.2f},{mw:.1f},{hev},{le:.3f},{ik},{s}\n")
print("\nFull filtered list saved to screen/ranked_final.csv")
