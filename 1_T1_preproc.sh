#!/bin/sh
# FOLLOW UKBB pipeline
# Description: Main script with all the processing for T1

subjDIR=$2
subjTAR=$3
template='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/templates'
tool='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/tools/'
parameter='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/hyperparameter/'

mkdir -p $subjTAR/$1/T1
cd $subjTAR/$1/T1  # into individual T1 folder
cp $subjDIR/$1/T1/T1_orig.nii.gz T1_orig.nii.gz

#no coil grad file for UI891, activate the #Alternative
#Alternative
cp $subjTAR/$1/T1/T1_orig.nii.gz T1_orig_ud.nii.gz

#Calculate where does the brain start in the z dimension and then extract the roi
head_top=`${FSLDIR}/bin/robustfov -i T1_orig_ud | grep -v Final | head -n 1 | awk '{print $5}'`
head_down=`${FSLDIR}/bin/robustfov -i T1_orig_ud | grep -v Final | head -n 1 | awk '{print $6}'`

${FSLDIR}/bin/fslmaths T1_orig_ud -roi 0 -1 0 -1 $head_top $head_down 0 1 T1_tmp

#Run a (Recursive) brain extraction on the roi
${FSLDIR}/bin/bet T1_tmp T1_tmp_brain -R

#Reduces the FOV of T1_orig_ud by calculating a registration from T1_tmp_brain to ssref and applies it to T1_orig_ud
${FSLDIR}/bin/standard_space_roi T1_tmp_brain T1_tmp2 -maskNONE -ssref $FSLDIR/data/standard/MNI152_T1_1mm_brain -altinput T1_orig_ud -d

${FSLDIR}/bin/immv T1_tmp2 T1  # get T1.nii.gz

#########################################################
#Generate the actual affine from the orig_ud volume to the cut version we have now and combine it to have an affine matrix from orig_ud to MNI
${FSLDIR}/bin/flirt -in T1 -ref T1_orig_ud -omat T1_to_T1_orig_ud.mat -schedule $FSLDIR/etc/flirtsch/xyztrans.sch 
${FSLDIR}/bin/convert_xfm -omat T1_orig_ud_to_T1.mat -inverse T1_to_T1_orig_ud.mat
${FSLDIR}/bin/convert_xfm -omat T1_to_MNI_linear.mat -concat T1_tmp2_tmp_to_std.mat T1_to_T1_orig_ud.mat

#Non-linear registration to MNI using the previously calculated alignment
# change PATH to bb_fnirt.cnf,MNI152_T1_1mm_brain_mask_dil_GD7
${FSLDIR}/bin/fnirt --in=T1 --ref=$FSLDIR/data/standard/MNI152_T1_1mm --aff=T1_to_MNI_linear.mat --config=$parameter/bb_fnirt.cnf --refmask=$template/MNI152_T1_1mm_brain_mask_dil_GD7 --logout=../logs/bb_T1_to_MNI_fnirt.log --cout=T1_to_MNI_warp_coef --fout=T1_to_MNI_warp --jout=T1_to_MNI_warp_jac --iout=T1_tmp4.nii.gz --interp=spline --jacrange=-1

#Combine both transforms (Gradient Distortion Unwarp and T1 to MNI) into one and then apply it.
#${FSLDIR}/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_1mm --warp1=T1_orig_ud_warp --midmat=T1_orig_ud_to_T1.mat --warp2=T1_to_MNI_warp --out=T1_orig_to_MNI_warp
#Alternative
${FSLDIR}/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_1mm --premat=T1_orig_ud_to_T1.mat --warp1=T1_to_MNI_warp --out=T1_orig_to_MNI_warp

${FSLDIR}/bin/applywarp --rel -i T1_orig -r $FSLDIR/data/standard/MNI152_T1_1mm -w T1_orig_to_MNI_warp -o T1_brain_to_MNI --interp=spline

#Create brain mask
# change PATH to MNI152_T1_1mm_brain_mask
${FSLDIR}/bin/invwarp --ref=T1 -w T1_to_MNI_warp_coef -o T1_to_MNI_warp_coef_inv
${FSLDIR}/bin/applywarp --rel --interp=trilinear --in=$template/MNI152_T1_1mm_brain_mask.nii.gz --ref=T1 -w T1_to_MNI_warp_coef_inv -o T1_brain_mask
${FSLDIR}/bin/fslmaths T1 -mul T1_brain_mask T1_brain  # get T1_brain.nii.gz(no skull)
${FSLDIR}/bin/fslmaths T1_brain_to_MNI -mul $template/MNI152_T1_1mm_brain_mask.nii.gz T1_brain_to_MNI

