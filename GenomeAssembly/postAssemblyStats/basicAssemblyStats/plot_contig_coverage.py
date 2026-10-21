#!/usr/bin/env python3
"""Per-contig HiFi coverage plots (histogram + length-vs-coverage scatter)
from blobtoolkit's windowed coverage bed and the assembly's .fai index."""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

ASSEMBLY = "/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm/woodsia_obtusa.asm.bp.p_ctg.fa"
COV_BED = "/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/blobtoolkit/results/read_mapping/pacbio/woodsia_obtusa_hifi.coverage.1k.bed.gz"
OUT_DIR = "/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/contigCoveragePlots"

fai = pd.read_csv(f"{ASSEMBLY}.fai", sep="\t", header=None,
                   names=["contig", "length", "offset", "linebases", "linewidth"],
                   usecols=["contig", "length"])

windows = pd.read_csv(COV_BED, sep="\t", header=None, compression="gzip",
                       names=["contig", "start", "end", "coverage"])
windows["win_len"] = windows["end"] - windows["start"]
windows["weighted"] = windows["coverage"] * windows["win_len"]

per_contig = windows.groupby("contig").agg(
    total_weighted=("weighted", "sum"),
    total_len=("win_len", "sum"),
).reset_index()
per_contig["mean_coverage"] = per_contig["total_weighted"] / per_contig["total_len"]

df = fai.merge(per_contig[["contig", "mean_coverage"]], on="contig", how="left")
assert df["mean_coverage"].notna().all(), "contigs missing from coverage bed"

# Plot 1: histogram of per-contig mean coverage (log10 x-axis)
fig, ax = plt.subplots(figsize=(8, 6))
bins = np.logspace(np.log10(df["mean_coverage"].min()),
                    np.log10(df["mean_coverage"].max()), 100)
ax.hist(df["mean_coverage"], bins=bins)
ax.set_xscale("log")
ax.set_xlabel("Mean HiFi coverage (log10)")
ax.set_ylabel("Number of contigs")
ax.set_title(f"Per-contig mean coverage (n={len(df)} contigs)")
fig.tight_layout()
fig.savefig(f"{OUT_DIR}/coverage_histogram.png", dpi=150)

# Plot 2: contig length vs. mean coverage
fig, ax = plt.subplots(figsize=(8, 6))
ax.scatter(df["length"], df["mean_coverage"], s=8, alpha=0.5)
ax.set_xlabel("Contig length (bp)")
ax.set_ylabel("Mean HiFi coverage")
ax.set_xscale("log")
ax.set_title(f"Contig length vs. mean coverage (n={len(df)} contigs)")
fig.tight_layout()
fig.savefig(f"{OUT_DIR}/length_vs_coverage_scatter.png", dpi=150)

df[["contig", "length", "mean_coverage"]].to_csv(
    f"{OUT_DIR}/per_contig_coverage.tsv", sep="\t", index=False)

print(f"{len(df)} contigs; wrote plots and table to {OUT_DIR}")
