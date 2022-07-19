#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation and how often to output
TotalTime=0.3
WriteTimestep=0.01
runTimestep=2e-5

#number of processores
NP=8

#### END OF USER INPUT #######################################################

nsatpoints=$(expr $TotalTime/$WriteTimestep | bc)

cp system/controlDictTP system/controlDict
cp system/postProcessDictRun system/postProcessDict
sed -i "s/TotalTime/$TotalTime/g" system/controlDict
sed -i "s/WriteTimestep/$WriteTimestep/g" system/controlDict
sed -i "s/runTimestep/$runTimestep/g" system/controlDict
sed -i "s/nsatpoints/$nsatpoints/g" system/postProcessDict

echo -e "Decompose parallel mesh"
cp system/decomposeParDictRun system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict

decomposePar > decomposeParTP.out

echo -e "Run interGCFoam"
mpiexec -np $NP interGCFoam  -parallel > interGCFoamTP.out
echo -e "reconstruct parallel mesh"
reconstructPar > reconstructParMeshTP.out
rm -rf proc*

echo -e "process relative permeability"
processRelPerm > processRelPermTP.out
