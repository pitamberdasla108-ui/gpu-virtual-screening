# GPU-Accelerated Virtual Screening Pipeline

A self-hosted, CUDA-accelerated molecular docking pipeline for drug discovery, built and validated from scratch on consumer hardware (NVIDIA RTX 3090). The pipeline reproduces a known cancer drug–target interaction, screens a library of FDA-approved drugs against a leukemia target, and critically analyzes the scoring biases that affect virtual screening.

---

## What this project does

Molecular docking predicts how strongly a small molecule (a potential drug) binds to a target protein. This project builds an end-to-end docking pipeline and uses it to:

1. **Validate** the method by reproducing the known binding of approved leukemia drugs to their target (the c-Abl kinase).
2. **Screen** ~800 FDA-approved drugs against that target — a *drug repurposing* experiment asking "which existing drugs might also bind this cancer protein?"
3. **Analyze** the results rigorously, identifying and correcting for the systematic biases inherent to docking.

The emphasis is on *methodology and honest interpretation*, not on claiming discoveries. Docking scores are hypotheses to investigate, not conclusions.

---

## Target

- **Protein:** c-Abl tyrosine kinase — the constitutively active fusion protein (BCR-Abl) that drives chronic myeloid leukemia (CML).
- **Structure:** prepared receptor centered on the ATP-binding pocket (the site targeted by CML drugs).
- **Search box:** center (15.190, 53.903, 16.917), 24 Å cube.

## Library

- **~1,100 FDA-approved drugs** (SMILES), an openly licensed dataset.
- Ligands prepared (3D embedding, protonation, charge assignment) into PDBQT format; **957 successfully prepared**, **823 docked**.

---

## Validation (the key result)

Before trusting the pipeline on unknowns, it was validated against molecules with *known* behavior: four real CML drugs spanning three drug generations, plus two non-binding decoys (common drugs with no kinase activity).

| Compound | Class | Binding score (kcal/mol) |
|---|---|---|
| Ponatinib | 3rd-gen CML inhibitor | **−20.88** |
| Nilotinib | 2nd-gen CML inhibitor | **−19.71** |
| Dasatinib | 2nd-gen CML inhibitor | **−18.96** |
| Imatinib (Gleevec) | 1st-gen CML inhibitor | **−17.94** |
| Aspirin | decoy (non-binder) | −11.31 |
| Caffeine | decoy (non-binder) | −9.66 |

**All four real leukemia drugs cleanly outranked both decoys**, with a clear ~7–9 kcal/mol gap separating true binders (−18 to −21) from non-binders (−10 to −11). This enrichment confirms the pipeline correctly distinguishes real kinase inhibitors from random molecules. Notably, the ranking even tracks drug potency/generation — ponatinib (the most potent, designed to overcome resistance) scores strongest, the original imatinib weakest of the four. (Scores from AutoDock-GPU, AutoDock4 scoring function; full output in `results/`.)

---

## Screening & honest analysis

The validated pipeline was then run across the full FDA library. The raw ranked list is **not** taken at face value — and that's the point of the project:

- **Raw docking score is biased toward large molecules.** A bigger molecule makes more atomic contacts and scores more negatively regardless of true specificity. The top of the raw list was dominated by large antibiotics (e.g., aminoglycosides), metal chelators, and other high-mass compounds — *expected false positives*, not real hits.
- **Ligand efficiency (score ÷ heavy atoms) over-corrects** toward tiny fragments.
- The honest sweet spot is **drug-like molecules ranked within a sensible size range**, analyzed with proper cheminformatics (RDKit: molecular weight, heavy-atom count, InChIKey identification).

**Finding:** naive docking of a chemically diverse library is dominated by molecular-size artifacts; rigorous hit selection requires understanding and correcting these biases. Recognizing *which* top hits are artifacts (large polar/greasy molecules) versus plausible leads is the core skill demonstrated here.

A separate run using the **Vina scoring function** (less size-biased than AutoDock4) enriched genuine kinase inhibitors (lapatinib, sorafenib) near the top of the same library — illustrating that *scoring-function choice materially changes results*, a real and important consideration.

---

## Engineering notes

- **Stack:** Windows + WSL2 → Docker → NVIDIA Container Toolkit → **AutoDock-GPU (CUDA)** on an RTX 3090.
- **Speed:** GPU docking completed in **seconds per compound** vs. ~90 s on a CPU NAS — roughly a 100× speedup, making library-scale screening practical.
- **Grid maps** generated with AutoGrid4; ligand prep via Open Babel / RDKit + Meeko.
- **Platform finding:** WSL2 exposes **CUDA but not OpenCL** to containers. AutoDock-GPU (CUDA) runs natively; **Vina-GPU (OpenCL) cannot run on the GPU under WSL2** — verified across multiple approaches (no OpenCL ICD in the WSL driver, driver install blocked by the read-only `libcuda` bridge, `clinfo` reports zero platforms). Vina-GPU was nonetheless **compiled from source** by debugging its Makefile (correcting hardcoded paths and the from-source Boost dependency).

---

## Repository contents

```
pipeline/        dock-screen.sh, dock-library.sh, dockall.sh, analyze.py
docker/          Dockerfiles (AutoDock-GPU, tools, RDKit)
receptor/        prepared c-Abl receptor (PDBQT) + grid maps
results/         validation scores, full ranked screen, RDKit analysis
README.md
```

## How to run

```bash
# 1. Build the GPU docking engine
docker build -t adgpu -f docker/Dockerfile.gpu .

# 2. Generate grid maps for the target (one-time)
docker run --rm -v $PWD:/data -w /data adtools autogrid4 -p receptor.gpf -l receptor.glg

# 3. Validate on a known drug
docker run --rm --gpus all -v $PWD:/data -w /data adgpu \
  autodock_gpu_128wi --lfile imatinib.pdbqt --ffile receptor.maps.fld --nrun 20

# 4. Screen the library, then analyze
docker run --rm --gpus all -v $PWD:/data -w /data adgpu bash /data/dockall.sh
docker run --rm -v $PWD:/data rdkit python3 /data/analyze.py
```

---

## Honest scope & limitations

This is a **methods and learning project**, not a drug-discovery claim. Docking is a fast, approximate first-pass filter with well-known false positives; it ignores protein flexibility, solvation, and many physical effects. No hit here is a validated binder — they are computational hypotheses that would require experimental testing. The value demonstrated is building, validating, and *critically interpreting* a real virtual-screening pipeline end to end.

## References

- Trott & Olson, *AutoDock Vina*, J. Comput. Chem. 2010.
- Santos-Martins et al., *AutoDock-GPU*, J. Chem. Theory Comput. 2021.
- FDA-approved SMILES dataset (openly licensed).
