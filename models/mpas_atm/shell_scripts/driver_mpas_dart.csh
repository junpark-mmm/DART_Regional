#!/bin/tcsh
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
##############################################################################################
#  driver_mpas_dart.csh
#
#  THIS IS A TOP-LEVEL DRIVER SCRIPT FOR CYCLING RUNS. 
#  BOTH THE ENSEMBLE KALMAN FILTER AND THE MPAS FORECAST ARE RUN IN MPI.
#
#  This is a sample script for cycling runs in a retrospective case study, 
#  and was tested on the NCAR HPC "Derecho" using a "qsub" command.
#
#  Note:
#  1. For the general configuration including all the parameters, edit setup.csh.
#  2. For the model configuration, our general policy is that we only edit the parameters that
#     affect the I/O stream here and leave all the rest unchanged (ex. physics options). 
#     This means that it is the user's responsibility to edit all other namelist parameters 
#     before running this script. One exception is the time info, which will be updated inside 
#     advance_model.csh for each cycle.
#  3. This script does NOT specify all the options available for the EnKF data assimilation either.
#     For your own complete filter design, you need to edit your input.nml
#     - at least &filter_nml, &obs_kind_nml, &model_nml, &location_nml and &mpas_vars_nml sections 
#     to set up your filter configuration before running this script.
#  4. For adaptive inflation, we only support the choice of prior adaptive inflation in the state
#     space here. For more options, check DART/assimilation_code/modules/assimilation/filter_mod.html.
#  5. All the logical parameters are case-sensitive. They should be either true or false.
#  6. All the output files will be locally stored. 
#     For a large ensemble run, check if you have enough disk space before running this script.
#
#  Required scripts to run this driver:
#  (All the template files are available in either shell_scripts or data under DART/models/mpas_atm/.)
#  1. setup.csh                  (for the general configuration of this experiment)
#  2. namelist.atmosphere        (for mpas)   - a namelist template for mpas.
#  3. input.nml                  (for filter) - a namelist template for filter. 
#  4. filter.template.pbs        (for an mpi filter run; with async >= 2)
#  5. advance_model.template     (for an mpi mpas run; using separate nodes for each ensemble member)
#  6. advance_model.csh          (for mpas/filter) - a driver script to run mpas forecast at each cycle
#
#  Input files to run this script:
#  A. input_state_file_list  - a list of input ensemble netcdf files for DART/filter
#  B. output_state_file_list - a list of output ensemble netcdf files from DART/filter
#  C. RUN_DIR/member#/${mpas_filename}    - the input file listed in input_state_file_list for each member
#  D. OBS_DIR/${obs_seq_in}.${YYYYMMDDHH} - obs sequence files for each analysis cycle (YYYYMMDDHH) 
#     for the entire period.
#  For the file/directory structure, read README and readme.rst in DART/models/mpas_atm/ and
#  then check several README files in DART/models/mpas_atm/shell_scripts/.
# 
#  Written by Soyoung Ha (MMM/NCAR)
#  Updated and tested on yellowstone (Feb-20-2013)
#  Updated for MPAS V5 and DART/Manhattan; tested on cheyenne (Jun-27-2017)
#  Updated for a better streamline and consistency: Ryan Torn (Jul-6-2017)
#  Updated for MPASV7: Soyoung Ha (Mar-4-2020)
#  Updated for a limited-area version of MPASV8+: Soyoung Ha (Oct-25-2025)
#
#  For any questions or comments, contact: syha@ucar.edu (+1-303-497-2601)
##############################################################################################
set echo
#module list > module.list.txt	# Check module environment in Derecho

set fn_param = `pwd`/setup.csh

if (! -e $fn_param ) then
   echo $fn_param does not exist. Cannot proceed.
   exit
endif
source $fn_param

# Load modules
unset echo
source $MODFILE
set echo

echo Experiment name: $EXPERIMENT_NAME at `hostname`

if( ! -e $RUN_DIR ) mkdir -p $RUN_DIR
cd $RUN_DIR

echo Running $0 in $RUN_DIR
echo
if ( ! -d logs ) mkdir logs

#------------------------------------------
# Prepare all the necessary files.
#------------------------------------------
if ( ! -d MPAS_RUN ) then
   if ( ! -d $MPAS_DIR ) then
      echo $MPAS_DIR does not exist. Stop.
      exit
   endif
   ${LINK} $MPAS_DIR MPAS_RUN				|| exit
endif

@ ndecomp = $MODEL_NODES * $N_PROCS_MPAS

