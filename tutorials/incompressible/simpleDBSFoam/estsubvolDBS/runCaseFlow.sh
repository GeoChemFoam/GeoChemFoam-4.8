#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation
TotalTime=2000

## Define your pressure drop at the inlet (Pa)
PGRAD=1000

## Define the kinematic viscocity of the fluid (m^2/s)
##(e.g for water this is 1e-6, for air this would be 1.478e-5)
Visc=1e-6

## Number of processor
NP=8

#### END OF USER INPUT #######################################################

MPIRUN=mpirun

cp constant/transportPropertiesRun constant/transportProperties
sed -i "s/Visc/$Visc/g" constant/transportProperties
sed -i "s/PGRAD/$PGRAD/g" constant/transportProperties

cp system/controlDict1 system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict

cp system/decomposeParDict1 system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

# Decompose
echo -e "DecomposePar"
decomposePar > decomposeParFlow.out

# Run simpleFoam in parallel
echo -e "Run simpleDBSFoam in parallel"
$MPIRUN -np $NP simpleDBSFoam -parallel  > simpleDBSFoamFlow.out

# ReconstructPar
echo -e "reconstructPar"
reconstructPar -latestTime > reconstructParFlow.out

rm -rf 0
mv -f [1-9]* 0
rm -rf processor*
echo -e "processPoroPerm"
processPoroPerm > poroPermFlow.out

echo -e "Note: Please check the last line of simpleDBSFoamFlow.out to confirm the flow field has converged. If it has not, use restartCaseFlow.sh to restart the case and/or change the p tolerance and residual controls in system/fvSolution" 
