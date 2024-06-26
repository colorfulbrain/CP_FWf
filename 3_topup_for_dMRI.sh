#!/usr/bin/env bash 

subjDIR=$2
subjTAR=$3

template='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/templates'
tool='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/tools/'
parameter='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/hyperparameter/'

####################merge for topup
mkdir -p $subjTAR/$1/B0_AP_PA


#######choose best B0
python $tool/bb_get_b0s.py -i $subjDIR/$1/dMRI/dMRI.nii.gz -o $subjDIR/$1/B0_AP_PA/B0_PA_sum.nii.gz -n 4 -l 50
$tool/bb_choose_bestB0 $subjDIR/$1/B0_AP_PA/B0_PA_sum.nii.gz $subjDIR/$1/B0_AP_PA/B0_PA.nii.gz


#first PA, then AP
fslmerge -t $subjTAR/$1/B0_AP_PA/B0_AP_PA $subjDIR/$1/B0_AP_PA/B0_PA $subjDIR/$1/B0_AP_PA/B0_AP


###################run topup for dMRI###Need to change for local path############################
echo 'run topup'
cd $subjTAR
/home/binyin/local4t/research/data_wash/RJ_uMR890_forAD/prepare_topup4dMRI.sh $1 $subjDIR $subjTAR

topup --imain=$subjTAR/$1/B0_AP_PA/B0_AP_PA --datain=$subjTAR/$1/B0_AP_PA/acqparams.txt --config=$parameter/topup_b02b0.cnf --out=$subjTAR/$1/B0_AP_PA/fieldmap_out --fout=$subjTAR/$1/B0_AP_PA/fieldmap_fout --jacout=$subjTAR/$1/B0_AP_PA/fieldmap_jacout -v --subsamp=1


####post topup
echo 'apply topup'
cd $subjTAR
#Get corrected B=0 for AP and PA and average them avoiding zero values
${FSLDIR}/bin/applytopup --imain=$subjDIR/$1/B0_AP_PA/B0_AP --datain=$1/B0_AP_PA/acqparams.txt --inindex=1 --topup=$1/B0_AP_PA/fieldmap_out --out=$1/B0_AP_PA/B0_AP_corr_tmp --method=jac
${FSLDIR}/bin/applytopup --imain=$subjDIR/$1/B0_AP_PA/B0_PA --datain=$1/B0_AP_PA/acqparams.txt --inindex=2 --topup=$1/B0_AP_PA/fieldmap_out --out=$1/B0_AP_PA/B0_PA_corr_tmp --method=jac

echo 'get mask'
    #Get a mask with the zero-valued voxels for AP and PA
python $tool/bb_mask_negatives_4D.py -i $1/B0_AP_PA/B0_AP_corr_tmp.nii.gz -o $1/B0_AP_PA/B0_AP_zero_mask_tmp.nii.gz -z True
python $tool/bb_mask_negatives_4D.py -i $1/B0_AP_PA/B0_PA_corr_tmp.nii.gz -o $1/B0_AP_PA/B0_PA_zero_mask_tmp.nii.gz -z True

    #Multiply the previous mask by the other direction and thus, get the values in AP for which we have zero in PA (And viceversa)
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/B0_AP_corr_tmp.nii.gz -mul $1/B0_AP_PA/B0_PA_zero_mask_tmp.nii.gz $1/B0_AP_PA/AP_masked_tmp.nii.gz
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/B0_PA_corr_tmp.nii.gz -mul $1/B0_AP_PA/B0_AP_zero_mask_tmp.nii.gz $1/B0_AP_PA/PA_masked_tmp.nii.gz
    
    #Add the previous result to B=0 AP and PA
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/B0_AP_corr_tmp.nii.gz -add $1/B0_AP_PA/PA_masked_tmp.nii.gz $1/B0_AP_PA/B0_AP_fixed_tmp.nii.gz
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/B0_PA_corr_tmp.nii.gz -add $1/B0_AP_PA/AP_masked_tmp.nii.gz $1/B0_AP_PA/B0_PA_fixed_tmp.nii.gz

    #Merge and average them
${FSLDIR}/bin/fslmerge -t $1/B0_AP_PA/fieldmap_iout.nii.gz $1/B0_AP_PA/B0_AP_fixed_tmp.nii.gz $1/B0_AP_PA/B0_PA_fixed_tmp.nii.gz
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/fieldmap_iout.nii.gz -Tmean $1/B0_AP_PA/fieldmap_iout_mean.nii.gz



