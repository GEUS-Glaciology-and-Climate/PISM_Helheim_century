#!/bin/bash
NN=8
export PARAM_PPQ=0.5
export REGRIDFILE=g20km_10ka_hy.nc
export EXSTEP=100
./spinup_maxdiff.sh $NN const 6000 10 hybrid g10km_gridseq_maxdiff.nc 
export REGRIDFILE=g10km_gridseq_maxdiff.nc
export EXSTEP=10
./spinup_maxdiff.sh $NN const 1000 5 hybrid g5km_gridseq_maxdiff.nc
