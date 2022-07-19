#!/bin/bash

###### USERS INPUT ############################################################

#Name of your image (image must be in raw format 8 bit)
Image_name="Est_3phase500cubed4micron"

# Define image dimensions
x_dim=500
y_dim=500
z_dim=500

# define resolution (m)
res=0.000004

#Values of solid, pore, and minimum porosity value for the solid phase (note: this CANNOT be 0) 
pores_value=1
solid_value=3

#define the labels of the phases
phases=(1 2 3)

#define the porosity of each phase, note that the porosity of the solid phase CANNOT be 0, default to 0.0001
micro_por=('1' '0.35' '0.0001')
#micro_por=('1' '0.37' '0.35' '0.32' '0.0001')

#define the permeability of each label (note: solid phase should be < 1e-20, pore should be > 1e13)
micro_k=('1e13' '1.82e-15' '1e-20')
#micro_k=('1e13' '2.47e-15' '1.82e-15' '1.46e-15' '1e-20')

# Define cropping parameters
x_min=150
x_max=300
y_min=150
y_max=300
z_min=150
z_max=300

#padding for inlet/outlet (minimum 2)
padWidth=4

# number of cells of initial mesh
n_x=75
n_y=75
n_z=75

#Mesh refinement level
nlevel=1
#0=no refinment in pores, 1=refinemnet in pores
refineStokes=1

#Choose the direction of flow, 0 is x, 1 is y, 2 is z
direction=0


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
cp constant/transportProperties$direction constant/transportPropertiesRun

cp system/controlDict1 system/controlDict
sed -i "s/TotalTime/1/g" system/controlDict

mkdir constant/triSurface
cd constant/triSurface
cp $GCFOAM_IMG/raw/$Image_name\.raw.tar.gz .
tar -xf $Image_name\.raw.tar.gz
cd ../..

cp -r 0_orig 0
python createblockmesh.py --xDim $x_dim --yDim $y_dim --zDim $z_dim --xMin $x_min --xMax $x_max --yMin $y_min --yMax $y_max --zMin $z_min --zMax $z_max --nX $n_x --nY $n_y --nZ $n_z --nLevel $nlevel --refineStokes $refineStokes --res $res --Image_name $Image_name --padWidth $padWidth --pores_value $pores_value --solid_value $solid_value --direction $direction --micro_por ${micro_por[@]} --micro_k ${micro_k[@]} --phases ${phases[@]}



rm -rf constant/triSurface

echo -e "Image Initialised. It is advised to check in paraview to confirm mesh and 0/eps are reasonable before running flow"

