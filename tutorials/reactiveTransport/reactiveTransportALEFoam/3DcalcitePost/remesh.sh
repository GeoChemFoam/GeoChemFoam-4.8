#!/bin/bash

# Load user environment variables
source $HOME/.bashrc

#export $GCFOAM_DIR/lib

MPIRUN=mpirun

cd ../temp

./removeInternalFaces.sh

surfaceMeshTriangulate -patches '(movingWalls)' constant/triSurface/Image_meshed.stl > surfaceMeshTriangulate.out
cp constant/triSurface/Image_meshed.stl ../3DcalcitePost/constant/triSurface/Image_meshed.stl

source $OF4X_DIR/OpenFOAM-4.x/etc/bashrc 


rm -rf 0 0.* [1-9]*

./deleteAll.sh

# Create background mesh
echo -e "Create background mesh"
blockMesh  > blockMesh.out

# Decompose background mesh
echo -e "Decompose background mesh"
decomposePar > decomposeBlockMesh.out

export NP="$(find processor* -maxdepth 0 -type d -print| wc -l)"

# Remove fields on this stage
rm -rf ./processor*/0/*

# Run snappyHexMesh in parallel
echo -e "Run snappyHexMesh in parallel"
$MPIRUN -np $NP snappyHexMesh -overwrite -parallel  > snappyHexMesh.out

# reconstruct mesh to fields decomposition
echo -e "reconstruct parallel mesh"
reconstructParMesh -constant > reconstructParMesh.out


echo -e "checkMesh"
$MPIRUN -np $NP checkMesh -parallel > checkMesh.out


rm -rf *.out processor*

cp -r 0_org 0

cp -r constant/polyMesh 0/.

