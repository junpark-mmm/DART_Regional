#!/bin/tcsh
#PBS -N swei_hydrosat_convpmo
#PBS -A nmmm0072
#PBS -q develop
#PBS -l job_priority=<%QOS%>
#PBS -l select=1:ncpus=4:mpiprocs=4:mem=96gb
#PBS -l walltime=00:30:00
#PBS -j oe
#PBS -o ./convention_pmo.log


source /glade/u/home/swei/Git/utils/mpas/modulefiles/setup_derecho_intel.sh

set DATE_BEG = 2024-05-01_00:00:00      # start date to run this script
set DATE_END = 2024-05-01_05:00:00      # end date to run this script
set INTV_DAY = 0                        # cycling frequency - assimilation_period_days    in input.nml
set INTV_SEC = 3600                    # cycling frequency - assimilation_period_seconds in input.nml

set NR_DIR = /glade/campaign/mmm/parc/olewis/QU3km_files
set SEQIN_DIR = /glade/campaign/mmm/parc/olewis/obs/obs_seq_in_within_domain
set SEQIN_TEMPLATE = obs_seq.in.conv.%odate%_after

set ROOT_DIR     = /glade/derecho/scratch/swei/hydrosat_tmp
set PMO_DIR      = ${ROOT_DIR}/MPAS-DART/pmo
set OUT_DIR      = $PMO_DIR/out
set LOG_DIR      = $PMO_DIR/logs
set RUN_DIR      = $PMO_DIR/rundir

set DART_DIR     = /glade/work/swei/projects/hydrosat/repos/DART_Regional/models/mpas_atm/work

set mpasinit = ${NR_DIR}/conus.init.nc

#====
set REMOVE = '/bin/rm -rf'
set   COPY = 'cp -pf'
set   MOVE = 'mv -f'
set   LINK = 'ln -sf'
set    SED = '/usr/bin/sed'
set    CAT = '/usr/bin/cat'
set MPIEXEC = `which mpiexec`

set RUNONPBS = 0
if( ! -z $PBS_JOBID ) then
  set RUNONPBS = 1
  set n_node = `echo $PBS_SELECT | sed 's/:.*//'`
  set ppn = `echo $PBS_SELECT | sed -n 's/.*ncpus=\([0-9]*\).*/\1/p'`
  @ ntasks = $n_node * $ppn
endif

foreach dir ( $PMO_DIR $OUT_DIR $LOG_DIR )
   if ( ! -e $dir ) mkdir -p $dir
end
if( ! -e $RUN_DIR ) then
   mkdir -p $RUN_DIR
