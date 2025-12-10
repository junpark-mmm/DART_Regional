! DART software - Copyright UCAR. This open source software is provided
! by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download

! Forward operator to compute total cloud water in a column,
! in kg/m2.   Can be used as an example of a
! forward operator that loops over either fixed pressure levels or
! over model levels.

!>@todo FIXME remove all the TAB characters - technically not supported, can issue warnings

! BEGIN DART PREPROCESS KIND LIST
! GOES_CWP_PATH,      QTY_CWP_PATH
! GOES_LWP_PATH,      QTY_CWP_PATH
! GOES_IWP_PATH,      QTY_CWP_PATH
! GOES_CWP_ZERO,      QTY_CWP_PATH_ZERO
! GOES_LWP_NIGHT,     QTY_CWP_PATH
! GOES_IWP_NIGHT,     QTY_CWP_PATH
! GOES_LWP0_PATH,     QTY_CWP_PATH_ZERO
! GOES_CWP_ZERO_NIGHT,     QTY_CWP_PATH
! END DART PREPROCESS KIND LIST

! BEGIN DART PREPROCESS USE OF SPECIAL OBS_DEF MODULE
!  use obs_def_cwp_mod, only : get_expected_cwp, write_cwp, read_cwp, set_cbp_ctp,interactive_cwp 
! END DART PREPROCESS USE OF SPECIAL OBS_DEF MODULE

! BEGIN DART PREPROCESS GET_EXPECTED_OBS_FROM_DEF
!         case(GOES_CWP_PATH)
!            call get_expected_cwp(state_handle, ens_size, location, "GOES_CWP_PATH", obs_def%key, expected_obs, istatus)
!         case(GOES_LWP_PATH)
!            call get_expected_cwp(state_handle, ens_size, location, "GOES_LWP_PATH", obs_def%key, expected_obs, istatus)
!         case(GOES_IWP_PATH)
!            call get_expected_cwp(state_handle, ens_size, location, "GOES_IWP_PATH", obs_def%key, expected_obs, istatus)
!         case(GOES_CWP_ZERO)
!            call get_expected_cwp(state_handle, ens_size, location, "GOES_CWP_ZERO", obs_def%key, expected_obs, istatus)
!         case(GOES_LWP_NIGHT)
!            call get_expected_cwp(state_handle, ens_size, location, "GOES_LWP_NIGHT", obs_def%key, expected_obs, istatus)
!         case(GOES_IWP_NIGHT)
!            call get_expected_cwp(state_handle, ens_size, location, "GOES_IWP_NIGHT", obs_def%key, expected_obs, istatus)
!         case(GOES_LWP0_PATH)
!            call get_expected_cwp(state_handle, ens_size, location, "GOES_LWP0_PATH", obs_def%key, expected_obs, istatus)
!         case(GOES_CWP_ZERO_NIGHT)
!            call get_expected_cwp(state_handle, ens_size, location, "GOES_CWP_ZERO_NIGHT", obs_def%key, expected_obs, istatus)
! END DART PREPROCESS GET_EXPECTED_OBS_FROM_DEF

! BEGIN DART PREPROCESS WRITE_OBS_DEF
!         case(GOES_CWP_PATH)
!            call write_cwp(obs_def%key, ifile, fform)
!         case(GOES_LWP_PATH)
!            call write_cwp(obs_def%key, ifile, fform)
!         case(GOES_IWP_PATH)
!            call write_cwp(obs_def%key, ifile, fform)
!         case(GOES_CWP_ZERO)
!            call write_cwp(obs_def%key, ifile, fform)
!         case(GOES_LWP_NIGHT)
!            call write_cwp(obs_def%key, ifile, fform)
!         case(GOES_IWP_NIGHT)
!            call write_cwp(obs_def%key, ifile, fform)
!         case(GOES_LWP0_PATH)
!            call write_cwp(obs_def%key, ifile, fform)
!         case(GOES_CWP_ZERO_NIGHT)
!            call write_cwp(obs_def%key, ifile, fform)
! END DART PREPROCESS WRITE_OBS_DEF

! BEGIN DART PREPROCESS READ_OBS_DEF
!         case(GOES_CWP_PATH)
!            call read_cwp(obs_def%key, ifile, fform)
!         case(GOES_LWP_PATH)
!            call read_cwp(obs_def%key, ifile, fform)
!         case(GOES_IWP_PATH)
!            call read_cwp(obs_def%key, ifile, fform)
!         case(GOES_CWP_ZERO)
!            call read_cwp(obs_def%key, ifile, fform)
!         case(GOES_LWP_NIGHT)
!            call read_cwp(obs_def%key, ifile, fform)
!         case(GOES_IWP_NIGHT)
!            call read_cwp(obs_def%key, ifile, fform)
!         case(GOES_LWP0_PATH)
!            call read_cwp(obs_def%key, ifile, fform)
!         case(GOES_CWP_ZERO_NIGHT)
!            call read_cwp(obs_def%key, ifile, fform)
! END DART PREPROCESS READ_OBS_DEF

