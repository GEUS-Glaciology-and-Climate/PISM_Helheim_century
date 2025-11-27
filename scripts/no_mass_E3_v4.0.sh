#!/bin/bash
E=3
dT=-6.5
temp_sd=1.8
dT_precip=-6.5
dPdz=-0.095
OUTFILENAME=no_mass_E${E}_v4.0
# check if env var PISM_DO was set (i.e. PISM_DO=echo for a 'dry' run)
if [ -n "${PISM_DO:+1}" ] ; then  
  echo "$SCRIPTNAME         PISM_DO = $PISM_DO  (already set)"
else
  PISM_DO="" 
fi

BOOT=pism_greenland_1km_v3-filled.nc
PISM_ONESTATION=pism_one_station_tas_cold_noleap-with-bounds.nc
FIRN_DEPTH=firn_depth.nc
#PDD_STD=air_temp_sd_file_cold.nc

EXDT=50
BCFILE=g5km_bc.nc

regridcommand="-regrid_file $BCFILE -regrid_vars basal_melt_rate_grounded,tillwat,enthalpy,litho_temp"


# Set model options
EXVARS='thk,velsurf_mag,diffusivity,bmelt'


CLIMATE="-atmosphere one_station,elevation_change \
		     -atmosphere.one_station.file $PISM_ONESTATION \
		     -atmosphere.elevation_change.file $BOOT \
		     -atmosphere.elevation_change.temperature_lapse_rate $dT \
		     -atmosphere.elevation_change.precip_adjustment shift \
		     -atmosphere.elevation_change.precipitation.lapse_rate $dPdz \
		     -surface pdd \
		     -surface.pdd.std_dev.value ${temp_sd} \
		     -sea_level constant "

PHYS="-no_mass -pik -sia_e ${E} -stress_balance ssa+sia -topg_to_phi 15.0,40.0,-300.0,700.0 -till_effective_fraction_overburden 0.02 -pseudo_plastic -pseudo_plastic_q 0.25 -tauc_slippery_grounding_lines"
# -calving float_kill -float_kill_margin_only -calving.float_kill.calve_near_grounding_line false
RUNSTART=1778
RUNEND=1896


NN=24
firstnode=0
lastnode=24

xmin=80793.
ymin=-2650282.
xmax=388422.
ymax=-2226046.


# Set paralell run options
PISM="taskset -c ${firstnode}-${lastnode} pismr -regional"

cmd="mpiexec -n $NN $PISM -bootstrap -i $BOOT \
    -x_range $xmin,$xmax \
    -y_range $ymin,$ymax \ 
    -Lz 4000 -Lbz 1000 -Mz 201 -Mbz 51 \
    -stress_balance.sia.max_diffusivity 500000 \
    -no_model_strip 10 \   
    $regridcommand \
    $PHYS \
    -regional.zero_gradient true \
    -extra_file ex_${OUTFILENAME}.nc -extra_times $RUNSTART:$EXDT:$RUNEND \
    -extra_vars $EXVARS \
    -ts_file ts_${OUTFILENAME}.nc -ts_times $RUNSTART:yearly:$RUNEND \
    $CLIMATE -ys $RUNSTART -ye $RUNEND -o ${OUTFILENAME}.nc"
$PISM_DO $cmd
