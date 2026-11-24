"""Standalone baseline and covariate-adjusted RSA interaction analysis.

Requires Python with numpy, pandas and openpyxl, plus Rscript on PATH.
Run with --rsa-root /path/to/RSA --output-dir /path/to/new_output.
Existing input files and output directories are never overwritten.
"""

from __future__ import annotations

import argparse
import json
import shutil
import struct
import subprocess
import warnings
import zlib
from pathlib import Path

import numpy as np
import pandas as pd

ROIS = ["IFG_L", "IFG_R", "IFGorb_L", "IFGorb_R", "MFG_L",
        "MFG_R", "AntTemp_L", "AntTemp_R", "PostTemp_L", "PostTemp_R"]
SUBJECTS = [f"sub{i:02d}" for i in range(1, 13)]


def read_tag(buf: bytes, pos: int):
    a, b = struct.unpack_from("<II", buf, pos)
    if a >> 16:
        size = a >> 16
        return a & 0xFFFF, buf[pos + 4:pos + 4 + size], pos + 8
    end = pos + 8 + b
    # MATLAB compressed elements can be stored without eight-byte padding.
    next_pos = end if a == 15 else (end + 7) & ~7
    return a, buf[pos + 8:end], next_pos


def parse_matrix(payload: bytes, wanted: str):
    _, _, pos = read_tag(payload, 0)
    _, dims_raw, pos = read_tag(payload, pos)
    dims = tuple(np.frombuffer(dims_raw, dtype="<i4"))
    _, name_raw, pos = read_tag(payload, pos)
    if name_raw.decode("utf-8") != wanted:
        return None
    dtype, raw, _ = read_tag(payload, pos)
    if dtype != 9:
        raise ValueError("Expected a MATLAB double matrix")
    return np.frombuffer(raw, dtype="<f8").reshape(dims, order="F").copy()


def load_neural_rdm(path: Path):
    buf = path.read_bytes()
    if len(buf) < 128 or buf[126:128] != b"IM":
        raise ValueError("Expected a little-endian MATLAB v5 MAT file")
    pos = 128
    while pos + 8 <= len(buf):
        dtype, payload, pos = read_tag(buf, pos)
        if dtype == 15:
            inner = zlib.decompress(payload)
            dtype, payload, _ = read_tag(inner, 0)
        if dtype == 14:
            matrix = parse_matrix(payload, "dissimilarity_matrix")
            if matrix is not None:
                return matrix
    raise KeyError("dissimilarity_matrix not found")


def zscore(values):
    values = np.asarray(values, dtype=float)
    sd = values.std(ddof=1)
    if not np.isfinite(values).all() or not np.isfinite(sd) or sd <= 0:
        raise ValueError("Cannot standardise a nonfinite or constant predictor")
    return (values - values.mean()) / sd


