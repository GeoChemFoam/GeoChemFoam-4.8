import numpy as np
import h5py
import array
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--xDim', type=int, help='xDim')
parser.add_argument('--yDim', type=int, help='yDim')
parser.add_argument('--zDim', type=int, help='zDim')
parser.add_argument('--xMin', type=int, help='xMin')
parser.add_argument('--xMax', type=int, help='xMax')
parser.add_argument('--yMin', type=int, help='yMin')
parser.add_argument('--yMax', type=int, help='yMax')
parser.add_argument('--zMin', type=int, help='zMin')
parser.add_argument('--zMax', type=int, help='zMax')
parser.add_argument('--nX', type=int, help='nX')
parser.add_argument('--nY', type=int, help='nY')
parser.add_argument('--nZ', type=int, help='nZ')
parser.add_argument('--nLevel', type=int, help='nLevel')
parser.add_argument('--refineStokes', type=int,help='refineStokes')
parser.add_argument('--nRef', type=int, help='nRef')
parser.add_argument('--res', type=float, help='resolution')
parser.add_argument('--Image_name', help='name of image')
parser.add_argument('--padWidth', type=int, help='pad Width')
parser.add_argument('--pores_value', type=int, help='value of pores')
parser.add_argument('--solid_value', type=float, help='value of solid phase')
parser.add_argument('--eps_min', type=float, help='minimum porosity')
parser.add_argument('--direction', type=int, help='flow in x y or z?')
parser.add_argument('--NP', type=int, help='NP')


opt = parser.parse_args()

xDim=opt.xDim
yDim=opt.yDim
zDim=opt.zDim

xMin=opt.xMin
xMax=opt.xMax
yMin=opt.yMin
yMax=opt.yMax
zMin=opt.zMin
zMax=opt.zMax

nX=opt.nX
nY=opt.nY
nZ=opt.nZ
nLevel=opt.nLevel
refineStokes=opt.refineStokes
nRef=opt.nRef

res=opt.res
Image_name= opt.Image_name
padWidth=opt.padWidth
pores_value=opt.pores_value
solid_value=opt.solid_value
eps_min=opt.eps_min
direction=opt.direction

NP=opt.NP

# open image
f = open('constant/triSurface/'+Image_name+'.raw', 'rb')
img = np.fromfile(f, dtype=np.uint8)
img = np.reshape(img,(zDim,yDim,xDim))
img_crop = img[zMin:zMax,yMin:yMax,xMin:xMax]
my_array = np.pad(img_crop,pad_width=padWidth,mode='constant',constant_values=pores_value)

if direction==0:

    #crop image to remove unecessary pad
    my_array = my_array[padWidth:padWidth+zMax-zMin,padWidth:padWidth+yMax-yMin,0:2*padWidth+xMax-xMin]

    #bounding box
    xmin=-padWidth
    xmax=xMax-xMin+padWidth
    ymin=0
    ymax=yMax-yMin
    zmin=0
    zmax=zMax-zMin
    
    #number of cells
    p=int((xMax-xMin)/nX)
    q=int((yMax-yMin)/nY)
    r=int((zMax-zMin)/nZ)

    nx1=int((xmax-xmin)/p)
    ny1=int((ymax-ymin)/q)
    nz1=int((zmax-zmin)/r)
    ncell = nx1*ny1*nz1


elif direction==1:

    #crop image to remove unecessary pad
    my_array = my_array[padWidth:padWidth+zMax-zMin,0:2*padWidth+yMax-yMin,padWidth:padWidth+xMax-xMin]
    
    #bounding box
    xmin=0
    xmax=xMax-xMin
    ymin=-padWidth
    ymax=yMax-yMin+padWidth
    zmin=0
    zmax=zMax-zMin
    
    #number of cells
    p=int((xMax-xMin)/nX)
    q=int((yMax-yMin)/nY)
    r=int((zMax-zMin)/nZ)

    nx1=int((xmax-xmin)/p)
    ny1=int((ymax-ymin)/q)
    nz1=int((zmax-zmin)/r)
    ncell = nx1*ny1*nz1 

else:

    #crop image to remove unecessary pad
    my_array = my_array[0:2*padWidth+zMax-zMin,padWidth:padWidth+yMax-yMin,padWidth:padWidth+xMax-xMin]
    
    #bounding box
    xmin=0
    xmax=xMax-xMin
    ymin=0
    ymax=yMax-yMin
    zmin=-padWidth
    zmax=zMax-zMin+padWidth
    
    #number of cells
    p=int((xMax-xMin)/nX)
    q=int((yMax-yMin)/nY)
    r=int((zMax-zMin)/nZ)

    nx1=int((xmax-xmin)/p)
    ny1=int((ymax-ymin)/q)
    nz1=int((zmax-zmin)/r)
    ncell = nx1*ny1*nz1 