! BEGIN DART PREPROCESS INTERACTIVE_OBS_DEF
!         case(GOES_CWP_PATH)
!            call interactive_cwp(obs_def%key)
!         case(GOES_LWP_PATH)
!            call interactive_cwp(obs_def%key)
!         case(GOES_IWP_PATH)
!            call interactive_cwp(obs_def%key)
!         case(GOES_CWP_ZERO)
!            call interactive_cwp(obs_def%key)
!         case(GOES_LWP_NIGHT)
!            call interactive_cwp(obs_def%key)
!         case(GOES_IWP_NIGHT)
!            call interactive_cwp(obs_def%key)
!         case(GOES_LWP0_PATH)
!            call interactive_cwp(obs_def%key)
!         case(GOES_CWP_ZERO_NIGHT)
!            call interactive_cwp(obs_def%key)
! END DART PREPROCESS INTERACTIVE_OBS_DEF


! BEGIN DART PREPROCESS MODULE CODE
module obs_def_cwp_mod

! <next few lines under version control, do not edit>
! $URL: https://svn-dares-dart.cgd.ucar.edu/DART/branches/rma_trunk/observations/forward_operators/obs_def_cwp_mod.f90 $
! $Id: obs_def_cwp_mod.f90 11289 2017-03-10 21:56:06Z hendric@ucar.edu $
! $Revision: 11289 $
! $Date: 2017-03-10 15:56:06 -0600 (Fri, 10 Mar 2017) $

use        types_mod, only : r8, missing_r8, RAD2DEG, DEG2RAD, PI, L_over_Rv
use    utilities_mod, only : register_module, error_handler, E_ERR, E_MSG, &
                             file_exist, open_file, close_file, nmlfileunit, ascii_file_format, &
                             find_namelist_in_file, check_namelist_read
use     location_mod, only : location_type, set_location, get_location, &
                             write_location, read_location, &
                             VERTISHEIGHT, VERTISPRESSURE, VERTISSURFACE, VERTISUNDEF, VERTISLEVEL
use time_manager_mod, only : time_type, read_time, write_time, &
                             set_time, set_time_missing
use  assim_model_mod, only : interpolate
use     obs_kind_mod, only : QTY_PRESSURE, QTY_SURFACE_PRESSURE, &
                             !QTY_CLOUD_LIQUID_WATER, QTY_CLOUD_ICE, &
                             QTY_CLOUDWATER_MIXING_RATIO, QTY_ICE_MIXING_RATIO, &
                             QTY_GRAUPEL_MIXING_RATIO, QTY_RAINWATER_MIXING_RATIO, QTY_SNOW_MIXING_RATIO, &
                             QTY_HAIL_MIXING_RATIO, QTY_CWP_PATH, QTY_CWP_PATH_ZERO, &
                             QTY_TEMPERATURE, QTY_VAPOR_MIXING_RATIO, &
                             GOES_CWP_PATH, GOES_LWP_PATH, GOES_IWP_PATH, GOES_CWP_ZERO, &
                             GOES_LWP_NIGHT, GOES_IWP_NIGHT,GOES_LWP0_PATH, GOES_CWP_ZERO_NIGHT
use  ensemble_manager_mod, only : ensemble_type
use obs_def_utilities_mod, only : track_status

implicit none
private

! These are the required interfaces for an obs_def module. 
public ::  get_expected_cwp, set_cbp_ctp, write_cwp, read_cwp, interactive_cwp

! version controlled file description for error handling, do not edit
character(len=128), parameter :: &
   source   = "$URL:  $", &
   revision = "$Revision: unknown $", &
   revdate  = "$Date: 2024-02-22 $"

logical, save :: module_initialized = .false.
logical            :: debug = .false.
character(len=129) :: msgstring

! Define global variables
real(r8), parameter :: gravity = 9.81_r8     ! gravitational acceleration (m s^-2)
real(r8), parameter :: density = 1000.0_r8   ! water density in kg/m^3
integer :: max_plevels = 1000                ! max number of pressure levels (large when using model level option)
integer :: physics = 8                       ! WRF cloud microphysics option DEFAULT

! default samples the atmosphere between the surface and 200 hPa 
! at the model level numbers.  if model_levels is set false,
! then the default samples at 40 heights, evenly divided in
! linear steps in pressure between the surface and top.
logical  :: model_levels = .true.        ! if true, use model levels, ignores num_pres_int
real(r8) :: pressure_top = 20000.0       ! top pressure in pascals
logical  :: separate_surface_level = .true.  ! false: level 1 of 3d grid is sfc
                                             ! true: sfc is separate from 3d grid (WRF)
integer  :: num_plevels = 60  ! number of intervals if model_levels is F

! Storage for the satellite cloud height information required for observations of this type
integer :: num_cwp_obs = 0
integer, parameter :: max_cwp_obs = 2000000
real(r8), allocatable :: cbp_array(:), ctp_array(:), obs_array(:)

