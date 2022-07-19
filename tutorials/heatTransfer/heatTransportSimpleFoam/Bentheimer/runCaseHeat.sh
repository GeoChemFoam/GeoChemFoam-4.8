#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation
TotalTime=2000

#fluid properties
Diff_f=4.47e-8
Diff_s=3.76e-6

#Number of processors
NP=8

#### END OF USER INPUT #######################################################

cp system/controlDict1 system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict

echo -e "set flow and transport properties"
cp constant/transportProperties2 constant/transportProperties
sed -i "s/Diff_s/$Diff_s/g" constant/transportProperties
sed -i "s/Diff_f/$Diff_f/g" constant/transportProperties

MPIRUN=mpirun 

cp 0_orig/T 0/.

cp system/decomposeParDict1 system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

# Decompose
echo -e "DecomposePar"
decomposePar > decomposePar.out

echo -e "Run heatTransportSimpleFoam in parallel"
$MPIRUN -np $NP heatTransportSimpleFoam -parallel  > heatTransportSimpleFoam.out 

echo -e "reconstructPar"
reconstructPar -latestTime > reconstructPar.out

cp [1-9]*/T 0/.

rm -rf [1-9]*

rm -rf processor*

echo -e "processHeatTransfer"
processHeatTransfer > processHeatTransfer.out




