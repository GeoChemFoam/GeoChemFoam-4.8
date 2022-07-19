# Load user environment variables
source ~/.bashrc


source $HOME/works/GeoChemFoam-4.5/etc/bashrc 
set -e

surfaceSmooth constant/triSurface/Image_meshed.stl 1.0 1 constant/triSurface/Image_meshed2.stl > smooth.out
mv constant/triSurface/Image_meshed2.stl constant/triSurface/Image_meshed.stl