namelist /obs_def_cwp_nml/ pressure_top,  physics


contains


subroutine initialize_module
!------------------------------------------------------------------------------

integer :: iunit, io

! Allocate space for the metadata
allocate(cbp_array(max_cwp_obs),  &
         ctp_array(max_cwp_obs), &
         obs_array(max_cwp_obs))

module_initialized = .true.
call register_module(source, revision, revdate)

!CALL NAMELIST INFO
call find_namelist_in_file("input.nml", "obs_def_cwp_nml", iunit)
read(iunit, nml = obs_def_cwp_nml, iostat = io)
call check_namelist_read(iunit, io, "obs_def_cwp_nml")


end subroutine initialize_module


!----------------------------------------------------------------------------
subroutine write_cwp(icwpkey, ifile, fform)
 integer,          intent(in)           :: icwpkey, ifile
 character(len=*), intent(in), optional :: fform

! Write out the additional data associated with this observation.
! The obs is identified by the incoming 'key' argument.
logical, parameter :: debug = .false. 
logical :: is_ascii

if ( .not. module_initialized ) call initialize_module

! Make sure key value is within valid range -- it will be used as an index below.
call check_valid_key(icwpkey, 'GIVEN', 'write_cwp')

is_ascii = ascii_file_format(fform)
if(debug) print*, 'write_cwp: ascii format = ', is_ascii

! Write out the cloud base and cloud top pressure for each observation. The old key is written out
! for tracking/debug use if needed.

if (is_ascii) then
   write(ifile, *) cbp_array(icwpkey), ctp_array(icwpkey)
   write(ifile, *) icwpkey
else
   write(ifile)    cbp_array(icwpkey), ctp_array(icwpkey)
   write(ifile)    icwpkey
endif
if(debug) print*, 'writing out metadata for CWP obs ', icwpkey
if(debug) print*, 'metadata values are: ', cbp_array(icwpkey), ctp_array(icwpkey)

end subroutine write_cwp


!----------------------------------------------------------------------
subroutine read_cwp(icwpkey, ifile, fform)
 integer,          intent(out)          :: icwpkey
 integer,          intent(in)           :: ifile
 character(len=*), intent(in), optional :: fform

! Read in the additional data associated with this observation.
! The key value in the file will be read and then discarded, and a new key
! will be generated based on the next available index in the metadata arrays.
! Notice that key is intent(out) here, not (in) as in some other routines.

logical, parameter :: debug = .false. 
logical            :: is_ascii
integer            :: ignored_icwpkey

if ( .not. module_initialized ) call initialize_module

! Increment the counter so all key values are unique
num_cwp_obs = num_cwp_obs + 1

! Set the return value for the key, and use it as the index below
icwpkey = num_cwp_obs

! Make sure key is within valid range
call check_valid_key(icwpkey, 'GENERATED', 'read_cwp')

is_ascii = ascii_file_format(fform)
if(debug) print*, 'read_cwp ascii format = ', is_ascii

! Read in the additional metadata for this observation, and discard the old key.
if (is_ascii) then
   read(ifile, *) cbp_array(icwpkey), ctp_array(icwpkey)
   read(ifile, *) ignored_icwpkey
else
   read(ifile)    cbp_array(icwpkey), ctp_array(icwpkey) 
   read(ifile)    ignored_icwpkey
endif
if(debug) print*, 'read in metadata for CWP integral obs ', icwpkey
if(debug) print*, 'metadata values are: ', cbp_array(icwpkey), ctp_array(icwpkey), obs_array(icwpkey)

!if(debug) print *, 'ignoring old key', ignored_icwpkey
!if(debug) print *, 'return key set to ', icwpkey

end subroutine read_cwp
!----------------------------------------------------------------------

subroutine interactive_cwp(icwpkey)
 integer, intent(out) :: icwpkey

! Initializes the specialized part of a 1d_integral observation.
! A new key will be generated based on the next available index
! in the metadata arrays.


if ( .not. module_initialized ) call initialize_module

! Increment the counter so all key values are unique
num_cwp_obs = num_cwp_obs + 1

! Set the return value for the key, and use it as the index below
icwpkey = num_cwp_obs

! Make sure key is within valid range
call check_valid_key(icwpkey, 'GENERATED', 'interactive_cwp')

! Prompt for input for the three required metadata items
write(*, *) 'Creating an interactive_clwp observation'

write(*, *) 'Input bottom cloud boundary in pressure (pascals)'
 read(*, *) cbp_array(icwpkey)

write(*, *) 'Input top cloud boundary in pressure (pascals)'
 read(*, *) ctp_array(icwpkey)

if(debug) print *, 'return key set to ', icwpkey

end subroutine interactive_cwp
!----------------------------------------------------------------------


