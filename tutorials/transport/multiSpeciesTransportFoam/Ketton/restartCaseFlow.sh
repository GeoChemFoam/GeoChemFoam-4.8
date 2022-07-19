#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation
TotalTime=2000

## Number of processor
NP=8

#### END OF USER INPUT #######################################################

cp system/controlDictFlow system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict

MPIRUN=mpirun 

cp system/decomposeParDict1 system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

# Decompose
echo -e "DecomposePar"
decomposePar > decomposeParFlow.out

# Run simpleFoam in parallel
echo -e "Run simpleFoam in parallel"
$MPIRUN -np $NP simpleFoam -parallel  > simpleFoamFlow.out

# ReconstructPar
echo -e "reconstructPar"
reconstructPar -latestTime > reconstructParFlow.out

rm -rf 0
mv -f [1-9]* 0
rm -rf processor*
echo -e "processPoroPerm"
processPoroPerm > poroPermFlow.out

echo -e "It is advised to check the simpleFoamFlow.out file to confirm flow has converged before using the permeability output or running transport. If flow has converged the file will say 'SIMPLE solution converged in X iterations'. If flow has not converged, increase TotalTime."