set f_graph = ${F_GRAPH}.${ndecomp}
set fgraph = `basename $f_graph`
if ( ! -e ${fgraph} ) then
       ${LINK} ${GRID_DIR}/${f_graph} ${fgraph}		|| exit
       if(! -e ${fgraph}) then
          echo "Cannot find ${fgraph} for n_mpas * n_proc (= $MODEL_NODES * $N_PROCS_MPAS)"
          exit
       endif
endif
set FILELIST = ( $fgraph )

set flist = ( filter advance_time update_mpas_states )
foreach fn ( $flist )
	#if ( ! -x $fn ) then
      echo ${LINK} ${EXE_DIR}/${fn} .
           ${LINK} ${EXE_DIR}/${fn} .
      if ( ! $status == 0 ) then
         echo ABORT\: We cannot find required executable dependency $fn.
         exit
	 #endif
   endif
end 
set FILELIST = ( $FILELIST $flist )

set flist = ( filter.template.pbs advance_model.template ) #advance_model.csh )
foreach fn ( $flist ) 
   if ( ! -r $fn || -z $fn ) then
         echo ${LINK} ${CSH_DIR}/${fn} .
              ${LINK} ${CSH_DIR}/${fn} .
         if ( ! $status == 0 ) then
            echo ABORT\: We cannot find required script $fn.
            exit
         endif
   endif
end

# For the case of prior backup (if save_prior = true in advance_model.csh),
# we define the variable list in VARLIST in setup.csh.
#------------------------------------------
${COPY} ${CSH_DIR}/advance_model.csh.temp adv.csh   			|| exit
sed -e "s/VARLIST/${VARLIST}/g" adv.csh >! advance_model.csh            || exit
chmod +x ./advance_model.csh

set FILELIST = ( $FILELIST $flist advance_model.csh )

# === Added for Regional cycling ===
if ( ${USE_REGIONAL} == true ) then
      foreach fn ( update_bc )
         if ( ! -x $fn ) then
            echo ${LINK} ${EXE_DIR}/${fn} .
                 ${LINK} ${EXE_DIR}/${fn} .
            if ( ! $status == 0 ) then
               echo ABORT\: We cannot find required executable dependency $fn.
               exit
            endif
         endif
      end
      set FILELIST = ( $FILELIST $fn )

      foreach fn ( driver_lbc_ens.csh driver_init_ens.csh )
         if ( ! -r $fn ) then
            echo ${LINK} ${CSH_DIR}/${fn} .
                 ${LINK} ${CSH_DIR}/${fn} .
            if ( ! $status == 0 ) then
               echo ABORT\: We cannot find required script $fn.
               exit
            endif
         endif
      end
      set FILELIST = ( $FILELIST $fn )
endif # FIXME - why was WPS/ungrib needed only for regional cycling? Just move this here for now.
# === End for Regional cycling ===

# === From MPAS V8+, we support cycling with either restart or da_state (e.g., non-restart) files.
foreach fn ( ${STREAM_ATM} )
      if ( ! -r ${fn} || -z $fn ) then
         if ( $USE_RESTART == true ) then
             ${COPY} ${DATA_DIR}/${fn} .
         else
             ${COPY} ${DATA_DIR}/${STREAM_ATM_IN} ${fn}
         endif
      endif
      if ( ! $status == 0 ) then
         echo ABORT\: We cannot find required script $fn.
         exit
      endif
end
set FILELIST = ( $FILELIST $fn )
echo

# === Added for QCEFF ===
# We assume ${NML_DART} (e.g., input.nml) already defined qceff_table. If not, edit it first.
set fn = ${DATA_DIR}/${FILTER_NML}
set ftbl = `grep qceff_table_filename ${fn} | head -1 | awk '{print $3}' | sed -e "s/'//g"`
if ( $ftbl != "" ) then
      echo "We need $ftbl for Non-Guassian analyses."
      ${COPY} ${DATA_DIR}/${ftbl} .	|| exit
endif
set FILELIST = ( $FILELIST ${ftbl} )
echo
# === End for QCEFF ===

# === Coefficient files needed. Add more in setup.csh, if needed.
set flist = ( ${SAMPLING_ERR_TBL} )
if ( ${USE_RTTOV} == true ) set flist = ( $flist ${RTTOV_FILES} )
foreach f ( $flist )
   set fn = `basename $f`
   if ( ! -r ${fn} || -z $fn ) then
            ${LINK} ${f} .			|| exit
   endif
end
set FILELIST = ( $FILELIST $flist )

# === Configuration files for MPAS
set  flist = ( ${STREAM_INIT} ${NML_INIT} ${MPAS_LEVEL_TXT} )
foreach fn ( $flist )
   set f = `basename $fn`
   if ( ! -r ${f} || -z $f ) then
            ${COPY} ${DATA_DIR}/${fn} .
   endif
   if ( ! $status == 0 ) then
            echo ABORT\: We cannot find required script $fn.
            exit
   endif