subroutine set_cbp_ctp(icwpkey, cbp_value, ctp_value)
 integer,  intent(out) :: icwpkey
 real(r8), intent(in)  :: cbp_value, ctp_value
 
 if ( .not. module_initialized ) call initialize_module
 
 
 ! Increment the counter so all key values are unique
 num_cwp_obs = num_cwp_obs + 1

! Set the return value for the key, and use it as the index below
 icwpkey = num_cwp_obs
 
 ! Make sure key is within valid range
 call check_valid_key(icwpkey, 'GENERATED', 'set_cbp_ctp')
 
 cbp_array(icwpkey) = cbp_value
 ctp_array(icwpkey) = ctp_value

end subroutine set_cbp_ctp
!----------------------------------------------------------------------


 subroutine get_expected_cwp(state_handle, ens_size, location, varname, icwpkey, out_wp, istatus)
!------------------------------------------------------------------------------
! Purpose:  To calculate cloud liquid water path (kg/m2) from model cloud liquid water.
! inputs:
!    state_handle, ens_size:    handle to an ensemble of dart state vectors and the ensemble size
!    location:        Observation location
!	 ctp, cbp		  GOES cloud top and cloud base pressures 
!
! output parameters:
!    clwp: total liquid water path and ice water path (in kg/m2) from all model analyzed cloud liquid water
!	      **** FOR compatibility with satellite data, clwp = qcloud + qice + qgraup + qrain +qsnow + qhail
!------------------------------------------------------------------------------
!  Author: Thomas A. Jones ,  Version 1.4: Aug 2, 2017 for WRF-ARW and NETCDF DART
!                Version 0.6: April 2012        Add code for QHAIL (ZVD microphysics only)
!                Version 0.7: May 23 2012       Add actual surface elevation to replace h=0 assumption, 
!                                                 which was only good for over oceans   
!                Version 0.8: July 31 2012      Add model level option to correspond with new TPW operator
!                Version 0.9: Sept 7 2012       Added if/then statments to account for difference micropyhiscs options
!                                                 Numbers based on WRF namelist.input definitions
!                                               (wrf_state_variables in input.nml must also be consistent with this option)
!
!                Version 1.0: Jan 13 2014       Add CWP_ZERO variable type for clear sky observations (cwp = 0 kg m-2)
!                Version 1.1: Dec 8 2015        Revomved surface elevation code for surface calculations and replaced
!                                                first model level calculation
!                Version 1.2: Dec 22 2015       Add RH calculation to determine where thick clouds already present 
!                                                in the model. Set cwp value to missing so that nothing happens here
!                Version 1.3: Feb 16 2016       Modifed to function with netcdf DART version
!                Version 1.4: Aug 2  2017	Updated for DART-MAN version (TJ / KK).
!                Version 2.0: 2022              Updated with latest updates from GSI forward operator / obs processing code
!                Version 2.1: June 15 2023      Updated with GOES_LWP/IWP_NIGHT variable for future use (highly unlikely)
!                Version 2.2: Nov 20 2023       Added other night time CWP variable information / check for below freezing for LWP
!   
!
!  Based off of TPW forward operator developed by Hui Liu at NCAR                               
!------------------------------------------------------------------------------
implicit none

type(ensemble_type), intent(in)  :: state_handle
integer,             intent(in)  :: ens_size
type(location_type), intent(in)  :: location
character(13),       intent(in)  :: varname
integer,             intent(in)  :: icwpkey
real(r8),            intent(out) :: out_wp(ens_size)
integer,             intent(out) :: istatus(ens_size)

! local variables
type(location_type) :: location2, location3
real(r8), dimension(ens_size, max_plevels+1) :: press, qc, qi, qr, qg, qha, qs, qv, tmpk, rh
real(r8), dimension(ens_size) :: psfc, press_int
real(r8), dimension(ens_size) :: cwp, iwp, lwp, es, qsat
real(r8) :: lon, lat, height, obsloc(3)
real(r8) :: lon2, q, p, satctp, satcbp, satcwp, layer_rh, layer_tk
real(r8) :: wrfcbp, wrfctp
integer :: which_vert, k, mink, maxk, lastk, first_non_surface_level, bbb, ttt, i
integer :: this_istatus(ens_size)
logical :: return_now

if ( .not. module_initialized ) call initialize_module

! Make sure key is within valid range
call check_valid_key(icwpkey, 'GIVEN', 'get_expected_cwp')

! errors accumulate across ensemble members, so start with istatus = 0
out_wp(:) = missing_r8   
istatus(:) = 0

obsloc   = get_location(location)
lon      = obsloc(1)                   ! degree: 0 to 360
lat      = obsloc(2)                   ! degree: -90 to 90
height   = obsloc(3)                   ! cloud median height in pressure (Pa)


lon2 = lon
if(lon > 360.0_r8 ) lon2 = lon - 360.0_r8
if(lon <   0.0_r8 ) lon2 = lon + 360.0_r8

