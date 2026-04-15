#!/bin/csh -f
# Clip hydrometeors to non-negative (qv to 0.) for a single MPAS NetCDF file.
# The corresponding python script seems to change something in .to_netcdf(),
# leading to failures in reading the updated file in DART. 
# So I'm switching back to this shell script, but will run it through a batch job 
# for each member.
#
# Usage:
#   ./clip_hydro_per_member.csh /path/to/drun 'init.nc'
#
# Example:
#   ./clip_hydro_per_member.csh $RUN_DIR/member1 'init.nc'

if ( $#argv < 2 ) then
 #echo "Usage: $0 \$RUN_DIR 'member1' 'init.nc'"
  echo "Usage: $0 \$RUN_DIR 'member1' 'init.nc'"
  exit 1
endif

set drun = $1
set f_in = $2

set FILES = (`/bin/sh -c "cd $drun && ls $f_in"`)
if ( $#FILES == 0 ) then
  echo "No files matched pattern '$f_in' under $drun"
  exit 0
endif

# You can tweak these:
#set EPS_QV = 1.0e-10   # floor for water vapor mixing ratio (qv) - unused.
set HYDROS = ( qv qc qr qi qs qg qh q2 )  # List of variables to check

# sanity
which ncap2 >/dev/null || (echo "ncap2 not found; install NCO"; exit 2)
which ncks  >/dev/null || (echo "ncks not found; install NCO";  exit 2)

set f = "$drun/$f_in"
set expr = ""
echo "Processing: $f"

foreach v ( $HYDROS )
    # Check if variable exists. 
    # -C: Don't print global attributes.
    # -m: Print metadata.
    # -v $v: Only check this variable.
    # > /dev/null 2>&1: Silence all output (stdout and stderr) from the command.
    
    # We run the check in a sub-shell to ensure proper quoting of $f.
    /bin/sh -c "ncks -C -m -v $v '$f' > /dev/null 2>&1"
    
    # The C-shell $status variable holds the exit code of the last command.
    if ( $status == 0 ) then
         set expr = "$expr where($v<0.0) $v=0.0;"
    endif
end

if ( "$expr" != "" ) then
    # Write to temp and replace atomically
    set ftmp = "${f}.tmp_clip"
    
    # Run ncap2 with the built expression.
    # -O: Overwrite existing output file.
    # -h: Avoid copying variable metadata when writing (faster).
    ncap2 -O -h -s "$expr" "$f" "$ftmp"
    
    # Check return code
    if ( $status != 0 ) then
        echo "ncap2 FAILED on $f"
        /bin/rm -f "$ftmp"
        exit 3
    endif
    
    # Replace the original file with the clipped one
    /bin/mv -f "$ftmp" "$f"
    ls -l "$f"
    echo "  -> clipped and updated in place"
else
    echo "  (no target variables found; skipped)"
endif
