#!/bin/bash

###### USERS INPUT ############################################################


#### END OF USER INPUT #######################################################

export NP="$(find processor* -maxdepth 0 -type d -print| wc -l)"

echo -e "run reactiveTransportDBSFoam for 1e-06 sec"
mpiexec -np $NP reactiveTransportDBSFoam -parallel > reactiveTransportDBSFoam0.out

echo -e "reconstruct parallel mesh"
if grep -q "dynamicRefineFvMesh" constant/dynamicMeshDict; then
    reconstructParMesh -latestTime > reconstructParMesh0.out
else
    reconstructPar -latestTime > reconstructParMesh0.out
fi

echo -e "move 1e-06 to 0"
for i in processor*; do cp "$i/1e-06/U" "$i/0/."; done
for i in processor*; do cp "$i/1e-06/p" "$i/0/."; done
for i in processor*; do cp "$i/1e-06/phi" "$i/0/."; done
for i in processor*; do cp "$i/1e-06/C" "$i/0/."; done
for i in processor*; do cp "$i/1e-06/R" "$i/0/."; done
rm -rf processor*/1e-06

cp -f 1e-06/C 0/.
cp -f 1e-06/U 0/.
cp -f 1e-06/p 0/.
cp -f 1e-06/phi 0/.
cp -f 1e-06/R 0/.
rm -rf 1e-06