which_vert = VERTISLEVEL
location2 = set_location(lon2, lat, 1.0_r8,  which_vert)

 tmpk(:,:) = 0.0_r8
 qv(:,:) = 0.0_r8
 qc(:,:) = 0.0_r8
 qi(:,:) = 0.0_r8
 qg(:,:) = 0.0_r8
 qr(:,:) = 0.0_r8
 qs(:,:) = 0.0_r8
 qha(:,:) = 0.0_r8
 rh(:,:) = 0.0_r8

!******* SIMUlATED DATA DOES NOT HAVE ANY SURFACE LEVEL INFORMATION

!  interpolate the surface pressure to the desired location (Pa)
 call interpolate(state_handle, ens_size, location2, QTY_SURFACE_PRESSURE, psfc, this_istatus)
 call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
 if (return_now) return

 press(:, 1) = psfc
 
!  READ IN QCLOUD AT SURFACE (kg/kg)
if (physics >= 1)  then
 !call interpolate(state_handle, ens_size, location2, QTY_CLOUD_LIQUID_WATER, qc(:, 1), this_istatus)
 call interpolate(state_handle, ens_size, location2, QTY_CLOUDWATER_MIXING_RATIO, qc(:, 1), this_istatus)
 call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
 if (return_now) return
endif

!  READ IN QICE AT SURFACE (kg/kg)
if (physics == 2 .or. physics == 4 .or. physics >= 6)  then
 !call interpolate(state_handle, ens_size, location2, QTY_CLOUD_ICE, qi(:, 1), this_istatus)
 call interpolate(state_handle, ens_size, location2, QTY_ICE_MIXING_RATIO, qi(:, 1), this_istatus)
 call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
 if (return_now) return
endif 

!  READ IN QGRUAPEL AT SURFACE (kg/kg)
if (physics == 2 .or. physics >= 6)  then
 if (physics /= 14) then
  call interpolate(state_handle, ens_size, location2, QTY_GRAUPEL_MIXING_RATIO, qg(:, 1), this_istatus)
  call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
  if (return_now) return
 endif
endif

!  READ IN QRAIN AT SURFACE (kg/kg)
if (physics >= 1)  then
 call interpolate(state_handle, ens_size, location2, QTY_RAINWATER_MIXING_RATIO, qr(:, 1), this_istatus)
 call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
 if (return_now) return
endif

!  READ IN QSNOW AT SURFACE (kg/kg)
if (physics == 2 .or. physics == 4 .or. physics >= 6)  then
 call interpolate(state_handle, ens_size, location2, QTY_SNOW_MIXING_RATIO, qs(:, 1), this_istatus) 
 call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
 if (return_now) return
endif

!  READ IN QHAIL AT SURFACE (kg/kg)  MY AND ZVD (OTHERWISE, JUST ASSUME qha = 0)
if (physics == 9 .or. physics >= 17) then
 call interpolate(state_handle, ens_size, location2, QTY_HAIL_MIXING_RATIO, qha(:, 1), this_istatus)
 call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
 if (return_now) return
endif

! READ IN QVAPOR AT SURFACE (kg/kg)
 call interpolate(state_handle, ens_size, location2, QTY_VAPOR_MIXING_RATIO, qv(:,1), this_istatus)
 call track_status(ens_size, this_istatus, out_wp, istatus, return_now)

! READ IN TEMPERATURE AT SURFACE (K)
 call interpolate(state_handle, ens_size, location2, QTY_TEMPERATURE, tmpk(:,1), this_istatus)
 call track_status(ens_size, this_istatus, out_wp, istatus, return_now)

! CALCULATE RH AT THE SURFACE
es   = 611.0_r8 * exp(L_over_Rv * (1.0_r8 / 273.0_r8 - 1.0_r8 / tmpk(:,1) ))
qsat = 0.622_r8 * es / (press(:,1) - es)
rh(:,1)   = qv(:,1) / qsat


! CHECK FOR NEGATIVE VALUES
where (  qc(:, 1) < 0.0_r8 )  qc(:, 1) = 0.0_r8
where (  qi(:, 1) < 0.0_r8 )  qi(:, 1) = 0.0_r8
where (  qg(:, 1) < 0.0_r8 )  qg(:, 1) = 0.0_r8
where (  qr(:, 1) < 0.0_r8 )  qr(:, 1) = 0.0_r8
where (  qs(:, 1) < 0.0_r8 )  qs(:, 1) = 0.0_r8
where ( qha(:, 1) < 0.0_r8 ) qha(:, 1) = 0.0_r8
where ( rh(:,1) < 0.0_r8 ) rh(:,1) = 0.0001_r8

! GET CBP AND CTP FROM SATELLITE DATA (metadata in obs_seq file)
satcbp = cbp_array(icwpkey)
satctp = ctp_array(icwpkey)

! CHECK IF GOOD DATA
! probably not needed anymore - would have returned sooner if any failed
if (any(istatus /= 0)) then
   out_wp(:) = missing_r8
  ! print *, psfc, qcloud, qice,  qgruap, qrain, qsnow, istatus
   return