else
   $REMOVE $RUN_DIR/*
endif

cd $RUN_DIR
echo Running perfect_model_obs at $RUN_DIR
echo

if ( ! -x input.nml.pmo ) then
   echo ${COPY} ${DART_DIR}/input.nml.pmo .
        ${COPY} ${DART_DIR}/input.nml.pmo .
        ${COPY} ${DART_DIR}/input.nml.pmo input.nml
   if ( ! $status == 0 ) then
      echo ABORT\: We cannot find required executable dependency $fn.
      exit
   endif
endif

foreach fn ( advance_time perfect_model_obs )
   if ( ! -x $fn ) then
      echo ${COPY} ${DART_DIR}/${fn} .
           ${COPY} ${DART_DIR}/${fn} .
      if ( ! $status == 0 ) then
         echo ABORT\: We cannot find required executable dependency $fn.
         exit
      endif
   endif
end

$CAT ./input.nml.pmo \
  | $SED "s#%pmo_logfile%#'dart_log.out'#g" \
  | $SED "s#%pmo_nmlfile%#'dart_log.nml'#g" \
  > ./input.nml
#------------------------------------------
# Time info
#------------------------------------------
set greg_beg = `echo $DATE_BEG 0 -g | ./advance_time`
set greg_end = `echo $DATE_END 0 -g | ./advance_time`
set intv_seconds = $INTV_SEC
set intv_dayinsec = `expr $INTV_DAY \* 3600 \* 24`
  @ intv_seconds += $intv_dayinsec
set intv_hours = `expr $intv_seconds \/ 3600`
set halfintv_seconds = `expr $intv_seconds \/ 2`
set diff_day = `expr $greg_end[1] \- $greg_beg[1]`
set diff_sec = `expr $greg_end[2] \- $greg_beg[2]`
set diff_tot = `expr $diff_day \* 86400 \+ $diff_sec`
set ncyc = `expr $diff_tot \/ $INTV_SEC \+ 1`
echo "Total of ${ncyc} cycles from $DATE_BEG to $DATE_END will be run every $intv_hours hr."
if($ncyc < 0) then
   echo Cannot figure out how many cycles to run. Check the time setup.
   exit
endif

set time_anl = `echo $DATE_BEG 0 | ./advance_time`              #YYYYMMDDHH
set time_end = `echo $DATE_END 0 | ./advance_time`              #YYYYMMDDHH

set icyc = 1
while ( $icyc <= $ncyc )

  set time_pre = `echo $time_anl -${intv_seconds}s | ./advance_time`    #YYYYMMDDHH
  set time_nxt = `echo $time_anl +${intv_seconds}s | ./advance_time`    #YYYYMMDDHH
  set greg_winbeg = `echo $time_anl -${halfintv_seconds}s -g | ./advance_time`
  set greg_winend = `echo $time_anl +${halfintv_seconds}s -g | ./advance_time`
  set greg_first_obs_days = $greg_winbeg[1]
  set greg_first_obs_secs = `expr $greg_winbeg[2] \+ 1`
  set greg_last_obs_days = $greg_winend[1]
  set greg_last_obs_secs = $greg_winend[2]
  
  set anl_yy = `echo $time_anl | cut -c1-4`
  set anl_mm = `echo $time_anl | cut -c5-6`
  set anl_dd = `echo $time_anl | cut -c7-8`
  set anl_hh = `echo $time_anl | cut -c9-10`
  @ hh_block = ( $anl_hh / 3 ) * 3 
  set hh_block_str = `printf "%02d" $hh_block`

  set mpas_time_anl_file = ${NR_DIR}/mpasout.${anl_yy}-${anl_mm}-${anl_dd}_${anl_hh}.00.00.nc
  set tmpfile = `echo $SEQIN_TEMPLATE | sed "s/%odate%/${anl_yy}${anl_mm}${anl_dd}${hh_block_str}/"`
  set obsseqin_file = $SEQIN_DIR/$tmpfile

  echo Run PMO for cycle $icyc at ${time_anl}: \
       from ${greg_first_obs_days}_${greg_first_obs_secs}\
         to ${greg_last_obs_days}_${greg_last_obs_secs}
  
  if( -s $mpasinit ) then
     echo $LINK $mpasinit ./init.nc
     $LINK $mpasinit ./init.nc
  else
     echo $mpasinit does not exist
     exit
  endif

  if( -s $mpas_time_anl_file ) then
     echo $LINK $mpas_time_anl_file
     $LINK $mpas_time_anl_file ./mpasout.nc
  else
     echo $mpas_time_anl_file does not exist
     exit
  endif

  if( -s $obsseqin_file ) then
     echo $LINK $obsseqin_file
     $LINK $obsseqin_file ./obs_seq.in
  else
     echo $obsseqin_file does not exist
     exit
  endif

  set obsseqout_file = $OUT_DIR/obs_seq.out.$time_anl
  set logfile = $LOG_DIR/dart_pmo.out.$time_anl
  set nmlfile = $LOG_DIR/dart_pmo.nml.$time_anl

$CAT ./input.nml.pmo \
  #| $SED "s#%pmo_state_file%#'$mpas_time_anl_file'#g" \
  | $SED "s#%pmo_obs_seq.out%#'$obsseqout_file'#g" \
  | $SED "s#%pmo_first_day%#$greg_first_obs_days#g" \
  | $SED "s#%pmo_first_sec%#$greg_first_obs_secs#g" \
  | $SED "s#%pmo_last_day%#$greg_last_obs_days#g" \
  | $SED "s#%pmo_last_sec%#$greg_last_obs_secs#g" \
  | $SED "s#%pmo_logfile%#'$logfile'#g" \
  | $SED "s#%pmo_nmlfile%#'$nmlfile'#g" \
  > ./input.nml

  if ($RUNONPBS) then
     $MPIEXEC -n $ntasks -ppn $ppn ./perfect_model_obs 
  else
     ./perfect_model_obs
  endif

  set time_anl = $time_nxt
  @ icyc++
end