print('create eps')
eps=np.zeros((nx1,ny1,nz1),dtype=float)
for i in range (0,nx1):
    for ii in range (0,p):
        for j in range (0,ny1):
            for jj in range (0,q):
                for k in range (0,nz1):
                    for kk in range (0,r):
                        eps[i,j,k]+=((my_array[k*r+kk,j*q+jj,i*p+ii]-solid_value)/(pores_value-solid_value)+ eps_min*(pores_value-my_array[k*r+kk,j*q+jj,i*p+ii])/(pores_value-solid_value))/p/q/r


print('create eps')
f=open('0/eps','a')
f.seek(0) #get to the first position
f.write("FoamFile"+'\n')
f.write("{"+'\n')
f.write("    version     2.0;"+'\n')
f.write("    format      ascii;"+'\n')
f.write("    class       volScalarField;"+'\n')
f.write("    object      eps;"+'\n')
f.write("}"+'\n')
f.write(""+'\n')
f.write("dimensions      [0 0 0 0 0 0 0];"+'\n')
f.write("internalField   nonuniform List<scalar>"+'\n')
f.write(str(ncell)+'\n')
f.write("("+'\n')
for k in range (0,nz1):
    for j in range (0, ny1):
        for i in range (0, nx1):
            f.write(str(eps[i,j,k])+'\n')
f.write(")"+'\n')
f.write(";"+'\n')
f.write(""+'\n')
f.write("boundaryField"+'\n')
f.write("{"+'\n')
f.write("    walls"+'\n')
f.write("    {"+'\n')
f.write("        type zeroGradient;"+'\n')
f.write("    }"+'\n')
f.write("    inlet"+'\n')
f.write("    {"+'\n')
f.write("        type zeroGradient;"+'\n')
f.write("    }"+'\n')
f.write("    outlet"+'\n')
f.write("    {"+'\n')
f.write("        type zeroGradient;"+'\n')
f.write("    }"+'\n')
f.write("}"+'\n')
f.close()

print('create blockMeshDict')

os.system('sed -i "s/nx/'+str(nx1)+'/g" constant/polyMesh/blockMeshDict')
os.system('sed -i "s/ny/'+str(ny1)+'/g" constant/polyMesh/blockMeshDict')
os.system('sed -i "s/nz/'+str(nz1)+'/g" constant/polyMesh/blockMeshDict')

os.system('sed -i "s/res/'+str(res)+'/g" constant/polyMesh/blockMeshDict')

os.system('sed -i "s/xMin/'+str(xmin)+'/g" constant/polyMesh/blockMeshDict')
os.system('sed -i "s/yMin/'+str(ymin)+'/g" constant/polyMesh/blockMeshDict')
os.system('sed -i "s/zMin/'+str(zmin)+'/g" constant/polyMesh/blockMeshDict')
os.system('sed -i "s/xMax/'+str(xmax)+'/g" constant/polyMesh/blockMeshDict')
os.system('sed -i "s/yMax/'+str(ymax)+'/g" constant/polyMesh/blockMeshDict')
os.system('sed -i "s/zMax/'+str(zmax)+'/g" constant/polyMesh/blockMeshDict')

os.system("blockMesh > blockMesh.out")

os.system('cp system/decomposeParDict0 system/decomposeParDict')
os.system('sed -i "s/NP/'+str(NP)+'/g" system/decomposeParDict')
os.system('echo "decompose parallel mesh"')
os.system('decomposePar > decomposePar.out')

os.system('cp constant/dynamicMeshDictInit constant/dynamicMeshDict')
os.system('cp constant/dynamicMeshDictInit constant/dynamicMeshDict0')
os.system('cp constant/dynamicMeshDictInit constant/dynamicMeshDict1')