endif

   
   ! some models have a 3d grid of values and the lowest level contains
   ! the surface quantities.  others have a separate field for the
   ! surface values and the 3d grid starts at some given elevation.
   ! if the namelist value 'separate_surface_level'  is true, we will
   ! ask to interpolate a surface pressure first and then work up the
   ! 3d column starting at level 1.  if it is false, we assume level 1
   ! was the surface pressure and we start here at level 2.

   if (separate_surface_level) then
      first_non_surface_level = 1
   else
      first_non_surface_level = 2
   endif

   ! construct a pressure column on model levels

   ! call the model until the interpolation call fails (above the top level)
   ! (this is not a fatal error unless the first call fails).
   ! also exit the loop if the pressure is above the namelist-specified pressure top

   lastk = 2
   LEVELS: do k=first_non_surface_level, 10000   ! something unreasonably large
   

      ! call the model_mod to get the pressure and specific humidity at each level 
      ! from the model and fill out the pressure and q arrays.  the model must
      ! support a vertical type of level number.

      which_vert = VERTISLEVEL
      location2 = set_location(lon2, lat, real(k, r8),  which_vert)

      call interpolate(state_handle, ens_size, location2, QTY_PRESSURE, press(:, lastk), this_istatus)
      if (any(this_istatus /= 0 .or. press(:, lastk) < pressure_top)) exit LEVELS

	  ! ADD VERTICAL COORD TO LOCATION (no need)
	  !location3 = set_location(lon2, lat, press(1, lastk),  which_vert)

	  if (physics >= 1)  then
	    !call interpolate(state_handle, ens_size, location2,  QTY_CLOUD_LIQUID_WATER, qc(:, lastk), this_istatus)
            call interpolate(state_handle, ens_size, location2, QTY_CLOUDWATER_MIXING_RATIO, qc(:, lastk), this_istatus)
            call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
            if (return_now) return
	  endif
	  
	  if (physics == 2 .or. physics == 4 .or. physics >= 6)  then
	    !call interpolate(state_handle, ens_size, location2,  QTY_CLOUD_ICE, qi(:, lastk), this_istatus)
            call interpolate(state_handle, ens_size, location2, QTY_ICE_MIXING_RATIO, qi(:, lastk), this_istatus)
            call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
            if (return_now) return
	  endif
	  
	  if (physics == 2 .or. physics >= 6)  then
            if (physics /= 14) then
                call interpolate(state_handle, ens_size, location2,  QTY_GRAUPEL_MIXING_RATIO, qg(:, lastk), this_istatus)
                call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
                if (return_now) return
            endif
	  endif
	  
	  if (physics >= 1)  then
	    call interpolate(state_handle, ens_size, location2,  QTY_RAINWATER_MIXING_RATIO, qr(:, lastk), this_istatus)
            call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
            if (return_now) return
	  endif
	  
	  if (physics == 2 .or. physics == 4 .or. physics >= 6)  then
	    call interpolate(state_handle, ens_size, location2,  QTY_SNOW_MIXING_RATIO, qs(:, lastk), this_istatus)
            call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
            if (return_now) return
	  endif
	  
	  if (physics == 9 .or. physics >= 17) then
	    call interpolate(state_handle, ens_size, location2,  QTY_HAIL_MIXING_RATIO, qha(:, lastk), this_istatus)
            call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
            if (return_now) return
	  endif
	  !qha(lastk) = 0.0_r8
      
         ! READ IN QVAPOR AT MODEL LEVEL (kg/kg)
         call interpolate(state_handle, ens_size, location2, QTY_VAPOR_MIXING_RATIO, qv(:,lastk), this_istatus)
         call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
         if (return_now) return

        ! READ IN TEMPERATURE AT THE MODEL LEVEL (K)
         call interpolate(state_handle, ens_size, location2, QTY_TEMPERATURE, tmpk(:,lastk), this_istatus)
         call track_status(ens_size, this_istatus, out_wp, istatus, return_now)
         if (return_now) return

        ! CALCULATE RH AT THE MODEL LEVEL
         es   = 611.0_r8 * exp(L_over_Rv * (1.0_r8 / 273.0_r8 - 1.0_r8 / tmpk(:,lastk) ))
         qsat = 0.622_r8 * es / (press(:,lastk) - es)
         rh(:,lastk)   = qv(:,lastk) / qsat

  
      ! probably not needed anymore - would have returned sooner if any failed
      if (any(istatus /= 0)) return
   
      !print *, 'MODEL LEVEL: ', k, press(:, lastk), qc(:, lastk), qi(:, lastk), qg(:, lastk), qr(:, lastk), qs(:, lastk)
   
   
   		! CHECK FOR NEGATIVE VALUES
		where (  qc(:, lastk) < 0.0_r8 )  qc(:, lastk) = 0.0_r8
		where (  qi(:, lastk) < 0.0_r8 )  qi(:, lastk) = 0.0_r8
		where (  qg(:, lastk) < 0.0_r8 )  qg(:, lastk) = 0.0_r8
		where (  qr(:, lastk) < 0.0_r8 )  qr(:, lastk) = 0.0_r8
		where (  qs(:, lastk) < 0.0_r8 )  qs(:, lastk) = 0.0_r8
		where ( qha(:, lastk) < 0.0_r8 ) qha(:, lastk) = 0.0_r8
                where ( rh(:, lastk) < 0.0_r8 ) rh(:, lastk) = 0.0001_r8 
      lastk = lastk + 1
   enddo LEVELS

   lastk = lastk - 1

   ! if we got no valid values, set istatus and return here.
   if (lastk == 1) then 
      istatus(:) = 3
      return
   endif

