#!/bin/bash
NN=8
export PARAM_PPQ=0.5
export REGRIDFILE=g5km_gridseq_maxdiff.nc
export EXSTEP=10
./spinup_maxdiff.sh $NN const 2000 5 hybrid g5km_gridseq_maxdiff_3ka.nc
