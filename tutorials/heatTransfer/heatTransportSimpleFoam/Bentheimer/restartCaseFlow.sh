#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation
TotalTime=2000

#Number of processors
NP=8

#### END OF USER INPUT #######################################################

cp system/controlDict1 system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict

MPIRUN=mpirun 

cp system/decomposeParDict1 system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

# Decompose
echo -e "DecomposePar"
decomposePar > decomposeParFlow.out

# Run simpleFoam in parallel
echo -e "Run simpleFoam in parallel"
$MPIRUN -np $NP simpleDBSFoam -parallel  > simpleFoamDBSFlow.out

echo -e "reconstructPar"
reconstructPar -latestTime > reconstructParFlow.out

rm -rf 0
mv -f [1-9]* 0
rm -rf processor*
echo -e "processPoroPerm"
processPoroPerm > poroPermFlow.out

echo -e "Note: Please check the last line of simpleDBSFoamFlow.out to confirm the flow field has converged. If it has not, use restartCaseFlow.sh to restart the case and/or change the p tolerance and residual controls in system/fvSolution" 