end
set FILELIST = ( $FILELIST $flist )

#--------------------------------------------------------------------------
# Edit namelist.atmosphere
#--------------------------------------------------------------------------
cat >! nml.sed << EOF
   /config_dt /c\
    config_dt = ${DT_MPAS}
   /config_len_disp /c\
    config_len_disp = ${LEN_DISP}
   /config_block_decomp_file_prefix /c\
    config_block_decomp_file_prefix = '${F_GRAPH}.'
   /config_sst_update /c\
    config_sst_update = ${SST_UPDATE}
EOF

if ( ${USE_REGIONAL} == true ) then
cat >! nml2.sed << EOF
   /config_apply_lbcs /c\
    config_apply_lbcs = true
EOF
cat nml2.sed >> nml.sed
endif
sed -f nml.sed ${DATA_DIR}/${NML_MPAS} > namelist.atmosphere	|| exit
ls -l namelist.atmosphere						|| exit
set FILELIST = ( $FILELIST namelist.atmosphere )

if ( $SST_UPDATE == true ) then
  set fsst = `sed -n '/<stream name=\"surface\"/,/\/>/{/Scree/{p;n};/##/{q};p}' ${STREAM_ATM} | \
              grep filename_template | awk -F= '{print $2}' | awk -F$ '{print $1}' | sed -e 's/"//g'`
  ${LINK} ${SST_DIR}/${SST_FNAME} $fsst         || exit
else
  echo NO SST_UPDATE...
endif

#--------------------------------------------------------------------------
# Edit input.nml
#--------------------------------------------------------------------------
  cat >! dart.sed << EOF
  /ens_size /c\
   ens_size                 = ${ENS_SIZE}
  /num_output_obs_members /c\
   num_output_obs_members   = ${num_output_obs_members}
  /num_output_state_members/c\
   num_output_state_members = ${num_output_state_members}
  /assimilation_period_days /c\
   assimilation_period_days     = ${INTV_DAY}
  /assimilation_period_seconds /c\
   assimilation_period_seconds  = ${INTV_SEC}
  /cutoff /c\
   cutoff                       = ${CUTOFF}
  /vert_localization_coord  /c\
   vert_localization_coord      = ${VLOC_COORD}
  /vert_normalization_height /c\
   vert_normalization_height   = ${VLOC}
  /distribute_mean /c\
   distribute_mean              = .${DISTRIB_MEAN}.
  /convert_all_obs_verticals_first /c\
   convert_all_obs_verticals_first   = .${CONVERT_OBS}.
  /convert_all_state_verticals_first /c\
   convert_all_state_verticals_first = .${CONVERT_STAT}.
  /write_binary_obs_sequence /c\
   write_binary_obs_sequence = .${binary_obs_seq}.
  /tasks_per_node /c\
   tasks_per_node = ${N_PROCS_ANAL}
  /mpas_lbc_variables = /c\
   mpas_lbc_variables = ${LBCLIST}
EOF

sed -f dart.sed ${DATA_DIR}/${FILTER_NML} > ${NML_DART}
ls -l ${NML_DART}					|| exit
set FILELIST = ( $FILELIST ${NML_DART} )
#--------------------------------------------------------------------------
#  Take file names from input.nml, check to make sure there is consistency in variables.
#--------------------------------------------------------------------------
set  input_list = `grep input_state_file_list  ${NML_DART} | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`
set output_list = `grep output_state_file_list ${NML_DART} | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`
set  obs_seq_in = `grep obs_sequence_in_name   ${NML_DART} | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`
set obs_seq_out = `grep obs_sequence_out_name  ${NML_DART} | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`

# init.nc: an MPAS template for mesh info. This should be the same as $fini from $STREAM_ATM below.
set fmesh = `grep init_template_filename ${NML_DART} | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`

if ( ! -e $fmesh ) ${LINK} ${F_TEMPLATE} $fmesh    || exit
set FILELIST = ( $FILELIST ${fmesh} )
# echo $FILELIST
#--------------------------------------------------------
# Take MPAS file names from streams.atmosphere.
#--------------------------------------------------------
set finv = `sed -n '/<immutable_stream name=\"invariant\"/,/\/>/{/Scree/{p;n};/##/{q};p}' ${STREAM_ATM} | \
            grep filename_template | awk -F= '{print $2}' | sed -e 's/"//g'`
set frst = `sed -n '/<immutable_stream name=\"restart\"/,/\/>/{/Scree/{p;n};/##/{q};p}' ${STREAM_ATM} | \
            grep filename_template | awk -F= '{print $2}' | awk -F$ '{print $1}' | sed -e 's/"//g'`

