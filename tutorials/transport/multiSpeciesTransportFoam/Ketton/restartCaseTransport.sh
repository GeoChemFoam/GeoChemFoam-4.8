#!/bin/bash

###### USERS INPUT ############################################################

## Define the total time of the simulation and how often to output concentration field

TotalTime=0.01
runTimestep=1e-4
WriteTimestep=10

## Number of processor
NP=8

#### END OF USER INPUT #######################################################

cp system/controlDictTransport system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict
sed -i "s/WriteTimestep/$WriteTimestep/g" system/controlDict
sed -i "s/runTimestep/$runTimestep/g" system/controlDict



MPIRUN=mpirun 

#rm -rf *.out

cp system/decomposeParDict1 system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

# Decompose
echo -e "DecomposePar"
decomposePar > decomposeParTransport.out

# Run multiSpeciesTransportFoam in parallel
echo -e "Run multiSpeciesTransportFoam in parallel"
$MPIRUN -np $NP multiSpeciesTransportFoam -parallel  > multiSpeciesTransport.out

# ReconstructPar
echo -e "reconstructPar"
reconstructPar > reconstructParTransport.out

rm -rf processor*

echo "process concentration"
processConcentration > processConcentrationTransport.out