#Defacing T1
# change PATH to MNI152_T1_1mm_BigFoV_facemask, MNI_to_MNI_BigFoV_facemask.mat
${FSLDIR}/bin/convert_xfm -omat grot.mat -concat T1_to_MNI_linear.mat T1_orig_ud_to_T1.mat
${FSLDIR}/bin/convert_xfm -omat grot.mat -concat $template/MNI_to_MNI_BigFoV_facemask.mat grot.mat
${FSLDIR}/bin/convert_xfm -omat grot.mat -inverse grot.mat
${FSLDIR}/bin/flirt -in $template/MNI152_T1_1mm_BigFoV_facemask -ref T1_orig -out grot -applyxfm -init grot.mat

${FSLDIR}/bin/fslmaths grot -binv -mul T1_orig T1_orig_defaced

cp T1.nii.gz T1_not_defaced_tmp.nii.gz  
${FSLDIR}/bin/convert_xfm -omat grot.mat -concat $template/MNI_to_MNI_BigFoV_facemask.mat T1_to_MNI_linear.mat
${FSLDIR}/bin/convert_xfm -omat grot.mat -inverse grot.mat
${FSLDIR}/bin/flirt -in $template/MNI152_T1_1mm_BigFoV_facemask -ref T1 -out grot -applyxfm -init grot.mat
${FSLDIR}/bin/fslmaths grot -binv -mul T1 T1

#Generation of QC value: Number of voxels in which the defacing mask goes into the brain mask
${FSLDIR}/bin/fslmaths T1_brain_mask -thr 0.5 -bin grot_brain_mask 
${FSLDIR}/bin/fslmaths grot -thr 0.5 -bin -add grot_brain_mask -thr 2 grot_QC
${FSLDIR}/bin/fslstats grot_QC.nii.gz -V | awk '{print $ 1}' > $subjTAR/$1/T1/T1_QC_face_mask_inside_brain_mask.txt

echo QCfinished

rm grot*
#Clean and reorganize
rm *tmp*
mkdir transforms
mv *MNI* transforms
mv *warp*.* transforms
mv *_to_* transforms
mv transforms/T1_brain_to_MNI.nii.gz .

cd ..

# preprocess for T2_flair






cd $subjTAR/$1/T1
#Run fast for gray matter segmentation
mkdir T1_fast
${FSLDIR}/bin/fast -b -o T1_fast/T1_brain T1_brain

#Binarize PVE masks
if [ -f T1_fast/T1_brain_pveseg.nii.gz ] ; then
    $FSLDIR/bin/fslmaths T1_fast/T1_brain_pve_0.nii.gz -thr 0.5 -bin T1_fast/T1_brain_CSF_mask.nii.gz
    $FSLDIR/bin/fslmaths T1_fast/T1_brain_pve_1.nii.gz -thr 0.5 -bin T1_fast/T1_brain_GM_mask.nii.gz
    $FSLDIR/bin/fslmaths T1_fast/T1_brain_pve_2.nii.gz -thr 0.5 -bin T1_fast/T1_brain_WM_mask.nii.gz
    # for asl segmentation in basil process
    cp T1_fast/T1_brain_pve_0.nii.gz ./T1_fast_pve_0.nii.gz
    cp T1_fast/T1_brain_pve_1.nii.gz ./T1_fast_pve_1.nii.gz
    cp T1_fast/T1_brain_pve_2.nii.gz ./T1_fast_pve_2.nii.gz
    cp T1_fast/T1_brain_bias.nii.gz ./T1_fast_bias.nii.gz
fi

#Apply bias field correction to T1
if [ -f T1_fast/T1_brain_bias.nii.gz ] ; then
    ${FSLDIR}/bin/fslmaths T1.nii.gz -div T1_fast/T1_brain_bias.nii.gz T1_unbiased.nii.gz
    ${FSLDIR}/bin/fslmaths T1_brain.nii.gz -div T1_fast/T1_brain_bias.nii.gz T1_unbiased_brain.nii.gz
else
    echo "WARNING: There was no bias field estimation. Bias field correction cannot be applied to T1."
fi
echo T1fastfinished


#Run First for subcortical structures
mkdir T1_first

#Creates a link inside T1_first to ./T1_unbiased_brain.nii.gz (In the present working directory)
ln -s ../T1_unbiased_brain.nii.gz T1_first/T1_unbiased_brain.nii.gz
${FSLDIR}/bin/run_first_all -i T1_first/T1_unbiased_brain -b -o T1_first/T1_first
echo T1fisrtfinished