if ( ${USE_RESTART} == false ) then
 set frst = `sed -n '/<immutable_stream name=\"input\"/,/\/>/{/Scree/{p;n};/##/{q};p}' ${STREAM_ATM} | \
             grep filename_template | awk -F= '{print $2}' | awk -F$ '{print $1}' | sed -e 's/"//g'`
 
 set fout = `sed -n '/<immutable_stream name=\"da_state\"/,/\/>/{/Scree/{p;n};/##/{q};p}' ${STREAM_ATM} | \
             grep filename_template | awk -F= '{print $2}' | awk -F$ '{print $1}' | sed -e 's/"//g'`
endif

set fbdy = `sed -n '/<immutable_stream name=\"lbc_in\"/,/\/>/{/Scree/{p;n};/##/{q};p}' ${STREAM_ATM} | \
    grep filename_template | awk -F= '{print $2}' | awk -F$ '{print $1}' | sed -e 's/"//g'`

#------------------------------------------
# Initial ensemble for $DATE_INI
#------------------------------------------
if( $DATE_BEG == $DATE_INI ) then
    set nens =  0
    if( -e ${input_list} ) then
       set fens = `cat ${input_list}`
       set nens = `ls -1L $fens | wc -l`
    endif
    if( $nens != ${ENS_SIZE} ) then
       ${CSH_DIR}/driver_init_ens.csh ${fn_param}
    endif
    if ( ${USE_REGIONAL} == true ) then
       set  blist = `grep update_boundary_file_list input.nml | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`
       set  nlist = `cat $blist | wc -l`
       if( ! -e $blist || $nlist != $ENS_SIZE) then
          echo Running driver_lbc_ens.csh to copy ensemble LBC files...
          ${CSH_DIR}/driver_lbc_ens.csh ${fn_param}
       endif
       set  nlist = `cat $blist | wc -l`
       if( $nlist != $ENS_SIZE) then
           echo Not enough LBC files to start with. Stop.
           exit
       endif
    endif
endif

#--------------------------------------------------------------------------
# Time info
#--------------------------------------------------------------------------
set time_ini = `echo $DATE_INI 0 | ${EXE_DIR}/advance_time`  # YYYYMMDDHH
set time_anl = `echo $DATE_BEG 0 | ${EXE_DIR}/advance_time`  
set time_end = `echo $DATE_END 0 | ${EXE_DIR}/advance_time` 
set intv_min = `expr ${INTV_SEC} \/ 60`
set intv_hr  = `expr ${INTV_SEC} \/ 3600`

set greg_beg = `echo $DATE_BEG 0 -g | ./advance_time`
set greg_end = `echo $DATE_END 0 -g | ./advance_time`
set diff_day = `expr $greg_end[1] \- $greg_beg[1]`
set diff_sec = `expr $greg_end[2] \- $greg_beg[2]`
set diff_tot = `expr $diff_day \* 86400 \+ $diff_sec`
set n_cycles = `expr $diff_tot \/ ${INTV_SEC} \+ 1`
if($n_cycles < 0) then
   echo Cannot figure out how many cycles to run. Check the time setup.
   exit
endif

set icyc = 1
if( $DATE_BEG != $DATE_INI ) then
   set greg_ini = `echo $DATE_INI 0 -g | ./advance_time`
   set init_day = `expr $greg_beg[1] \- $greg_ini[1]`
   set init_sec = `expr $greg_beg[2] \- $greg_ini[2]`
   set init_dif = `expr $init_day \* 86400 \+ $init_sec`
   set icyc = `expr $init_dif \/ $INTV_SEC \+ 1`
endif
#set ncyc = `expr $icyc \+ $n_cycles \- 1`
echo

echo "Total of ${n_cycles} cycles from ${time_anl} to ${time_end} every ${intv_min} min."
#--------------------------------------------------------
# Cycling gets started
#--------------------------------------------------------
#set tcnt = `echo $time_anl | wc -c`
#if ($tcnt < 12 ) set time_anl = ${time_anl}00   #=> YYYYMMDDHH00
#set tcnt = `echo $time_end | wc -c`
#if ($tcnt < 12 ) set time_end = ${time_end}00   #=> YYYYMMDDHH00

