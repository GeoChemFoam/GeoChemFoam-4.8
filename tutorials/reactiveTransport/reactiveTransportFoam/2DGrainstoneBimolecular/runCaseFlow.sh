#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation
TotalTime=2000

## Define inlet veclocity (m/s)
Ux=0.0001
Uy=0
Uz=0

## Define the kinematic viscocity of the fluid (m^2/s)
##(e.g for water this is 1e-6, for air this would be 1.478e-5)
Visc=1e-06

## Number of processor
NP=24

#### END OF USER INPUT #######################################################

cp system/controlDictFlow system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict

cp constant/transportProperties1 constant/transportProperties
sed -i "s/Visc/$Visc/g" constant/transportProperties

# Load user environment variables 
source ~/.bashrc

source $HOME/works/GeoChemFoam-4.7/etc/bashrc

set -e

MPIRUN=mpirun 

cp -r 0_orig 0
sed -i "s/Ux/$Ux/g" 0/U
sed -i "s/Uy/$Uy/g" 0/U
sed -i "s/Uz/$Uz/g" 0/U

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
mv [1-9]* 0
rm -rf processor*
echo -e "processPoroPerm"
processPoroPerm > poroPermFlow.out

echo -e "It is advised to check the simpleFoamFlow.out file to confirm flow has converged before using the permeability output or running transport. If flow has converged the file will say 'SIMPLE solution converged in X iterations'. If flow has not converged, increase endtime."

