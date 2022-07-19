#!/bin/bash

###### USERS INPUT ############################################################

#Define image name
Image_name="Grainstones"

# Define image dimensions
x_dim=1000
y_dim=500
z_dim=1

# Define cropping parameters
x_min=0
x_max=1e-3
y_min=0
y_max=5e-4
z_min=-5e-6
z_max=5e-6

# number of cells of initial mesh
# n*(nlevel+1) should be equal to image dimension when not binning 
n_x=1000
n_y=500
#In 2D images, z has to be the empty direction
n_z=1

# flow direction 0 or 1, 2 is empty
direction=0

#Enter pore index manually
pore_index_0=0.0001522
pore_index_1=0.0001522
pore_index_2=0


# Number of processors
NP=24

#### END OF USER INPUT #######################################################

# Load user environment variables 
source ~/.bashrc

source $HOME/works/GeoChemFoam-4.7/etc/bashrc

source $OF4X_DIR/OpenFOAM-4.x/etc/bashrc WM_LABEL_SIZE=64 FOAMY_HEX_MESH=yes

MPIRUN=mpirun 

cp constant/triSurface/$Image_name.stl constant/triSurface/Image_meshed.stl

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

cp system/decomposeParDict1 system/decomposeParDict
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

echo -e "Image Initialised. It is advised to check in paraview to confirm mesh of porespace is reasonable before running flow" 