while ( $time_anl <= $time_end )

  set time_pre = `echo $time_anl -${INTV_SEC}s | ./advance_time`	# YYYYMMDDHH
  set time_nxt = `echo $time_anl +${INTV_SEC}s | ./advance_time`	# YYYYMMDDHH

  #set tcnt = `echo $time_pre | wc -c`
  #if ($tcnt < 12 ) set time_pre = ${time_pre}00   #=> YYYYMMDDHH00
  #set tcnt = `echo $time_nxt | wc -c`
  #if ($tcnt < 12 ) set time_nxt = ${time_nxt}00   #=> YYYYMMDDHH00

  set anal_utc = `echo $time_anl 0 -w | ./advance_time`
  set greg_obs = `echo $time_anl 0 -g | ./advance_time`
  set greg_obs_days = $greg_obs[1]
  set greg_obs_secs = $greg_obs[2]

  set sav_dir = ${RUN_DIR}/${time_anl}
  if( ! -d ${sav_dir} ) mkdir -p ${sav_dir}

  echo
  echo "icyc = ${icyc} at ${time_anl}: ${greg_obs_days}_${greg_obs_secs} in $sav_dir"
  echo

  #------------------------------------------------------
  # 1. Namelist setup
  #------------------------------------------------------
  if($icyc == 1) then
     set cycling    = false
     set do_restart = false
  else
     set cycling    = true
     set do_restart = ${USE_RESTART}
  endif
  if ( ${USE_RESTART} == true ) then
     set jedi_io    = false
  else
     set jedi_io    = true 
  endif

  if ( -e init.sed ) ${REMOVE} init.sed script*.sed

  cat >! init.sed << EOF3
   /config_do_DAcycling /c\
    config_do_DAcycling = ${cycling}
   /config_do_restart /c\
    config_do_restart = ${do_restart}
   /config_jedi_da    /c\
    config_jedi_da = ${jedi_io}
EOF3
  mv namelist.atmosphere namelist.temp
  sed -f init.sed namelist.temp >! namelist.atmosphere
  ${REMOVE} init.sed namelist.temp

  if ( $ADAPTIVE_INF == true ) then       # For a spatially-varying prior inflation.

    if ($icyc == 1) then
       cat >! script.sed << EOF
       /inf_initial_from_restart/c\
       inf_initial_from_restart    = .false.,                .false.,
       /inf_sd_initial_from_restart/c\
       inf_sd_initial_from_restart = .false.,                .false.,
EOF
    else
       cat >! script.sed << EOF
       /inf_initial_from_restart/c\
       inf_initial_from_restart    = .true.,                .true.,
       /inf_sd_initial_from_restart/c\
       inf_sd_initial_from_restart = .true.,                .true.,
EOF
    endif

  endif

  ${MOVE} ${NML_DART} ${NML_DART}.temp
  sed -f script.sed ${NML_DART}.temp >! ${NML_DART}             || exit 2
  ${REMOVE} script.sed ${NML_DART}.temp

  #------------------------------------------------------
  # 2. Update the input file list to get filter started
  # (assuming start_from_restart = .true. in input.nml)
  #------------------------------------------------------
  set f_rst =   ${frst}`echo ${anal_utc} | sed -e 's/:/\./g'`.nc
  set f_anl = analysis.`echo ${anal_utc} | sed -e 's/:/\./g'`.nc
  set f_out =   ${fout}`echo ${anal_utc} | sed -e 's/:/\./g'`.nc
  set f_prior = prior.`echo ${anal_utc} | sed -e 's/:/\./g'`.nc 
  set f_diag = diag.`echo ${anal_utc} | sed -e 's/:/\./g'`.nc
  set f_pdiag = pdiag.`echo ${anal_utc} | sed -e 's/:/\./g'`.nc

  echo "Input ensemble for ${time_anl}"
  if( -e ${input_list})  ${REMOVE} ${input_list}
  if( -e ${output_list}) ${REMOVE} ${output_list}
  echo "Creating an input list in ${input_list} and output in ${output_list}"

  set finput = ${f_rst}
  set i = 1
  while ( $i <= ${ENS_SIZE} )
    # if($icyc == 1) then
       if ( $icyc == 1 && ! -d ${ENS_DIR}${i} ) ${LINK} ../${ENS_DIR}${i} . # mkdir ${ENS_DIR}${i}
       # link the fini (input in filter_in) to restart or da_state streams

    #    if ( ! -e ./${ENS_DIR}${i}/$f_prior ) ${COPY} ./${ENS_DIR}${i}/$fini ./${ENS_DIR}${i}/$f_prior &
    #    if ( ! -e ./${ENS_DIR}${i}/$f_rst ) ${COPY} ./${ENS_DIR}${i}/$fini ./${ENS_DIR}${i}/$f_rst &
    # else
       if( -e ${ENS_DIR}${i}/${f_out} ) then
         ${COPY} ${ENS_DIR}${i}/${f_out} ${ENS_DIR}${i}/${f_prior} &
         ${COPY} ${ENS_DIR}${i}/${f_out} ${ENS_DIR}${i}/${f_rst} &
       endif
       if ( -e ${ENS_DIR}${i}/${f_diag} ) then
         ${MOVE} ${ENS_DIR}${i}/${f_diag} ${ENS_DIR}${i}/${f_pdiag} &
       endif
    # endif
    @ r = $i / 10
    if ( $r == 0 ) wait
    @ i++
  end
  wait

  set i = 1
  while ( $i <= ${ENS_SIZE} )
    if (! -e ${ENS_DIR}${i}/${finput}) then
	echo "Cannot find ${ENS_DIR}${i}/${finput}."
        exit
    else
        if( -e ${ENS_DIR}${i}/${f_out} ) ${REMOVE} ${ENS_DIR}${i}/${f_out}
        if( -e ${ENS_DIR}${i}/${f_diag} ) ${REMOVE} ${ENS_DIR}${i}/${f_diag}
        echo ${ENS_DIR}${i}/${finput} >> ${input_list}
    endif
    echo ${ENS_DIR}${i}/${f_anl} >> ${output_list}

    @ i++
  end
  echo ${ENS_DIR}${i}/$finput $f_anl

  set ne = `cat ${input_list} | wc -l `
  if ( $ne != $ENS_SIZE ) then
     echo "We need ${ENS_SIZE} initial ensemble members, but found ${ne} only."
     exit
  endif
  echo

  # Clip hydrometeors for QCEFF
  #------------------------------------------------------
  if ( $ftbl != "" && ! -e ./clip_done ) then
       if ( -e check_negative.log ) ${REMOVE} check_negative.log
       python $CSH_DIR/check_negative_ensemble.py $RUN_DIR ${finput} > check_negative.log
       set nneg = `tail -1 check_negative.log | awk '{print $1}' | bc`

       if ( $nneg > 0 ) then

       echo "${nneg} negative values found. Clipping hydrometers for each member."
       set jobn = clip.`echo ${time_anl} | cut -c5-`

         cat >! clip.pbs << EOF
