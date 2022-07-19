#!/bin/bash

###### USERS INPUT ############################################################

#Define image name
Image_name="calcitePost"

# Define image dimensions
x_min=-1.0835e-3
x_max=1.5835e-3
y_min=-0.498e-3
y_max=0.998e-3
z_min=-0.1e-3
z_max=0.1e-3

# number of cells of initial mesh
n_x=134
n_y=75
n_z=10

#Mesh refinement level
nlevel=1

# flow direction 0 or 1, 2 is empty
direction=0

#Enter pore index manually
pore_index_0=-50e-5
pore_index_1=0
pore_index_2=0

# Number of processors
NP=24

#### END OF USER INPUT #######################################################

# Load user environment variables 
source ~/.bashrc

source $OF4X_DIR/OpenFOAM-4.x/etc/bashrc 

MPIRUN=mpirun 
#Insert dimensions in postProcessDict
cp system/postProcessDict1 system/postProcessDict
sed -i "s/x_1/$x_min/g" system/postProcessDict
sed -i "s/y_1/$y_min/g" system/postProcessDict
sed -i "s/z_1/$z_min/g" system/postProcessDict

sed -i "s/x_2/$x_max/g" system/postProcessDict
sed -i "s/y_2/$y_max/g" system/postProcessDict
sed -i "s/z_2/$z_max/g" system/postProcessDict

sed -i "s/flowdir/$direction/g" system/postProcessDict

# Create background mesh
echo -e "Create background mesh"
cp system/blockMeshDict$direction system/blockMeshDict
sed -i "s/x_min/$x_min/g" system/blockMeshDict
sed -i "s/y_min/$y_min/g" system/blockMeshDict
sed -i "s/z_min/$z_min/g" system/blockMeshDict

sed -i "s/x_max/$x_max/g" system/blockMeshDict
sed -i "s/y_max/$y_max/g" system/blockMeshDict
sed -i "s/z_max/$z_max/g" system/blockMeshDict

sed -i "s/nx/$n_x/g" system/blockMeshDict
sed -i "s/ny/$n_y/g" system/blockMeshDict
sed -i "s/nz/$n_z/g" system/blockMeshDict

cp system/controlDictInit system/controlDict

blockMesh  > blockMesh.out

cp system/decomposeParDict1 system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict


# Decompose background mesh
echo -e "Decompose background mesh"
decomposePar > decomposeBlockMesh.out
rm -rf processor*/0/*

# Run snappyHexMesh in parallel
echo -e "Run snappyHexMesh in parallel"

cp constant/triSurface/$Image_name.stl constant/triSurface/Image_meshed.stl

cp system/snappyHexMeshDict1 system/snappyHexMeshDict
sed -i "s/nlev/$nlevel/g" system/snappyHexMeshDict
sed -i "s/poreIndex0/$pore_index_0/g" system/snappyHexMeshDict
sed -i "s/poreIndex1/$pore_index_1/g" system/snappyHexMeshDict
sed -i "s/poreIndex2/$pore_index_2/g" system/snappyHexMeshDict


$MPIRUN -np $NP snappyHexMesh -overwrite -parallel  > snappyHexMesh.out

echo -e "reconstruct parallel mesh"
reconstructParMesh -constant > reconstructParMesh.out

echo -e "checkMesh"
$MPIRUN -np $NP checkMesh -parallel > checkMesh.out


rm -rf processor*

echo -e "Image Initialised. It is advised to check in paraview to confirm mesh of porespace is reasonable before initialising fields by running runCase0" 
