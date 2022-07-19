#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation
TotalTime=2000

# Define flow rate
flowrate=3.5e-8

## Define the kinematic viscocity of the fluid (m^2/s)
##(e.g for water this is 1e-6, for air this would be 1.5e-5)
Visc=1e-06

## Number of processor
NP=8

#### END OF USER INPUT

cp constant/transportPropertiesSP constant/transportProperties
cp system/fvSolutionSP system/fvSolution
cp system/fvSchemesSP system/fvSchemes
cp system/controlDictSP system/controlDict
cp system/postProcessDictRun system/postProcessDict
sed -i "s/Visc/$Visc/g" constant/transportProperties
sed -i "s/TotalTime/$TotalTime/g" system/controlDict

MPIRUN=mpirun 

cp -r 0_org_SP 0

sed -i "s/flowrate/$flowrate/g" 0/U

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

echo -e "Note: Please check the last line of simpleFoamSP.out to confirm the flow field has converged. If it has not, use restartCaseSPFlow.sh to restart the case and/or change the p tolerance and residual controls in system/fvSolution" 