def build_designs(beh):
    columns = ["MWF_std_neg", "MDD_std", "Text", "start", "end_", "SL"]
    missing = set(columns) - set(beh.columns)
    if missing:
        raise ValueError(f"Missing behavioural columns: {sorted(missing)}")
    if len(beh) < 3 or not np.isfinite(beh[columns].to_numpy(dtype=float)).all():
        raise ValueError("Missing or nonfinite sentence-level values")
    tri = np.tril_indices(len(beh), k=-1)
    def difference(values):
        a = np.asarray(values, dtype=float)
        return np.abs(a[:, None] - a[None, :])[tri]
    lexical = zscore(difference(beh["MWF_std_neg"]))
    syntactic = zscore(difference(beh["MDD_std"]))
    base = {"LexicalDiff_z": lexical, "MDDDiff_z": syntactic,
            "DiffInteraction_centered": lexical * syntactic}
    story = beh["Text"].to_numpy()
    same = (story[:, None] == story[None, :])[tri]
    temporal = np.where(same, difference(beh["start"]), 0.0)
    duration = beh["end_"] - beh["start"]
    if (duration < 0).any():
        raise ValueError("Negative annotated durations are not supported")
    if (duration == 0).any():
        warnings.warn(
            f"Retaining {int((duration == 0).sum())} zero annotated durations "
            "to reproduce the archived covariate analysis; no imputation or deletion.",
            stacklevel=2,
        )
    expanded = {**base, "DurationDiff_z": zscore(difference(duration)),
                "SentenceLengthDiff_z": zscore(difference(beh["SL"])),
                "StoryDifferent": (~same).astype(float),
                "WithinStoryTemporalDistance_z": zscore(temporal)}
    return tri, {"baseline_centered": base,
                 "plus_duration_length_story_time": expanded}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rsa-root", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--allow-missing", action="store_true",
                        help="Permit unavailable subject-ROI cells; report actual n per ROI")
    args = parser.parse_args()
    root = args.rsa_root.resolve()
    output = args.output_dir.resolve()
    if output.exists():
        raise FileExistsError("Choose a new output directory")
    if not shutil.which("Rscript"):
        raise RuntimeError("Rscript is required for group-level inference")
    beh = pd.read_excel(root / "Behavioral_RDM" / "Behavioral_Indices.xlsx")
    tri, models = build_designs(beh)
    designs = {}
    for model, predictors in models.items():
        names = ["Intercept", *predictors]
        x = np.column_stack([np.ones(len(tri[0])), *predictors.values()])
        q, r = np.linalg.qr(x, mode="reduced")
        if np.linalg.matrix_rank(r) != len(names):
            raise ValueError(f"Rank-deficient design: {model}")
        designs[model] = names, q, r
    output.mkdir(parents=True)
    rows, errors = [], []
    for subject in SUBJECTS:
        for roi in ROIS:
            path = root / "Neural_RDM" / subject / f"Results_{roi}" / "dissimilarity_matrix.mat"
            try:
                matrix = load_neural_rdm(path)
                if matrix.shape != (len(beh), len(beh)):
                    raise ValueError(f"Unexpected RDM shape: {matrix.shape}")
                y = matrix[tri]
                if not np.isfinite(y).all():
                    raise ValueError("Nonfinite neural distances")
                for model, (names, q, r) in designs.items():
                    beta = np.linalg.solve(r, q.T @ y)
                    for term, value in zip(names, beta):
                        rows.append(dict(subject=subject, roi=roi, model=model,
                                         term=term, beta=float(value)))
                print(f"Completed {subject} {roi}", flush=True)
            except (OSError, ValueError, KeyError, struct.error, zlib.error) as exc:
                errors.append(dict(subject=subject, roi=roi, error=str(exc)))
                print(f"Unavailable {subject} {roi}: {exc}", flush=True)
    pd.DataFrame(errors, columns=["subject", "roi", "error"]).to_csv(output / "unavailable_cells.csv", index=False)
    if not rows:
        raise RuntimeError("No analysable neural RDMs; see unavailable_cells.csv")
    pd.DataFrame(rows).to_csv(output / "subject_coefficients.csv", index=False)
    if errors and not args.allow_missing:
        raise RuntimeError("Unavailable cells detected. See unavailable_cells.csv; "
                           "use --allow-missing with a NEW output directory only if intended.")
    r_code = '''args <- commandArgs(TRUE)
d <- read.csv(file.path(args[1], "subject_coefficients.csv"))
d <- subset(d, term != "Intercept")
groups <- split(d, interaction(d$model, d$roi, d$term, drop=TRUE))
s <- do.call(rbind, lapply(groups, function(g) {
  x <- g$beta; n <- length(x)
  if (n < 2) stop("Fewer than two participants in a group")
  tt <- t.test(x, mu=0, alternative="two.sided")
  data.frame(model=g$model[1], roi=g$roi[1], term=g$term[1], n=n,
    mean_beta=mean(x), sd_beta=sd(x), sem_beta=sd(x)/sqrt(n),
    ci95_low=tt$conf.int[1], ci95_high=tt$conf.int[2],
    t=unname(tt$statistic), df=n-1, p_raw=tt$p.value,
    cohens_dz=mean(x)/sd(x))
}))
s$q_fdr_10roi <- NA_real_
for (idx in split(seq_len(nrow(s)), interaction(s$model, s$term, drop=TRUE))) {
  s$q_fdr_10roi[idx] <- p.adjust(s$p_raw[idx], method="BH", n=10)
}
write.csv(s, file.path(args[1], "group_stats.csv"), row.names=FALSE)
'''
    (output / "group_inference.R").write_text(r_code, encoding="utf-8")
    subprocess.run(["Rscript", str(output / "group_inference.R"), str(output)], check=True)
    metadata = {"sentences": len(beh), "sentence_pairs": len(tri[0]),
                "expected_subjects": SUBJECTS, "rois": ROIS,
                "zero_annotated_durations": int(((beh["end_"] - beh["start"]) == 0).sum()),
                "row_order": "Behavioural table row order must match neural RDM sentence order; dimensions alone cannot establish identity",
                "unavailable_cells": errors,
                "time_distance": "Within-story absolute onset difference; cross-story raw values zero before z-scoring",
                "interaction": "Product of separately sample-z-scored lexical and MDD distance vectors; product not re-standardised",
                "inference": "Two-sided participant-level t-tests; BH across 10 ROIs separately per model and term"}
    (output / "analysis_settings.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