#!/bin/tcsh
#============================================
#PBS -N $jobn
#PBS -A NMMM0063
##PBS -o logs/${jobn}.log
#PBS -j oe
#PBS -q develop
#PBS -l job_priority=premium
#PBS -l select=1:mpiprocs=1:ncpus=1
#PBS -l walltime=00:10:00
#PBS -J 1-60%5
#============================================
source $MODFILE
set memid = \${PBS_ARRAY_INDEX}

ls -l $RUN_DIR/${ENS_DIR}\${memid}/${finput}

$CSH_DIR/clip_hydro_per_member.csh $RUN_DIR/${ENS_DIR}\${memid} "${finput}"

ls -l $RUN_DIR/${ENS_DIR}\${memid}/${finput}
EOF
    set jid = `qsub clip.pbs`
    sleep 60

       # Wait until the job is finished.
       set is_there = 0
       while ( $is_there == 0 )
         sleep 30
         qstat -w $jid
         set is_there = $?
       end

       set i = 1
       while ( $i <= ${ENS_SIZE} )
         ls -l ${ENS_DIR}${i}/${finput}
         @ i++
       end
       ${MOVE} ${jobn}.o* ./logs
       touch clip_done

       endif	# if ( $nneg > 0 ) then
  endif	# if ( $ftbl != "" ) then

  if ( -e ./clip_done ) ${REMOVE} ./clip_done

  if ( $ADAPTIVE_INF == true && $icyc > 1 ) then
    if ( ! -e ${RUN_DIR}/${time_pre}/${INFL_OUT}_mean.nc ) then
      echo ${RUN_DIR}/${time_pre}/${INFL_OUT}_mean.nc does not exist. Stop.
      exit
    endif
    ${LINK} ${RUN_DIR}/${time_pre}/${INFL_OUT}_mean.nc ${INFL_IN}_mean.nc	|| exit
    ${LINK} ${RUN_DIR}/${time_pre}/${INFL_OUT}_sd.nc   ${INFL_IN}_sd.nc		|| exit
  endif

  #------------------------------------------------------
  # 3. Obs sequence for this analysis cycle - one obs time at each analysis cycle
  #------------------------------------------------------
  #set fn_obs = ${OBS_DIR}/obs_seq${time_anl} # without QC OBS
  set fn_obs = ${OBS_DIR}/obs_seq.out.${time_anl}  #_after # after mpas_dart_obs_preprocess
  if ( ! -e ${fn_obs} ) then
     echo ${fn_obs} does not exist. Stop.
     exit
  endif
  ${LINK} ${fn_obs} ${obs_seq_in}

