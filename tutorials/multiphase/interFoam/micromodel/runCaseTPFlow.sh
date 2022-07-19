#!/bin/bash

###### USERS INPUT ############################################################

## Define the total number of iterations of the simulation and how often to output
TotalTime=0.1
WriteTimestep=0.01
runTimestep=2e-5

#Define flow rate
flowrate=3.5e-8

#fluid viscosities (m2/s) 
#Phase 1 is resident phase, phase 2 is injected phase
Visc1=1e-06
Visc2=1.65e-5

#fluid densities (kg/m3)
rho1=1000
rho2=864

#interfacial tension (N/m)
ift=0.03

#contact angle (degree)
theta=45

#number of processores
NP=8

#### END OF USER INPUT #######################################################

nsatpoints=$(expr $TotalTime/$WriteTimestep | bc)

cp constant/transportPropertiesTP constant/transportProperties
cp system/fvSolutionTP system/fvSolution
cp system/fvSchemesTP system/fvSchemes
cp system/controlDictTP system/controlDict
cp system/postProcessDictRun system/postProcessDict
sed -i "s/Visc1/$Visc1/g" constant/transportProperties
sed -i "s/Visc2/$Visc2/g" constant/transportProperties
sed -i "s/rho1/$rho1/g" constant/transportProperties
sed -i "s/rho2/$rho2/g" constant/transportProperties
sed -i "s/ift/$ift/g" constant/transportProperties
sed -i "s/TotalTime/$TotalTime/g" system/controlDict
sed -i "s/WriteTimestep/$WriteTimestep/g" system/controlDict
sed -i "s/runTimestep/$runTimestep/g" system/controlDict
sed -i "s/nsatpoints/$nsatpoints/g" system/postProcessDict

rm -rf 0 [1-9]*

cp -r 0_org 0

sed -i "s/contactAngle/$theta/g" 0/alpha1
sed -i "s/flowrate/$flowrate/g" 0/U

echo -e "set alpha field"
setFields > setFieldsTP.out

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
