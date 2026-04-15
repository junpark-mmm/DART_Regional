#!/usr/bin/env bash
#PBS -N create_pmoin_fr_pbfrout
#PBS -A nmmm0063
#PBS -q develop
#PBS -l select=1:ncpus=1:mpiprocs=1:mem=32Gb
#PBS -l walltime=1:00:00
#PBS -j oe
#PBS -J 0-23
#PBS -V

# 1. Convert 6-hours prepbufr output to hourly with obs_sequence_tool
# 2. Crop it to mpas regional domain by mpas_dart_preprocess

jobid=${PBS_ARRAY_INDEX}

export HDF5_USE_FILE_LOCKING=FALSE
ulimit -s unlimited || true
ulimit -v unlimited || true

trace_message(){
    message=$1
    echo "Job[$jobid]: $message"
}

trace_message "Started at `date`"
hh=$(printf "%02d" "$jobid")

parse_obs_seq_tool_nml(){
local tmpl=$1
local output=$2
local firstgregd=$3
local firstgregs=$4
local lastgregd=$5
local lastgregs=$6
cat $tmpl \
   | sed "s#%SEQTOOLOUT%#${output}#g" \
   | sed "s#%first_greg_day%#${firstgregd}#g" \
   | sed "s#%first_greg_sec%#${firstgregs}#g" \
   | sed "s#%last_greg_day%#${lastgregd}#g" \
   | sed "s#%last_greg_sec%#${lastgregs}#g" \
   > input.nml
}

days=(202405{01..10})
tmptopdir=/glade/derecho/scratch/swei/hydrosat_tmp/conv_pmo_in
nml_tmpl=/glade/work/swei/projects/hydrosat/tests/test_obsseqtool/input.nml.tmpl
rtcoef=/glade/campaign/mmm/parc/swei/rtcoef/rtcoef_dummy_5_dummyir.dat
sccldcoef=/glade/campaign/mmm/parc/swei/rtcoef/sccldcoef_dummy_5_dummyir.dat
sensordbcsv=/glade/work/swei/projects/hydrosat/repos/DART_Regional/observations/forward_operators/rttov_sensor_db.csv
inittmpl=/glade/work/swei/projects/hydrosat/mpas.configs/3km/conus.3km.q_added.init.nc

parse_mpas_preprocess_nml(){
local tmpl=$1
local input=$2
local output=$3
cat $tmpl \
   | sed "s#%SEQTOOLOUT%#${input}#g" \
   | sed "s#%PREPOUT%#${output}#g" \
   > input.nml
}

dart_exedir='/glade/work/swei/projects/hydrosat/repos/DART_Regional/models/mpas_atm/work'
advtime=${dart_exedir}/advance_time
seqtool=${dart_exedir}/obs_sequence_tool
preprocess=${dart_exedir}/mpas_dart_obs_preprocess
# Input of obs_sequence_tool
obsprepbufrout_dir='/glade/campaign/mmm/parc/swei/obs/hourly/conv/obs_seq.prepbufr_out.conv'
obsprepbufrout_prefix='obs_seq.prepbufr_out.'
# Input of mpas_dart_obs_preprocess
obsprepin_prefix='obs_seq.prep_in.conv.'
obspmoin_prefix='obs_seq.pmo_in.conv.'

rundir=$tmptopdir/$obstype/rundir_${jobid}
[[ ! -d $rundir ]] && mkdir -p $rundir
cd $rundir
cp $nml_tmpl ./input.nml.tmpl
cp $nml_tmpl ./input.nml
cp $advtime .
cp $seqtool .
ln -sf $rtcoef
ln -sf $sccldcoef
ln -sf $sensordbcsv
ln -sf $inittmpl ./init.nc

for target_pdy in ${days[@]}
do
   target_hh=$hh
   target_date=${target_pdy}${target_hh}

   case $target_hh in
   04|05|06|07|08|09)
     first_date=${target_pdy}06
     second_date=${target_pdy}12 ;;
   10|11|12|13|14|15)
     first_date=${target_pdy}12
     second_date=${target_pdy}18 ;;
   16|17|18|19|20|21)
     first_date=${target_pdy}18
     second_date=${target_pdy}24 ;;
   22|23)
     tmp_date=`echo $target_date +1d | ./advance_time`
     first_date=${target_pdy}24
     second_date=${tmp_date:0:8}06 ;;
   00|01|02|03)
     tmp_date=`echo $target_date -1d | ./advance_time`
     first_date=${tmp_date:0:8}24
     second_date=${target_pdy}06 ;;
   esac

   [[ -s ./temp_obs_list ]] && rm ./temp_obs_list
   first_pbout=$obsprepbufrout_dir/${obsprepbufrout_prefix}${first_date}
   second_pbout=$obsprepbufrout_dir/${obsprepbufrout_prefix}${second_date}
   echo $first_pbout > ./temp_obs_list
   if [ -s $second_pbout ]; then
      echo $second_pbout >> ./temp_obs_list
   fi

   first_obs_greg=`echo $target_date -29m59s -g | ./advance_time`
   target_greg=`echo $target_date 0 -g | ./advance_time`
   last_obs_greg=`echo $target_date +30m -g | ./advance_time`
   prepinfile=./${obsprepin_prefix}${target_date}
   parse_obs_seq_tool_nml ./input.nml.tmpl $prepinfile $first_obs_greg $last_obs_greg
   $seqtool
   
   pmoinfile=./${obspmoin_prefix}${target_date}
   parse_mpas_preprocess_nml ./input.nml.tmpl $prepinfile $pmoinfile
   echo ${target_greg[0]} ${target_greg[1]} | $preprocess
done 