#------------------------------------------------------
# 4. Run filter
#------------------------------------------------------
  set jobn = ${EXPERIMENT_NAME}.`echo $time_anl | cut -c5-`	# MMDDHH only

  if( ! -e filter_done && ! -e ${obs_seq_out} ) then

    if ( $RUN_IN_PBS == yes ) then
    echo Running filter: $jobn

    cat >! filter.sed << EOF
    s#JOB_NAME#${jobn}#g
    s#PROJ_NUMBER#${PROJ_NUMBER}#g
    s#NODES#${FILTER_NODES}#g
    s#NPROC#${N_PROCS_ANAL}#g
    s#NCPUS#${N_CPUS}#g
    s#JOB_TIME#${TIME_FILTER}#g
    s#QUEUE#${QUEUE_FILTER}#g
EOF

    sed -f filter.sed filter.template.pbs >! filter.pbs
    set jid = `qsub filter.pbs`
    sleep 60
    ${REMOVE} filter.sed

    # Wait until the job is finished.
    set is_there = 0
    while ( $is_there == 0 )
      sleep 30
      qstat -w $jid
      set is_there = $?
    end
    ${MOVE} ${jobn}.o* logs/.

    else

    echo `date +%s` >&! filter_started

    set flog = ${sav_dir}/${jobn}.log
    ./filter >! $flog

    endif       #if ( $RUN_IN_PBS == yes ) then

    if ( -e ${obs_seq_out})  touch filter_done

  endif # if( ! -e filter_done ) then

  # Check errors in filter.
  if ( -e filter_started && ! -e filter_done ) then
    echo "Filter was not normally finished. Exiting."
    ls -l filter_started
    date
    ${REMOVE} filter_started
    exit
  endif

  ${REMOVE} filter_started filter_done
  echo Filter is done for Cycle at ${time_anl}

  #------------------------------------------------------
  # 5. Target time for model advance
  #------------------------------------------------------
  set greg_obs = `echo $time_anl ${INTV_DAY}d${INTV_SEC}s -g | ./advance_time`
  set greg_obs_days = $greg_obs[1]
  set greg_obs_secs = $greg_obs[2]
  echo Target date: $time_nxt ${greg_obs_days}_${greg_obs_secs}
  ${COPY} input.nml ${time_anl}/input.nml.filter.${icyc}

  #------------------------------------------------------
  # 6. Run update_mpas_states for all ensemble members
  #------------------------------------------------------
  set fanal = `grep update_output_file_list input.nml | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`
  set nanal = `cat $fanal | wc -l`

  set flog = logs/update_mpas_states.${time_anl}.cycle${icyc}.log
  if ( -e $flog ) ${REMOVE} $flog

  if ( ! -e $flog || -z $flog) then
  ${EXE_DIR}/update_mpas_states > $flog
  endif

  set i_err = `grep ERROR    $flog | wc -l`
  set idone = `grep Finished $flog | wc -l`
  if($nanal != $ENS_SIZE || ${i_err} > 0 || $idone == 0 ) then
     echo Error in $flog
     echo nanal = $nanal ensemble input files with i_err = ${i_err} and idone = $idone.
     exit
  endif
  echo

  #------------------------------------------------------
  # 7. Run update_bc for all ensemble members (for regional MPAS)
  #------------------------------------------------------
  if ( ${USE_REGIONAL} == true ) then

       set anllist = `grep update_analysis_file_list input.nml | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`
         if($anllist != $fanal) then
            echo $anllist should be the same as $fanal for update_bc. Exit.
            exit
         endif
       set bdylist = `grep update_boundary_file_list input.nml | awk '{print $3}' | cut -d ',' -f1 | sed -e "s/'//g" | sed -e 's/"//g'`
       if( -e $bdylist) ${REMOVE} $bdylist
       if( -e  bdynext) ${REMOVE}  bdynext

       echo Creating $bdylist for update_bc now.
       touch $bdylist bdynext
       set lbc0 = ${fbdy}`echo ${time_anl} 0 -w | ./advance_time | sed -e 's/:/\./g'`.nc
       set lbcN = ${fbdy}`echo ${time_nxt} 0 -w | ./advance_time | sed -e 's/:/\./g'`.nc
       set g_fc = ${f_rst}	# analysis after update_mpas_states

       set n = 1
       while ( $n <= $ENS_SIZE )

	set num = `printf "%02d" $n`

        ls -lL ${ENS_DIR}${n}/${lbc0}                                    || exit
        echo ${ENS_DIR}${n}/${lbc0} >> $bdylist
	#${COPY} ${ENS_DIR}${n}/${lbc0} ${ENS_DIR}${n}/prior.${lbc0}

        if( ! -e ${ENS_DIR}${n}/${lbcN} ) then
          ${COPY} ${LBC_DIR}/${time_anl}/${ENS_DIR}${num}/${lbcN} ${ENS_DIR}${n}/    || exit
        endif
        ls -1 ${ENS_DIR}${n}/${lbcN} >> bdynext

        @ n++
       end

  set  nbdy = `cat $bdylist | wc -l`
  set nbdyN = `cat bdynext | wc -l`
  if($nbdy != $ENS_SIZE || $nbdyN != $ENS_SIZE) then
     echo Not enough LBC files for the regional MPAS run: $nbdy and $nbdyN. Stop.
     exit
  endif

  ${EXE_DIR}/update_bc >!    logs/update_bc.${time_anl}.cycle${icyc}.log
  set i_err = `grep ERROR    logs/update_bc.${time_anl}.cycle${icyc}.log | wc -l`
  set idone = `grep Finished logs/update_bc.${time_anl}.cycle${icyc}.log | wc -l`
  if( ${i_err} > 0 || $idone == 0 ) then
     echo Error in logs/update_bc.${time_anl}.cycle${icyc}.log
     exit
  endif

  if( -z $bdylist ) then
      echo $bdylist is zero. Check update_bc. Exit.
      exit
  endif

  endif # if ( ${USE_REGIONAL} == true ) then

  #------------------------------------------------------
  # 8. Advance model for each member
  #------------------------------------------------------
  # Run forecast for ensemble members until next analysis time
  echo Advance model for ${ENS_SIZE} members now...

  if( -e list.${time_nxt}.txt ) \rm -f list.${time_nxt}.txt

   if ( $RUN_IN_PBS == "yes" ) then  #  derecho
      
      set jobname = ${EXPERIMENT_NAME}.`echo $time_anl | cut -c5-` #.e${n} # MMDDHH only

      cat >! advance.sed << EOF
      s#JOB_NAME#${jobname}#g
      s#PROJ_NUMBER#${PROJ_NUMBER}#g
      s#ENS_SIZE#${ENS_SIZE}#g
      s#QUEUE#${QUEUE_MPAS}#g
      s#NODES#${MODEL_NODES}#g
      s#NPROC#${N_PROCS_MPAS}#g
      s#NCPUS#${N_CPUS}#g
      s#JOB_TIME#${TIME_MPAS}#g
      s#MULTIPHYSICS#${MULTIPHYSICS}#g
