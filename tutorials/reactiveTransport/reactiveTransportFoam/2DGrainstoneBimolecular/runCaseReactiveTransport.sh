#!/bin/bash

###### USERS INPUT ############################################################

## Define the total time of the simulation and how often to output concentration fields
TotalTime=4
WriteTimestep=0.5
runTimestep=0.01

## Define the diffusion coefficient of the species as a solute (m^2/s)
DiffAB=1e-9
DiffA=1e-9
DiffB=1e-9

## Number of processor
NP=24

#### END OF USER INPUT #######################################################

cp system/controlDictReactiveTransport system/controlDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict
sed -i "s/WriteTimestep/$WriteTimestep/g" system/controlDict
sed -i "s/runTimestep/$runTimestep/g" system/controlDict
cp constant/thermoPhysicalProperties1 constant/thermoPhysicalProperties
sed -i "s/DiffAB/$DiffAB/g" constant/thermoPhysicalProperties
sed -i "s/DiffA/$DiffA/g" constant/thermoPhysicalProperties
sed -i "s/DiffB/$DiffB/g" constant/thermoPhysicalProperties
# Load user environment variables 
source ~/.bashrc

source $HOME/works/GeoChemFoam-4.7/etc/bashrc

set -e

MPIRUN=mpirun 

#rm -rf *.out

cp 0_orig/A 0/.
cp 0_orig/B 0/.
cp 0_orig/AB 0/.
rm -rf 0/uniform

cp system/decomposeParDict1 system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

# Decompose
echo -e "DecomposePar"
decomposePar > decomposeParRT.out

# Run reactiveTransportFoam in parallel
echo -e "Run reactiveTransportFoam in parallel"
$MPIRUN -np $NP reactiveTransportFoam -parallel  > reactiveTransportFoamRT.out

# ReconstructPar
echo -e "reconstructPar"
reconstructPar > reconstructParRT.out

rm -rf processor*

echo "process concentration"
processConcentration > processConcentrationRT.out
