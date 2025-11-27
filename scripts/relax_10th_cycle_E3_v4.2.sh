#!/bin/bash
E=3
dT=-6.5
dPdz=-0.095
temp_sd=1.8
EXDT=1
EXVARS='thk,velsurf_mag,surface_melt_rate,surface_runoff_rate'
TSTIME=yearly
BOOT=relax_9th_cycle_E${E}_v4.2.nc
OUTFILENAME=relax_10th_cycle_E${E}_v4.2 

# check if env var PISM_DO was set (i.e. PISM_DO=echo for a 'dry' run)
if [ -n "${PISM_DO:+1}" ] ; then  
  echo "$SCRIPTNAME         PISM_DO = $PISM_DO  (already set)"
else
  PISM_DO="" 
fi
PROJ_LIB=/usr/share/proj
PISM_ONESTATION=pism_one_station_tas_cold_noleap-with-bounds.nc
PISM_DATANAME=force_to_thickness_v2_ftt.nc


regridcommand="-regrid_file $BCFILE -regrid_vars basal_melt_rate_grounded,tillwat,enthalpy,litho_temp"

CLIMATE="-atmosphere one_station,elevation_change \
		     -atmosphere.one_station.file $PISM_ONESTATION \
		     -atmosphere.elevation_change.file $BOOT \
		     -atmosphere.elevation_change.temperature_lapse_rate $dT \
		     -atmosphere.elevation_change.precip_adjustment shift \
		     -atmosphere.elevation_change.precipitation.lapse_rate $dPdz \
		     -surface pdd,forcing \
		     -force_to_thickness_file $PISM_DATANAME \
		     -surface.pdd.std_dev.value ${temp_sd} \
		     -sea_level constant "

PHYS="-pik \
      -sia_e ${E} \
      -stress_balance ssa+sia \
      -topg_to_phi 15.0,40.0,-300.0,700.0 \
      -till_effective_fraction_overburden 0.02 \
      -pseudo_plastic -pseudo_plastic_q 0.25 \
      -tauc_slippery_grounding_lines \
      -calving float_kill \
      -calving.float_kill.margin_only false \
      -calving.float_kill.calve_near_grounding_line false "

NN=24
firstnode=0
lastnode=24


RUNSTART=1778
RUNEND=1896



xmin=80793.
ymin=-2650282.
xmax=388422.
ymax=-2226046.

# Set paralell run options
PISM="taskset -c ${firstnode}-${lastnode} pismr -regional"

cmd="mpiexec -n $NN $PISM -i $BOOT \
    $PHYS \
    -regional.zero_gradient true \ 
    -stress_balance.sia.max_diffusivity 500000 \  
    -extra_file ex_${OUTFILENAME}.nc -extra_times $RUNSTART:$EXDT:$RUNEND \
    -extra_vars $EXVARS \
    -ts_file ts_${OUTFILENAME}.nc -ts_times $RUNSTART:$TSTIME:$RUNEND \
    $CLIMATE -ys $RUNSTART -ye $RUNEND -o ${OUTFILENAME}.nc"
$PISM_DO $cmd
