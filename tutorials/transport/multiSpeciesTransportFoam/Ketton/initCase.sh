#!/bin/bash

###### USERS INPUT ############################################################

#Define image name
Image_name="Ketton"

# Define image dimensions
x_dim=512
y_dim=512
z_dim=512

# define resolution (m)
res=0.0000053

# define value of the pores and solid in the image 
pores_value=255
solid_value=0

# Define cropping parameters
x_min=0
x_max=300
y_min=0
y_max=300
z_min=0
z_max=300

# number of cells of initial mesh
# n*(2^nlevel) should be equal to image dimension when not binning 
n_x=75
n_y=75
n_z=75

# Level of refinement - mesh is refined by n_level at the pore surfaces
n_level=1

# flow direction (0 is x, 1 is y and 2 is z)
direction=0

# Number of processors
NP=8

#### END OF USER INPUT #######################################################

source $OF4X_DIR/OpenFOAM-4.x/etc/bashrc 

MPIRUN=mpirun 

echo -e "make stl"
cd constant/triSurface
cp -r $GCFOAM_IMG/raw/$Image_name\.raw.tar.gz .
tar -xf $Image_name\.raw.tar.gz
python raw2stl.py --x_min=$x_min --x_max=$x_max --y_min=$y_min --y_max=$y_max --z_min=$z_min --z_max=$z_max --pores_value=$pores_value --solid_value=$solid_value  --image_name=$Image_name --x_dim=$x_dim --y_dim=$y_dim --z_dim=$z_dim
rm $Image_name\.*
cd ../..
# ./runSmooth.sh

surfaceTransformPoints -translate '(-0.5 -0.5 -0.5)' constant/triSurface/Image_meshed.stl constant/triSurface/Image_meshed.stl > surfaceTransformPoints.out
export pore_index_0="$(cat constant/triSurface/pore_indx)"
export pore_index_1="$(cat constant/triSurface/pore_indy)"
export pore_index_2="$(cat constant/triSurface/pore_indz)"
 
echo -e "Coordinates at center of a pore = ($pore_index_0,$pore_index_1,$pore_index_2)" 
 
# Create background mesh
echo -e "Create background mesh"
cp system/blockMeshDict$direction system/blockMeshDict
dx=0
let dx+=$x_max
let dx-=$x_min
dy=0
let dy+=$y_max
let dy-=$y_min
dz=0
let dz+=$z_max
let dz-=$z_min

sed -i "s/dx/$dx/g" system/blockMeshDict
sed -i "s/dy/$dy/g" system/blockMeshDict
sed -i "s/dz/$dz/g" system/blockMeshDict

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
cp system/snappyHexMeshDict1 system/snappyHexMeshDict

sed -i "s/nlevel/$n_level/g" system/snappyHexMeshDict

sed -i "s/poreIndex0/$pore_index_0/g" system/snappyHexMeshDict
sed -i "s/poreIndex1/$pore_index_1/g" system/snappyHexMeshDict
sed -i "s/poreIndex2/$pore_index_2/g" system/snappyHexMeshDict


x_2=$(expr $dx*$res | bc)
y_2=$(expr $dy*$res | bc)
z_2=$(expr $dz*$res | bc)

x_1=$res
y_1=$res
z_1=$res

cp system/postProcessDict1 system/postProcessDict
sed -i "s/x_1/$x_1/g" system/postProcessDict
sed -i "s/y_1/$y_1/g" system/postProcessDict
sed -i "s/z_1/$z_1/g" system/postProcessDict

sed -i "s/x_2/$x_2/g" system/postProcessDict
sed -i "s/y_2/$y_2/g" system/postProcessDict
sed -i "s/z_2/$z_2/g" system/postProcessDict

sed -i "s/flowdir/$direction/g" system/postProcessDict


$MPIRUN -np $NP snappyHexMesh -overwrite -parallel  > snappyHexMesh.out

echo -e "reconstruct parallel mesh"
reconstructParMesh -constant > reconstructParMesh.out

echo -e "transformPoints" 
vector="($res $res $res)"
transformPoints -scale "$vector" > transformPoints.out

rm -rf processor*

echo -e "Image Initialised. It is advised to check in paraview to confirm mesh of porespace is reasonable before running flow" 
