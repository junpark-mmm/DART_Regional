#!/bin/tcsh
#
# DART software - Copyright UCAR. This open source software is provided
# by UCAR, "as is", without charge, subject to all terms of use at
# http://www.image.ucar.edu/DAReS/DART/DART_download
#
set echo
########################################################################################
# Set up parameters that are used for other scripts throughout the cycling period.
# Note: 1. Specify a full path name at each line.
#       2. Namelist options should be specified for all Namelist files separately.  
########################################################################################
#
# General configuration 
#
set EXPERIMENT_NAME = base15km.3
set MPAS_GRID       = conus  	# Prefix of MPAS files (ex. wofs_mpas.afterda.nc)
set FILTER_NML      = input.nml.eakf.inf2.baseline3
set MODFILE         = /glade/u/home/swei/Git/utils/mpas/modulefiles/setup_derecho_intel.sh

set MULTIPHYSICS    = false 	# true  : use multiphysics ensemble in advance_model.csh. default is false.
set USE_REGIONAL    = true 	# true  : use regional MPAS-A => calls update_bc.
                                # false : use global MPAS-A
set USE_RESTART     = false	# true  : use Restart file at streams
                          	# false : use invariant and da_state file at streams; see template/streams.atmosphere.new
                                #         invariant stream is supported after v8.1.0? (will be updated later)
set USE_RTTOV       = true	# true  : check RTTOV_FILES below and define &obs_def_rttov_nml in input.nml.

set DATE_INI = 2024-05-08_18:00:00      # initial cycle for spin-up or for the first guess time.
set DATE_BEG = 2024-05-09_23:00:00      # start date to run this script for cycling
set DATE_END = 2024-05-10_00:00:00      # end date to run this script for cycling; excluding extended forecasts 
set INTV_DAY = 0                        # assimilation_period_days    in input.nml for cycling frequency
set INTV_SEC = 3600                      # assimilation_period_seconds in input.nml for cycling frequency

# Model configuration in namelist.atmosphere
set     LEN_DISP = 15000         	# = 3 km; the finest resolution of the mesh [meter]
set      DT_MPAS = 60    		# config_dt [seconds] = LEN_DISP/1000. * 5 (or 4 or 6)

# PBS setup for NCAR HPCs (Derecho)
set   RUN_IN_PBS = yes           # Run on derecho using PBS? yes or no    # Change #
set  PROJ_NUMBER = NMMM0063	# Your account key for derecho  # Change #
set FILTER_NODES = 2            # for Derecho: -l select for DART/filter 
set  MODEL_NODES = 1            # for Derecho: -l select for MPAS/atmosphere_model
set       N_CPUS = 128		# for Derecho: ncpus - no. of cpus per node (default = 128)
set N_PROCS_ANAL = 128		# Number of mpi processors for filter; reduce this for a large memory
set N_PROCS_MPAS = 128		# Number of mpi processors for MPAS (=> MODEL_NODES * N_PROCS_MPAS for graph.info)
set QUEUE_FILTER = premium	# queue priority for filter
set   QUEUE_MPAS = premium      # queue priority for mpas job (when queue is 'main' at derecho)
#set    MEMORY_GB = 230          # memory per node (GB) ; default mem=230GB (derecho)
set  TIME_FILTER = 02:00:00	# wall clock time for mpi filter runs
set    TIME_MPAS = 00:05:00	# walltime for prior forecast during DA - set walltime as the SMALLEST possible!


set   SST_UPDATE = false
set   SST_FNAME  = ${MPAS_GRID}.sfc_update.nc

# Ensemble filter configuration
set     ENS_SIZE = 60 	 	# Ensemble size
set ADAPTIVE_INF = true         # adaptive_inflation - If true, this script only supports
                                # spatially-varying state space prior inflation.
                                # And you also need to edit inf_sd_initial, inf_damping,
                                # inf_lower_bound, and inf_sd_lower_bound in &filter_nml
set       CUTOFF = 0.02        # half-width localization radius
set   VLOC_COORD = 3		# vertical localization in height => set vert_normalization_height
set         VLOC = 400000     # half-width localization radius in height [meters] - will be mulplied by CUTOFF
set num_output_obs_members = $ENS_SIZE   # output members in obs_seq.out
set num_output_state_members = $ENS_SIZE # output members in output states    
set binary_obs_seq = false        # binary or ascii obs_seq.final to produce
set DISTRIB_MEAN = false          # true for a large-memory job; false otherwise
set CONVERT_OBS  = true           # convert_all_obs_verticals_first = .true. in &assim_tools_nml
set CONVERT_STAT = false        #   convert_all_state_verticals_first = .false. in &assim_tools_nml
                                
set     INFL_OUT = output_priorinf
set      INFL_IN = input_priorinf

# First Guess (for cold-start runs and initial ensemble)
set GRIB_DATA = HRRRE       # GRIB DATA TYPE : GFS or GFSENS(GEFS) 
                            # for GFS or ERA5,  DART will be run to add perturbations.
                            # for GEFS, will use external data from GEFS ensemble
			    # for HRRRE, to test WOFS configuration ( data is not in public)
