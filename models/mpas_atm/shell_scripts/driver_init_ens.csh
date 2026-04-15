#!/bin/tcsh
# driver_init_ens.csh
#
# Create an initial ensemble. Run this only once at the initial cycle.
set echo
if ( $#argv >= 1 ) then
   set fn_param = ${1}
else
   set fn_param = `pwd`/setup.csh
endif
source ${fn_param}

set    time_ini = `echo $DATE_INI 0 | $EXE_DIR/advance_time`	# initial ensemble at this time

if (! -e $RUN_DIR) mkdir -p $RUN_DIR
cd $RUN_DIR

foreach f ( input.nml streams.atmosphere )
  if (! -e $f ) cp -p ../$f .
end
ls -l  input.nml streams.atmosphere
if ( ! $status == 0 ) then
     echo ABORT\: Run driver_mpas_dart.csh to have input.nml and streams.atmosphere ready for $0.
     exit
endif

echo
echo driver_init_ens.csh at ${time_ini} in $RUN_DIR
echo

# Check the file names for the MPAS model and the file lists for DART/filter.
set f_inv = `sed -n '/<immutable_stream name=\"invariant\"/,/\/>/{/Scree/{p;n};/##/{q};p}' streams.atmosphere | \
             grep filename_template | awk -F= '{print $2}' | sed -e 's/"//g'`

set frst = `sed -n '/<immutable_stream name=\"restart\"/,/\/>/{/Scree/{p;n};/##/{q};p}' ${STREAM_ATM} | \
            grep filename_template | awk -F= '{print $2}' | awk -F$ '{print $1}' | sed -e 's/"//g'`

if ( ${USE_RESTART} == true ) then
    set fini = $frst
else
    set fini = `sed -n '/<immutable_stream name=\"da_state\"/,/\/>/{/Scree/{p;n};/##/{q};p}' ${STREAM_ATM} | \
                grep filename_template | awk -F= '{print $2}' | awk -F$ '{print $1}' | sed -e 's/"//g'`
endif
set f_rst = ${frst}`echo $DATE_INI | sed -e 's/:/\./g'`.nc
set f_ini = ${fini}`echo $DATE_INI | sed -e 's/:/\./g'`.nc

# If an initial ensemble already exists, simply link to it.
echo Check $INIT_DIR/$time_ini/${ENS_DIR}*/${f_rst} for ${f_inv} first.
set nens_inv = `ls -1 $INIT_DIR/$time_ini/${ENS_DIR}*/${f_rst} | wc -l`

echo Check $INIT_DIR/$time_ini/${ENS_DIR}*/${f_ini} for initial file.
if ( ${USE_RESTART} == true ) then
    set nens_ini = $nens_inv
else
    set nens_ini = `ls -1 $INIT_DIR/$time_ini/${ENS_DIR}*/${f_ini} | wc -l`
endif

if ( $nens_inv >= $ENS_SIZE && $nens_ini >= $ENS_SIZE ) then

   echo "An initial ensemble is found."
   echo "Copy them in each member directory (to be overwritten by DA)."

   set n = 1
   while ( $n <= $ENS_SIZE )

     set f_invariant = ${ENS_DIR}${n}/$f_inv
     set f_initfile = ${ENS_DIR}${n}/$f_ini

     if ( ! -d ${ENS_DIR}${n} ) mkdir ${ENS_DIR}${n}

     set num = `printf "%02d" $n` # two-digit integer like 01, 02, 03, ...

     # Copy restart file to invariant.nc
     ls -l ${INIT_DIR}/$time_ini/${ENS_DIR}${num}/$f_rst		        || exit
     if ( ! -e $f_invariant ) ${COPY} ${INIT_DIR}/$time_ini/${ENS_DIR}${num}/$f_rst ${f_invariant} &

     # Copy init file (restart or mpasout) to the folder
     ls -l ${INIT_DIR}/$time_ini/${ENS_DIR}${num}/$f_ini		        || exit
     if ( ! -e $f_initfile ) ${COPY} ${INIT_DIR}/$time_ini/${ENS_DIR}${num}/$f_ini ${f_initfile} &
     
     @ r = $n % 10 
     if ( $r == 0 ) wait

     #echo ${finput} >> ${input_list}

     @ n++

   end

else

   echo An initial ensemble should be created from ${GRIB_DIR}/${GRIB_DATA} using WPS.
   if ( ! -d ${GRIB_DIR} ) mkdir -p ${GRIB_DIR}
   cd ${GRIB_DIR}
   echo This option is not yet supported. Exit.
   exit

endif
