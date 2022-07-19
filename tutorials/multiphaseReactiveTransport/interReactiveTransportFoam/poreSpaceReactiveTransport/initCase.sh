#!/bin/bash

# Load user environment variables 
source ~/.bashrc

NP=24

source $OF4X_DIR/OpenFOAM-4.x/etc/bashrc

MPIRUN=mpirun 

# Define image dimensions
x_dim=230
y_dim=70
z_dim=1

# Define cropping parameters
x_min=-0.046
x_max=0.046
y_min=-0.014
y_max=0.014
z_min=-0.001
z_max=0.001

#resolution
res=0.01
# number of cells of initial mesh
n_x=230
n_y=70

#In 2D images, z has to be the empty direction
n_z=1

# flow direction 0 or 1, 2 is empty
direction=0

#mesh image
Image_name="pores"
cp constant/triSurface/$Image_name.stl constant/triSurface/Image_meshed.stl

#Enter pore index manually
pore_index_0=-0.041
pore_index_1=0
pore_index_2=0
# Create background mesh
echo -e "Create background mesh"
cp system/blockMeshDict2D$direction system/blockMeshDict
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

cp system/decomposeParDictRun system/decomposeParDict
sed -i "s/NP/$NP/g" system/decomposeParDict


# Decompose background mesh
echo -e "Decompose background mesh"
decomposePar > decomposeBlockMesh.out
rm -rf processor*/0/*

# Run snappyHexMesh in parallel
echo -e "Run snappyHexMesh in parallel"

cp system/snappyHexMeshDict2D system/snappyHexMeshDict

sed -i "s/poreIndex0/$pore_index_0/g" system/snappyHexMeshDict
sed -i "s/poreIndex1/$pore_index_1/g" system/snappyHexMeshDict
sed -i "s/poreIndex2/$pore_index_2/g" system/snappyHexMeshDict


$MPIRUN -np $NP snappyHexMesh -overwrite -parallel  > snappyHexMesh.out

echo -e "reconstruct parallel mesh"
reconstructParMesh -constant > reconstructParMesh.out

echo -e "checkMesh"
$MPIRUN -np $NP checkMesh -parallel > checkMesh.out


rm -rf processor*

echo -e "Scale to resolution"
transformPoints -scale "($res $res $res)" > transformPoint.out

echo -e "Image Initialised. It is advised to check in paraview to confirm mesh of porespace is reasonable before running flow" 
