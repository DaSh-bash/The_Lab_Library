#!/usr/bin/env python3

import re
import os
import sys
import csv
from pathlib import Path

# Default QC_DIR (used if no command-line argument is given) — Adjust if needed.
#
# IMPORTANT: when this script is launched via `sbatch --wrap="python3
# extract_to_table.py"`, sbatch only snapshots that shell command at submit
# time, NOT this file's contents -- the file is read fresh off disk whenever
# the job actually starts executing. Editing QC_DIR below and resubmitting a
# new --wrap job while an earlier one is still queued/pending on a
# dependency is a race: the earlier job can end up running after this edit
# and silently write to the wrong directory. Hit exactly this on
# 2026-08-20 -- lei26_noC's and fas25_noC's extract_to_table jobs (6063737,
# 6063738) both executed after QC_DIR here had already been changed to
# rolan9F_noC for a later rerun, so neither produced their own
# assembly_summary.tsv; both silently overwrote rolan9F_noC's instead (with
# an incomplete snapshot, since not all of *that* run's QC was done yet
# either). Fix: pass QC_DIR explicitly as a CLI argument in the --wrap
# command instead of relying on this file's in-place-edited default --
# that argument is part of the snapshotted shell command, so it can't race.
QC_DIR = Path("/lisc/data/scratch/botany/aiden/gen_assembl/qc/post_assembly_ragtag_scaffold_rolan9F_noC")

if len(sys.argv) > 1:
    QC_DIR = Path(sys.argv[1])

os.chdir(QC_DIR)

rows = []

# Find all QUAST reports
for report in QC_DIR.rglob("report.txt"):

    assembly = report.parent.parent.name

    quast = {
        "assembly": assembly,
        "contigs": "",
        "largest_contig": "",
        "tot_length": "",
        "N50": "",
        "N90": "",
        "L50": "",
        "L90": "",
        "C": "",
        "S": "",
        "D": "",
        "F": "",
        "M": "",
        "E": ""
    }

    # -------------------------
    # Parse QUAST report
    # -------------------------
    with open(report) as f:
        for line in f:

            if line.startswith("# contigs"):
                quast["contigs"] = line.split()[-1]

            elif line.startswith("Largest contig"):
                quast["largest_contig"] = line.split()[-1]

            elif line.startswith("Total length"):
                quast["tot_length"] = line.split()[-1]

            elif re.match(r"^N50\s", line):
                quast["N50"] = line.split()[-1]

            elif re.match(r"^N90\s", line):
                quast["N90"] = line.split()[-1]

            elif re.match(r"^L50\s", line):
                quast["L50"] = line.split()[-1]

            elif re.match(r"^L90\s", line):
                quast["L90"] = line.split()[-1]

    # -------------------------
    # Find BUSCO summary (INSIDE loop!)
    # -------------------------
    busco_files = list(
        QC_DIR.rglob(
            f"{assembly}_busco/short_summary*.txt"
        )
    )

    if busco_files:

        busco_file = busco_files[0]

        with open(busco_file) as f:
            text = f.read()

        busco_line = None
        for line in text.splitlines():
            if line.strip().startswith("C:") and "n:" in line:
                busco_line = line.strip()
                break

        if busco_line:
            def grab(key):
                m = re.search(rf"{key}:(\d+\.?\d*)%?", busco_line)
                return m.group(1) if m else ""

            quast["C"] = grab("C")
            quast["S"] = grab("S")
            quast["D"] = grab("D")
            quast["F"] = grab("F")
            quast["M"] = grab("M")
            quast["E"] = grab("E")

    # IMPORTANT: append INSIDE loop
    rows.append(quast)

# -------------------------
# Write output table
# -------------------------
outfile = "assembly_summary.tsv"

with open(outfile, "w", newline="") as out:
    writer = csv.writer(out, delimiter="\t")

    writer.writerow([
        "assembly",
        "contigs",
        "largest_contig",
        "tot_length",
        "N50",
        "N90",
        "L50",
        "L90",
        "C",
        "S",
        "D",
        "F",
        "M",
        "E"
    ])

    for row in sorted(rows, key=lambda x: x["assembly"]):
        writer.writerow([
            row["assembly"],
            row["contigs"],
            row["largest_contig"],
            row["tot_length"],
            row["N50"],
            row["N90"],
            row["L50"],
            row["L90"],
            row["C"],
            row["S"],
            row["D"],
            row["F"],
            row["M"],
            row["E"]
        ])

print(f"Wrote {outfile}")