EOF

          sed -f advance.sed advance_model.template >! advance_model.pbs
          set jid = `qsub advance_model.pbs`

   else
      set n = 1
      while ( $n <= $ENS_SIZE )

      ./advance_model.csh $n $n >! logs/advance_model.${time_anl}.cycle${icyc}.log

      @ n++
      end
   endif
#
  if ( $RUN_IN_PBS == yes ) then
    sleep 60

    # Wait until the job is finished.
    set is_there = 0
    while ( $is_there == 0 )
      sleep 30
      qstat -w $jid
      set is_there = $?
    end

    sleep 15

    # Rename the job log
    $MOVE ${jobname}.* logs
    set rename_jobid = `echo $jid | sed 's/\[.*//'`
    rename "o${rename_jobid}." "log.e" logs/${jobname}.o${rename_jobid}.*

    date
    sleep 30
  endif

  #------------------------------------------------------
  # 9. Store output files
  #------------------------------------------------------
  echo Saving output files for ${time_anl}.
  ls -lrt >! ${sav_dir}/list.txt
  set fstat = `grep stages_to_write input.nml | awk -F= '{print $2}'`
  set fs = `echo $fstat | sed -e 's/,/ /g' | sed -e "s/'//g"`

  foreach f ( $fs ${obs_seq_out} ${input_list} ${output_list} $bdylist bdynext )
    ${MOVE} ${f}* ${sav_dir}/
  end

  #------------------------------------------------------
  # 10. Get ready to run filter for next cycle.
  #------------------------------------------------------
  cd $RUN_DIR
  ls -lL list.${time_nxt}.txt           || exit
  set nout = `cat list.${time_nxt}.txt | wc -l`

  if ( $nout != ${ENS_SIZE} ) then
     echo This cycle has failed with only $nout members done. Check missing members.
     exit
  else
     echo Filter is ready to go for $nout members for the next cycle ${time_nxt}.
     set time_anl = $time_nxt
     @ icyc++
  endif

  echo
end
#
echo Cycling is done for $n_cycles cycles in ${EXPERIMENT_NAME}.
echo Script exiting normally.
#
exit 0