if (nLevel>0):
    os.system('cp constant/dynamicMeshDictAMRInit constant/dynamicMeshDict')
    os.system('cp constant/dynamicMeshDictAMRInit constant/dynamicMeshDict0')

    upRef=0.99+0.02*refineStokes
    os.system('sed -i "s/nRef/1/g" constant/dynamicMeshDict')
    os.system('sed -i "s/lowRef/0.01/g" constant/dynamicMeshDict')
    os.system('sed -i "s/upRef/'+str(upRef)+'/g" constant/dynamicMeshDict')
    os.system('sed -i "s/refLevel/'+str(nLevel)+'/g" constant/dynamicMeshDict')


    os.system('sed -i "s/nRef/'+str(nRef)+'/g" constant/dynamicMeshDict0')
    os.system('sed -i "s/lowRef/0.01/g" constant/dynamicMeshDict0')
    os.system('sed -i "s/upRef/'+str(upRef)+'/g" constant/dynamicMeshDict0')
    os.system('sed -i "s/refLevel/'+str(nLevel)+'/g" constant/dynamicMeshDict0')

    dt=1e-6/nLevel

    os.system('cp system/controlDictAMRInit system/controlDict')
    os.system('sed -i "s/dt/'+str(dt)+'/g" system/controlDict')

    os.system('echo "refine mesh at interface by running reactiveTransportDBSFoam for small time"')
    os.system('mpiexec -np '+str(NP)+' reactiveTransportDBSFoam -parallel > reactiveTransportDBSFoamInit.out')

    os.system('echo "reconstruct parallel mesh"')
    os.system("reconstructParMesh -latestTime > reconstructParMeshInit.out")

    os.system("rm -rf processor*/0")
    for i in range(0,NP):
        os.system('mv processor'+str(i)+'/1e-06 processor'+str(i)+'/0')

    os.system("rm processor*/0/phi")
    os.system("rm processor*/0/ddt*")
    os.system("rm processor*/0/R")
    os.system("rm -rf processor*/0/uniform")

    os.system("rm -rf 0")
    os.system("mv 1e-06 0")

    os.system("rm 0/phi")
    os.system("rm 0/ddt*")
    os.system("rm 0/R")
    os.system("rm -rf 0/uniform")
    os.system("cp 0_orig/U 0/.")
    os.system("cp 0_orig/p 0/.")
    os.system("cp 0_orig/C 0/.")
    os.system('sed -i "s/flow_rate/1e-30/g" 0/U')
    os.system('sed -i "s/c_inlet/0/g" 0/C')

    os.system('echo "process mesh centers"')
    os.system("processMeshCellCenters > processMeshCellCenters.out")

    nz1=2**nLevel*nz1
    ny1=2**nLevel*ny1
    nx1=2**nLevel*nx1
    p=int((xmax-xmin)/nx1)
    q=int((ymax-ymin)/ny1)
    r=int((zmax-zmin)/nz1)
    os.system('echo "calculate eps for fine mesh"')
    eps=np.zeros((nx1,ny1,nz1),dtype=float)
    for i in range (0,nx1):
        for ii in range (0,p):
            for j in range (0,ny1):
                for jj in range (0,q):
                    for k in range (0,nz1):
                        for kk in range (0,r):
                            eps[i,j,k]+=((my_array[k*r+kk,j*q+jj,i*p+ii]-solid_value)/(pores_value-solid_value)+ eps_min*(pores_value-my_array[k*r+kk,j*q+jj,i*p+ii])/(pores_value-solid_value))/p/q/r

    dx = res*(xmax-xmin)/nx1
    dy = res*(ymax-ymin)/ny1
    dz = res*(zmax-zmin)/nz1
    
    ix = np.zeros(nx1*ny1*nz1)
    iy = np.zeros(nx1*ny1*nz1)
    iz = np.zeros(nx1*ny1*nz1)

    file = open("0/cellCenters","r")
    Lines = file.readlines()
    count =0
    wbool=0
    for line in Lines:
      ls = line.strip()
      if (ls==")"):
          break
      if (wbool==1):
          x=float(ls.split("(")[1].split(")")[0].split()[0])
          ix[count] = np.floor((x-res*xmin)/dx);
          y=float(ls.split("(")[1].split(")")[0].split()[1])
          iy[count] = np.floor((y-res*ymin)/dy);
          z=float(ls.split("(")[1].split(")")[0].split()[2])
          iz[count] = np.floor((z-res*zmin)/dz);
          count +=1
      if (ls=="("):
          wbool=1

    ncell = count

    newEps = np.zeros(ncell)

    os.system('echo "modify eps according to finer mesh for cells at interface using cell center"')

    file = open("0/eps","r")
    Lines = file.readlines()
    count=0
    wbool=0
    for line in Lines:
      ls = line.strip()
      if (ls==")"):
          break
      if (wbool==1):
          epsVal=float(ls)
          if (epsVal<1) and (epsVal>0.01):
            newEps[count] = eps[ix[count].astype(int),iy[count].astype(int),iz[count].astype(int)]
          else:
            newEps[count] = epsVal
          count +=1
      if (ls=="("):
          wbool=1

    os.system('rm 0/eps')
    f=open('0/eps','a')
    f.seek(0) #get to the first position
    f.write("FoamFile"+'\n')
    f.write("{"+'\n')
    f.write("    version     2.0;"+'\n')
    f.write("    format      ascii;"+'\n')
    f.write("    class       volScalarField;"+'\n')
    f.write("    object      eps;"+'\n')
    f.write("}"+'\n')
    f.write(""+'\n')
    f.write("dimensions      [0 0 0 0 0 0 0];"+'\n')
    f.write("internalField   nonuniform List<scalar>"+'\n')
    f.write(str(ncell)+'\n')
    f.write("("+'\n')

    for k in range(0,ncell):
            f.write(str(newEps[k])+'\n')
    f.write(")"+'\n')
    f.write(";"+'\n')
    f.write(""+'\n')
    f.write("boundaryField"+'\n')
    f.write("{"+'\n')
    f.write("    walls"+'\n')
    f.write("    {"+'\n')
    f.write("        type zeroGradient;"+'\n')
    f.write("    }"+'\n')
    f.write("    inlet"+'\n')
    f.write("    {"+'\n')
    f.write("        type zeroGradient;"+'\n')
    f.write("    }"+'\n')
    f.write("    outlet"+'\n')
    f.write("    {"+'\n')
    f.write("        type zeroGradient;"+'\n')
    f.write("    }"+'\n')
    f.write("}"+'\n')
    f.close()

    os.system('rm -f 0/cellCenters')

