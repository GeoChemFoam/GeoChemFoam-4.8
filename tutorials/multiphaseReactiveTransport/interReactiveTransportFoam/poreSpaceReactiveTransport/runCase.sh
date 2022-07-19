#!/bin/bash

set -e

# Inlet velocity
Ux=0.01
Uy=0
Uz=0

## Define the total time of the simulation and how often to output the flowfield
TotalTime=0.01
WriteTimeStep=5e-4

#Number of processore
NP=24

cp -r 0_org 0

sed -i "s/Ux/$Ux/g" 0/U
sed -i "s/Uy/$Uy/g" 0/U
sed -i "s/Uz/$Uz/g" 0/U

cp system/controlDictRun system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict
sed -i "s/WriteTimeStep/$WriteTimeStep/g" system/controlDict

cp system/decomposeParDictRun system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

echo -e "Decompose parallel mesh"
decomposePar > decomposePar.out

echo -e "Run interReactiveTranportFoam"
mpiexec -np 24 interReactiveTransportFoam -parallel > interReactiveTransportFoam.out

echo -e "reconstruct parallel mesh"
reconstructPar > reconstructPar.out

rm -rf processor*