!*** BEGIN MEMBER LOOP
cwp(:) = 0.0_r8
lwp(:) = 0.0_r8
iwp(:) = 0.0_r8

do i=1, ens_size

! CALCULATE MIN AND MAX LEVEL TO INTERGRATE OVER USING CBP/CTP
!print *, 'CALC CB, CT PRESSURE LEVELS'
mink=1
maxk=lastk-1
bbb=0
ttt=0
if (satcbp > 0.0 .and. satctp > 0.0) then

	do k=1, lastk+1
	  if ( press(i, k) > 10000.0) then 
	
		! CLOUD BASE LEVEL
		if (satcbp > press(i, k) .and. bbb == 0) then
			mink=k
			bbb=1
		endif
		! CLOUD TOP LEVEL
		if (satctp > press(i, k) .and. ttt == 0) then
			maxk=k
			ttt=1
		endif
		
		!print*, press(k), satcbp, satctp
	  endif
	end do
endif

if (mink < 2) mink = 2


! TOTAL UP CWP FROM CLOUD BASE TO CLOUD TOP (for an individual layer)
!	Multiple layers treated as seperate observations

if (maxk > mink) then
  do k=mink, maxk
	
	!if (any(press(i, k) < press(i, k+1)) ) print*, press(i, k), press(i, k+1), lon, lat
	
	if (press(i, k) > 10000.0 .and. press(i, k+1) > 10000.0 .and. press(i,k) > press(i, k+1) .and. press(i, k) < 110000.0 )  then	
	
		cwp(i) = cwp(i) + 0.5_r8 * ( (qc(i, k) + qc(i, k+1)) + (qi(i, k) + qi(i, k+1)) + (qg(i, k) + qg(i, k+1)) + &
                      (qr(i, k) + qr(i, k+1)) + (qs(i, k) + qs(i, k+1)) + (qha(i, k) + qha(i, k+1)) ) * (press(i, k) - press(i, k+1))
	
		lwp(i) = lwp(i) + 0.5_r8 * ( (qc(i, k) + qc(i, k+1)) + (qr(i, k) + qr(i, k+1)) ) * (press(i, k) - press(i, k+1))
		
		iwp(i) = iwp(i) + 0.5_r8 * ( (qi(i, k) + qi(i, k+1)) + (qg(i, k) + qg(i, k+1)) + &
                      (qs(i, k) + qs(i, k+1)) + (qha(i, k) + qha(i, k+1)) ) * (press(i, k) - press(i, k+1)) 

        endif

!	where (cwp < 0.0 .or. cwp > 200.0) 
!print '(I5, 4F10.3, 12F12.6,4F10.3)', k, press(:, k), press(:, k+1), lon, lat, qc(:, k), qc(:, k+1), &
!        qr(:, k), qr(:, k+1), qi(:, k), qi(:, k+1), qs(:, k), qs(:, k+1), qg(:, k) , qg(:, k+1), qha(:, k), qha(:, k+1), &
!        cwp, lwp, iwp, (press(:, k) - press(:, k+1))
!	endwhere

  enddo

  layer_rh = sum(rh(i, mink:maxk)) / (max(1,size(rh(i, mink:maxk))))
  layer_tk = sum(tmpk(i, mink:maxk)) / (max(1,size(tmpk(i, mink:maxk))))

  ! IF environment is nearly staturated, do not assimilated IWP/LWP
  if ( trim(varname) == "GOES_IWP_PATH" .and. layer_rh .gt. 0.975 ) cwp(i) = -998.0
  if ( trim(varname) == "GOES_LWP_PATH" .and. layer_rh .gt. 0.975 ) lwp(i) = -998.0
  if ( trim(varname) == "GOES_IWP_NIGHT" .and. layer_rh .gt. 0.975 ) cwp(i) = -998.0
  if ( trim(varname) == "GOES_LWP_NIGHT" .and. layer_rh .gt. 0.975 ) lwp(i) = -998.0

  ! CHECK IF Layer temperature is below freezing for LWP retreivals...
  if ( trim(varname) == "GOES_LWP_PATH" .and. layer_tk .lt. 273.0 ) then
  !   print*, 'LWP - FREEZING CHECK: ', layer_tk, lwp(i)
     lwp(i) = cwp(i)
  endif
  if ( trim(varname) == "GOES_LWP_NIGHT" .and. layer_tk .lt. 273.0 ) lwp(i) = cwp(i)

