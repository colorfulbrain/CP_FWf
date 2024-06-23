#!/bin/bash
subjDIR='/home/binyin/nasdata/RJ_UI890_forAD/niigz/'
SUBJECTS_DIR='/home/binyin/nasdata/RJ_UI890_forAD/stacked_preproc/recon_fs711/'
subjTAR='/home/binyin/nasdata/RJ_UI890_forAD/preproc/'
subjname=$1
mkdir -p $subjTAR/$subjname/dMRI/ALPS
cd $subjTAR/$subjname/

dtifit -k ./dMRI/data -m ./dMRI/nodif_brain_mask_ud.nii.gz -r ./dMRI/bvecs -b ./dMRI/bvals -o ./dMRI/dtifit/dti --save_tensor

fslsplit $subjTAR/$subjname/dMRI/dtifit/dti_tensor.nii.gz $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor

applywarp -i /home/binyin/local4t/research/project/external/alps/association-L.nii.gz -r $subjTAR/$subjname/dMRI/dtifit/dti_FA.nii.gz -o $subjTAR/$subjname/dMRI/ALPS/A_L.nii.gz -w $subjTAR/$subjname/dMRI/TBSS/FA/MNI_to_dti_FA_warp.nii.gz --interp=nn
applywarp -i /home/binyin/local4t/research/project/external/alps/projection-L.nii.gz -r $subjTAR/$subjname/dMRI/dtifit/dti_FA.nii.gz -o $subjTAR/$subjname/dMRI/ALPS/P_L.nii.gz -w $subjTAR/$subjname/dMRI/TBSS/FA/MNI_to_dti_FA_warp.nii.gz --interp=nn

applywarp -i /home/binyin/local4t/research/project/external/alps/association-R.nii.gz -r $subjTAR/$subjname/dMRI/dtifit/dti_FA.nii.gz -o $subjTAR/$subjname/dMRI/ALPS/A_R.nii.gz -w $subjTAR/$subjname/dMRI/TBSS/FA/MNI_to_dti_FA_warp.nii.gz --interp=nn
applywarp -i /home/binyin/local4t/research/project/external/alps/projection-R.nii.gz -r $subjTAR/$subjname/dMRI/dtifit/dti_FA.nii.gz -o $subjTAR/$subjname/dMRI/ALPS/P_R.nii.gz -w $subjTAR/$subjname/dMRI/TBSS/FA/MNI_to_dti_FA_warp.nii.gz --interp=nn


pxx_l=`fslstats $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor0000.nii.gz -k $subjTAR/$subjname/dMRI/ALPS/P_L.nii.gz -m`
axx_l=`fslstats $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor0000.nii.gz -k $subjTAR/$subjname/dMRI/ALPS/A_L.nii.gz -m`
pyy_l=`fslstats $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor0003.nii.gz -k $subjTAR/$subjname/dMRI/ALPS/P_L.nii.gz -m`
azz_l=`fslstats $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor0005.nii.gz -k $subjTAR/$subjname/dMRI/ALPS/A_L.nii.gz -m`

pxx_r=`fslstats $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor0000.nii.gz -k $subjTAR/$subjname/dMRI/ALPS/P_R.nii.gz -m`
axx_r=`fslstats $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor0000.nii.gz -k $subjTAR/$subjname/dMRI/ALPS/A_R.nii.gz -m`
pyy_r=`fslstats $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor0003.nii.gz -k $subjTAR/$subjname/dMRI/ALPS/P_R.nii.gz -m`
azz_r=`fslstats $subjTAR/$subjname/dMRI/dtifit/fDTI_tensor0005.nii.gz -k $subjTAR/$subjname/dMRI/ALPS/A_R.nii.gz -m`

echo "($pxx_l+$axx_l)/($pyy_l+$azz_l)"|bc -l> $subjTAR/$subjname/dMRI/ALPS/alps_l.txt
echo "($pxx_r+$axx_r)/($pyy_r+$azz_r)"|bc -l> $subjTAR/$subjname/dMRI/ALPS/alps_r.txt





