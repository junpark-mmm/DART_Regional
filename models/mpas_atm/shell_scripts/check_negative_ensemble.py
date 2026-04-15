# check_negative_ensemble.py
#
# module load conda/latest
# conda activate npl
import xarray as xr
import numpy as np
import sys, os, glob
from pathlib import Path

# Usage: python check_negative_ensemble.py data_dir init.nc

if len(sys.argv) < 2:
    print("Usage: python check_negative_ensemble.py ddir init.nc")
    sys.exit(1)

ddir = sys.argv[1]
infn = sys.argv[2]
fs = sorted(glob.glob('%s/member*/%s'%(ddir,infn)))

vars_to_clip = [ "q2", "qv", "qc", "qr", "qi", "qs", "qg", "qh" ]
ntot = 0

for fn in fs:

  path = Path(fn)
  if not path.exists():
      print(f"File not found: {path}")

  with xr.open_dataset(fn) as ds:

    for xv in vars_to_clip:
       if xv not in ds.data_vars:
          continue
       data = ds[xv].values
       nneg = np.count_nonzero(data < 0.0)
       if nneg > 0:
          vmin = float(data[data < 0.0].min())
          print(f"{fn}: {xv} has {nneg:,} negative values (min={vmin:.3e})")
          ntot = ntot + nneg

print(f"{ntot} negative values in total.")
