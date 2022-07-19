#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation
TotalTime=2000

## Number of processor
NP=8

#### END OF USER INPUT

cp system/fvSolutionSP system/fvSolution
cp system/fvSchemesSP system/fvSchemes
cp system/controlDictSP system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict

MPIRUN=mpirun 

cp system/decomposeParDictRun system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

# Decompose
echo -e "DecomposePar"
decomposePar > decomposeParSP.out

# Run simpleFoam in parallel
echo -e "Run simpleFoam in parallel"
$MPIRUN -np $NP simpleFoam -parallel  > simpleFoamSP.out

# ReconstructPar
echo -e "reconstructPar"
reconstructPar -latestTime > reconstructParSP.out

rm -rf 0
mv -f [1-9]* 0
rm -rf processor*
echo -e "processPoroPerm"
processPoroPerm > poroPermSP.out