#GDC to iout_mean
#bb_GDC --workingdir=$1/fieldmap//fieldmap_iout_GDC/ --in=$1/fieldmap/fieldmap_iout_mean.nii.gz --out=$1/fieldmap/fieldmap_iout_mean_ud.nii.gz --owarp=$1/fieldmap/fieldmap_iout_mean_ud_warp.nii.gz
#TODO: This was the previous copy. The geometry is exactly the same for B0_AP and fieldmap_iout_mean -- fslcpgeom $1/fieldmap/fieldmap_iout_mean.nii.gz $1/fieldmap/fieldmap_fout.nii.gz

cp $1/B0_AP_PA/fieldmap_iout_mean.nii.gz $1/B0_AP_PA/fieldmap_iout_mean_ud.nii.gz
${FSLDIR}/bin/fslcpgeom $subjDIR/$1/B0_AP_PA/B0_PA.nii.gz $1/B0_AP_PA/fieldmap_fout.nii.gz


#Clean temporary files
${FSLDIR}/bin/imrm *_tmp.nii.gz

echo 'Get the topup iout (magnitude) to struct space and apply the transformation to fout (fieldmap)'

$tool/bb_epi_reg --epi=$1/B0_AP_PA/fieldmap_iout_mean_ud.nii.gz --t1=$1/T1/T1.nii.gz --t1brain=$1/T1/T1_brain.nii.gz --out=$1/B0_AP_PA/fieldmap_iout_to_T1 --wmseg=$1/T1/T1_fast/T1_brain_WM_mask.nii.gz
${FSLDIR}/bin/applywarp --rel -i $1/B0_AP_PA/fieldmap_fout.nii.gz -r $1/T1/T1.nii.gz -o $1/B0_AP_PA/fieldmap_fout_to_T1 --postmat=$1/B0_AP_PA/fieldmap_iout_to_T1.mat --interp=spline

# Mask the warped fout (fieldmap) using T1 brain mask
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/fieldmap_fout_to_T1 -mul $1/T1/T1_brain_mask.nii.gz $1/B0_AP_PA/fieldmap_fout_to_T1_brain.nii.gz

# Multiply the warped & masked fout (fieldmap) by 2*Pi to have it in radians
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/fieldmap_fout_to_T1_brain.nii.gz -mul 6.283185 $1/B0_AP_PA/fieldmap_fout_to_T1_brain_rad.nii.gz

# Generate a mask for topup output by inverting the previous registration and applying it to T1 brain mask
${FSLDIR}/bin/convert_xfm -omat $1/B0_AP_PA/T1_to_fieldmap_iout.mat -inverse $1/B0_AP_PA/fieldmap_iout_to_T1.mat
${FSLDIR}/bin/fslmaths $1/T1/T1_brain_mask.nii.gz -thr 0.1 -kernel sphere 1.1 -dilF -bin -fillh $1/T1/T1_brain_mask_dil.nii.gz
${FSLDIR}/bin/flirt -in $1/T1/T1_brain_mask_dil.nii.gz -ref $1/B0_AP_PA/fieldmap_iout_mean.nii.gz -applyxfm -init $1/B0_AP_PA/T1_to_fieldmap_iout.mat -out $1/B0_AP_PA/fieldmap_mask_ud.nii.gz -interp trilinear
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/fieldmap_mask_ud.nii.gz -thr 0.25 -bin -fillh $1/B0_AP_PA/fieldmap_mask_ud.nii.gz

#Warp the dilated T1 brain mask to the Gradient Distorted space
${FSLDIR}/bin/applywarp --rel -i $1/T1/T1_brain_mask_dil.nii.gz -r $1/B0_AP_PA/fieldmap_iout_mean.nii.gz -o $1/B0_AP_PA/fieldmap_mask.nii.gz --premat=$1/B0_AP_PA/T1_to_fieldmap_iout.mat --interp=trilinear
${FSLDIR}/bin/fslmaths $1/B0_AP_PA/fieldmap_mask.nii.gz -thr 0.25 -bin -fillh $1/B0_AP_PA/fieldmap_mask.nii.gz



#####################################################################