set   VTABLE  = Vtable.${GRIB_DATA}

# Directories
set MPAS_DIR     = /glade/work/swei/projects/hydrosat/repos/MPAS-Model
set DART_DIR     = /glade/work/swei/projects/hydrosat/repos/DART_Regional
set DATA_DIR     = /glade/work/swei/projects/hydrosat/mpas.configs/15km
set EXE_DIR      = ${DART_DIR}/models/mpas_atm/work
set CSH_DIR      = ${DART_DIR}/models/mpas_atm/shell_scripts

set ROOT_DIR     = /glade/derecho/scratch/swei/hydrosat_tmp/MPAS-DART

set OBS_DIR      = /glade/campaign/mmm/parc/swei/exp_obs/superob_hydrosat.5       	# obs_seq.out
set GRIB_DIR     = ${ROOT_DIR}/grib		# for GRIB_DATA thru create_init_ensemble.csh
set INIT_DIR     = /glade/derecho/scratch/junpark/rMPAS-DART_QU15KM_CNTL_FINAL/output_rec             # MPAS initial ensemble under each member dir.
set LBC_DIR      = /glade/derecho/scratch/junpark/rMPAS-DART_QU15KM_CNTL_FINAL/init_rec_hourly            # LBCs under YYYYMMDDHHMM in this dir.
set TEMPLATE_DIR = /glade/work/swei/projects/hydrosat/mpas.configs/15km		# FIXME: ${DART_DIR}/models/mpas_atm/data
set SST_DIR      = ${ROOT_DIR}/sst		# sfc_update.nc

set BASE_DIR     = ${ROOT_DIR}/${EXPERIMENT_NAME}
set RUN_DIR      = ${BASE_DIR}                    	# Run MPAS/DART cycling
set GRID_DIR     = ${TEMPLATE_DIR}

set ENS_DIR      = member   	# Prefix for ensemble directory. This should match with advance_model.csh/temp_dir.

# init_template_filename in &model_nml in input.nml
set INIT_FNAME = restart.`echo $DATE_INI | sed -e 's/:/\./g'`.nc
set F_TEMPLATE = ${TEMPLATE_DIR}/${MPAS_GRID}.init.nc
set F_GRAPH    = ${MPAS_GRID}.graph.info.part	# add .$ndecomp (= $MODEL_NODES * $N_PROCS)

# Namelist files
set NML_INIT     = namelist.init_atmosphere      # Namelist for init_atmosphere_model
set NML_MPAS     = namelist.atmosphere		 # Namelist for atmosphere_model
set NML_WPS      = namelist.wps			 # Namelist for WPS
set NML_DART     = input.nml			 # Namelist for DART
set STREAM_ATM   = streams.atmosphere		 # I/O list for atmosphere_model
set STREAM_ATM_IN = streams.atmosphere.da_state.1hr		 # I/O list for atmosphere_model, will be copied to STREAM_ATM
set STREAM_INIT  = streams.init_atmosphere	 # I/O list for init_atmosphere_model

# User-defined coefficient files
set RTTOV_CSV    = ${DART_DIR}/observations/forward_operators/rttov_sensor_db.csv
set RTTOV_INPUT1 = /glade/campaign/mmm/parc/swei/rtcoef/rtcoef_dummy_5_dummyir.dat
set RTTOV_INPUT2 = /glade/campaign/mmm/parc/swei/rtcoef/sccldcoef_dummy_5_dummyir.dat
set RTTOV_FILES  = ( ${RTTOV_CSV} ${RTTOV_INPUT1} ${RTTOV_INPUT2} )

set SAMPLING_ERR_TBL = ${DART_DIR}/assimilation_code/programs/gen_sampling_err_table/work/sampling_error_correction_table.nc
#set BNRHF_CSV    = ${DATA_DIR}/dual_qceff_table.csv
#set KDEF_CSV     = ${DATA_DIR}/kde_qceff_table.csv
set MPAS_LEVEL_TXT   = L60.txt

# A list of model prognostic variables for prior backup before analysis, 
# if save_prior = true in advance_model.csh: mpas_state_variables in &mpas_vars_nml
set VARLIST = 'xtime,theta,rho,u,w,qv,qc,qr,qi,qs,qg,uReconstructZonal,uReconstructMeridional,t2m,u10,v10,q2,surface_pressure'

# mpas_lbc_variables in input.nml
set LBCLIST = "'lbc_qc', 'lbc_qr', 'lbc_qv', 'lbc_rho', 'lbc_theta', 'lbc_u', 'lbc_w'"

# Commands (do not need modification unless moving to new system)
set REMOVE = '/bin/rm -rf'
set   COPY = 'cp -pf'
set   MOVE = 'mv -f'
set   LINK = 'ln -sf'
unalias cd
unalias ls