endif

enddo
!END MEMBER LOOP
!CHECK FOR NEGATIVE VALUES
where (cwp < 0.0 ) cwp = 0.0
where (iwp < 0.0 ) iwp = 0.0
where (lwp < 0.0 ) lwp = 0.0

!CONVERT TO PATH UNITS (kg/m2)
where (cwp > 0.0 ) cwp = 1.0 * cwp /(gravity)   ! -> kg/m2
where (lwp > 0.0 ) lwp = 1.0 * lwp /(gravity)   ! -> kg/m2
where (iwp > 0.0 ) iwp = 1.0 * iwp /(gravity)   ! -> kg/m2

!SET MAX MODEL CWP VALUE TO 5 kg/m2 to correspond with satellite saturation value
where (cwp > 5.0 ) cwp = 5.0
where (iwp > 5.0 ) iwp = 5.0
where (lwp > 3.0 ) lwp = 3.0

!IF MODEL CWP > Saturation CWP Retrival Value
!    set forward operator output to bad
!where (cwp > 6.0 ) cwp = -997.0
!where (iwp > 6.0 ) iwp = -997.0
!where (lwp > 3.0 ) lwp = -997.0


!********************* ASSIGN CORRECT PATH (ALL/ICE/WATER) TO OUTPUT VARIABLE
!out_wp(:) = cwp
if ( trim(varname) == "GOES_CWP_PATH" ) out_wp = cwp
if ( trim(varname) == "GOES_CWP_ZERO" ) out_wp = cwp
if ( trim(varname) == "GOES_IWP_PATH" ) out_wp = cwp   !iwp	
if ( trim(varname) == "GOES_LWP_PATH" ) out_wp = lwp
if ( trim(varname) == "GOES_LWP0_PATH" ) out_wp = iwp !don't use

!NIGHT TIME DATA
if ( trim(varname) == "GOES_LWP_NIGHT" ) out_wp = lwp
if ( trim(varname) == "GOES_IWP_NIGHT" ) out_wp = cwp
if ( trim(varname) == "GOES_CWP_ZERO_NIGHT" ) out_wp = cwp

!if (cwp < 0.0 .or. cwp > 100.0) then
!print '(A18, 2F10.3, 4F12.6,4F10.3, 2I6)', trim(varname), lon, lat, cwp,iwp,lwp,out_wp,  satcbp/100.0, satctp/100.0, press(mink)/100.0, press(maxk)/100.0
!print*, trim(varname),  cwp(i),iwp(i),lwp(i),out_wp(i) !,  satcbp/100.0, satctp/100.0
!endif

end subroutine get_expected_cwp


!----------------------------------------------------------------------

subroutine check_valid_key(icwpkey, what, fromwhere)
 integer, intent(in)          :: icwpkey
 character(len=*), intent(in) :: what, fromwhere

! Internal subroutine that verifies that we haven't incremented the key value
! past the size of the allocated space, or that a routine hasn't been called
! with a out-of-range key (which would indicate an internal error of some kind).
! If an error is found, an fatal message is printed and this routine doesn't return.
! The 'what' argument is either 'GIVEN' for a key value that's passed in from
! another routine; or 'GENERATED' for one we have just made and are planning to
! return to the caller.  The 'fromwhere' argument is the name of the calling 
! subroutine so the error message can report where it was called from.

character(len=128) :: msgstring

if (icwpkey <= 0 .or. icwpkey > max_cwp_obs) then
   if (what == 'GENERATED' .and. icwpkey > max_cwp_obs) then
      ! generating a new key and ran out of space
      write(msgstring, *)'Out of space, max_clwp_obs limit ',max_cwp_obs
      call error_handler(E_ERR,trim(fromwhere),msgstring,source,revision,revdate, &
                         text2='Increase value of max_clwp_obs in obs_def_1d_state_mod')
   else
     ! called with a bad key or a negative key generated somehow. "shouldn't happen".
      write(msgstring, *)'Key is ',icwpkey,' must be between 1 and ',max_cwp_obs
      call error_handler(E_ERR,trim(fromwhere),msgstring,source,revision,revdate, &
                         text2='Internal error: Invalid key value in RAW_STATE_1D_INTEGRAL obs')
   endif
endif

end subroutine

end module obs_def_cwp_mod

! END DART PREPROCESS MODULE CODE

! <next few lines under version control, do not edit>
! $URL: https://svn-dares-dart.cgd.ucar.edu/DART/branches/rma_trunk/observations/forward_operators/obs_def_cwp_mod.f90 $
! $Id: obs_def_cwp_mod.f90 11289 2017-03-10 21:56:06Z hendric@ucar.edu $
! $Revision: 11289 $
! $Date: 2017-03-10 15:56:06 -0600 (Fri, 10 Mar 2017) $
