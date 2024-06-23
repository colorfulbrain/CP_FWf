#!/bin/bash 

#subjDIR=$2
#subjTAR=$3

template='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/templates'
tool='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/tools/'
parameter='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/hyperparameter/'

mkdir -p $subjTAR/$1/dMRI

cd $subjTAR/$1/
# Prepare data for eddy, dtifit and bedpostx.
cp ./B0_AP_PA/fieldmap_iout_mean.nii.gz ./dMRI/nodif.nii.gz
cp ./B0_AP_PA/fieldmap_mask.nii.gz ./dMRI/nodif_brain_mask.nii.gz
cp ./B0_AP_PA/fieldmap_mask_ud.nii.gz ./dMRI/nodif_brain_mask_ud.nii.gz

cp $subjDIR/$1/dMRI/dMRI.bval ./dMRI/bvals
cp $subjDIR/$1/dMRI/dMRI.bvec ./dMRI/bvecs
cp $subjDIR/$1/dMRI/dMRI.nii.gz ./dMRI/PA.nii.gz

indx=""
n=`${FSLDIR}/bin/fslval ./dMRI/PA.nii.gz dim4`
for ((i=1;i<=${n};i++));do
    indx="$indx 1"
done
echo $indx > ./dMRI/eddy_index.txt


## eddy correction

$FSLDIR/bin/eddy_cuda10.2 --imain=./dMRI/PA.nii.gz --mask=./dMRI/nodif_brain_mask_ud.nii.gz --topup=./B0_AP_PA/fieldmap_out --acqp=./B0_AP_PA/acqparams.txt --index=./dMRI/eddy_index.txt --bvecs=./dMRI/bvecs --bvals=./dMRI/bvals --out=./dMRI/data --ref_scan_no=0 --flm=quadratic --resamp=jac --slm=linear --fwhm=2 --ff=5  --sep_offs_move --nvoxhp=1000 --very_verbose  --repol --rms

# ditfit for FA, MD, MO
mkdir -p $subjTAR/$1/dMRI/dtifit
#dtifit -k ./dMRI/data -m ./dMRI/nodif_brain_mask_ud.nii.gz -r ./dMRI/bvecs -b ./dMRI/bvals -o ./dMRI/dtifit/dti
dtifit -k ./dMRI/data -m ./dMRI/nodif_brain_mask_ud.nii.gz -r ./dMRI/bvecs -b ./dMRI/bvals -o ./dMRI/dtifit/dti --save_tensor
