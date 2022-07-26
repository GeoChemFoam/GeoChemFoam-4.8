#!/bin/bash

###### USERS INPUT ############################################################

TotalTime=1600
WriteTimestep=800
initTimestep=1
maxTimestep=50

#### END OF USER INPUT #######################################################

export NP="$(find processor* -maxdepth 0 -type d -print| wc -l)"

cp system/controlDictRun system/controlDict
cp system/fvSolutionRun system/fvSolution

sed -i "s/TotalTime/$TotalTime/g" system/controlDict
sed -i "s/WriteTimestep/$WriteTimestep/g" system/controlDict
sed -i "s/initTimestep/$initTimestep/g" system/controlDict
sed -i "s/maxTimestep/$maxTimestep/g" system/controlDict


echo -e "run reactiveTransportDBSFoam"
mpiexec -np $NP reactiveTransportDBSFoam -parallel > reactiveTransportDBSFoamRT.out

echo -e "reconstruct parallel mesh"
if grep -q "dynamicRefineFvMesh" constant/dynamicMeshDict; then
    reconstructParMesh  > reconstructParMeshRT.out
else
    reconstructPar  > reconstructParMeshRT.out
fi

echo -e "process solid area"
processSolidArea > processSolidAreaRT.out
