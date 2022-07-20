#!/bin/bash

###### USERS INPUT ############################################################

#Define flow rate
flowRate=3.5e-10

#fluid properties
Visc=2.61e-6
Diff=5e-9

#Reaction constants
kreac=8.9125e-4 
scoeff=2
rhos=2710
Mws=100
cinlet=0.0126


#Kozeny-Carman constant
kf=1e12 

#### END OF USER INPUT #######################################################

export NP="$(find processor* -maxdepth 0 -type d -print| wc -l)"

cp constant/dynamicMeshDict0 constant/dynamicMeshDict
cp system/controlDict0 system/controlDict
cp system/fvSolution0 system/fvSolution

echo -e "set flow and transport properties"
cp constant/transportProperties0 constant/transportProperties
sed -i "s/Visc/$Visc/g" constant/transportProperties
sed -i "s/rho_s/$rhos/g" constant/transportProperties
sed -i "s/Mw_s/$Mws/g" constant/transportProperties
sed -i "s/k_f/$kf/g" constant/transportProperties

cp constant/thermoPhysicalProperties0 constant/thermoPhysicalProperties
sed -i "s/Diff/$Diff/g" constant/thermoPhysicalProperties
sed -i "s/s_coeff/$scoeff/g" constant/thermoPhysicalProperties
sed -i "s/k_reac/$kreac/g" constant/thermoPhysicalProperties

cp 0_orig/U 0/.
cp 0_orig/C 0/.
cp 0_orig/p 0/.

sed -i "s/flow_rate/$flowRate/g" 0/U
sed -i "s/c_inlet/$cinlet/g" 0/C

echo "decompose parallel mesh"

decomposePar -fields > decomposeParFields0.out

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

echo -e "Note: Please check the last line of reactiveTransportDBSFoam0.out to confirm the equation have converged. If it has not, use restartCase0.sh to restart the case and/or change the tolerance and residual controls in system/fvSolution" 


