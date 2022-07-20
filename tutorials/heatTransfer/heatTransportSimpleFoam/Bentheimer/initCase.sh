#!/bin/bash

###### USERS INPUT ############################################################

#Define image name
Image_name="Bentheimer400-5mum"

# Define image dimensions
x_dim=400
y_dim=400
z_dim=400

# define resolution (m)
res=0.000005

#padding for inlet/outlet
padWidth=4

#Values of solid, pore, and minimum porosity value for the solid phase (note: this CANNOT be 0) 
pores_value=0
solid_value=255
eps_min=0.0001

# Define cropping parameters
x_min=0
x_max=200
y_min=0
y_max=200
z_min=0
z_max=200

# number of cells of initial mesh
n_x=50
n_y=50
n_z=50

#Mesh refinement level
nlevel=1
refineStokes=0

#Smoothing parameters: smooth surface when image has artifical roughness created ny segmentation to avoid error when using adaptive mesh
nSmooth=1
cSmooth=0.1

# flow direction 0 or 1, 2 is empty
direction=0

# Number of processors
NP=8

#### END OF USER INPUT #######################################################

#Insert dimensions in postProcessDict
x_1=0
y_1=0
z_1=0

xSize=$(echo "$x_max - $x_min" | bc)
ySize=$(echo "$y_max - $y_min" | bc)
zSize=$(echo "$z_max - $z_min" | bc)

x_2=$(expr $xSize*$res | bc)
y_2=$(expr $ySize*$res | bc)
z_2=$(expr $zSize*$res | bc)


cp system/postProcessDict1 system/postProcessDict
sed -i "s/x_1/$x_1/g" system/postProcessDict
sed -i "s/y_1/$y_1/g" system/postProcessDict
sed -i "s/z_1/$z_1/g" system/postProcessDict

sed -i "s/x_2/$x_2/g" system/postProcessDict
sed -i "s/y_2/$y_2/g" system/postProcessDict
sed -i "s/z_2/$z_2/g" system/postProcessDict

sed -i "s/flowdir/$direction/g" system/postProcessDict

mkdir constant/polyMesh
cp system/blockMeshDict$direction constant/polyMesh/blockMeshDict

mkdir constant/triSurface
cd constant/triSurface
cp $GCFOAM_IMG/raw/$Image_name\.raw.tar.gz .
tar -xf $Image_name.raw.tar.gz
cd ../..

#Dummy fluid properties
flowRate=1e-30

cp -r 0_orig 0

sed -i "s/flow_rate/$flowRate/g" 0/U

cp system/fvSolution1 system/fvSolution
sed -i "s/nSmooth/1/g" system/fvSolution
sed -i "s/cSmooth/0.5/g" system/fvSolution

python createblockmesh.py --xDim $x_dim --yDim $y_dim --zDim $z_dim --xMin $x_min --xMax $x_max --yMin $y_min --yMax $y_max --zMin $z_min --zMax $z_max --nX $n_x --nY $n_y --nZ $n_z --nLevel $nlevel --refineStokes $refineStokes --res $res --Image_name $Image_name --padWidth $padWidth --pores_value $pores_value --solid_value $solid_value --eps_min $eps_min --direction $direction --NP $NP

rm constant/triSurface/$Image_name.raw

cp system/fvSolution1 system/fvSolution
sed -i "s/nSmooth/$nSmooth/g" system/fvSolution
sed -i "s/cSmooth/$cSmooth/g" system/fvSolution

smoothSolidSurface > smoothSolidSurface.out

echo -e "Case initialised. It is advised to check in paraview to confirm mesh and 0/eps are reasonable before running flow"






