#!/bin/sh
#
# Script name: bb_struct_init
#
# Description: Main script with all the processing for T1

# omit： bbgetb0，bbchoose_best_b0,fslmerge_APPA, compared to UKbiobank script
#. $BB_BIN_DIR/bb_pipeline_tools/bb_set_header 
# input subjid

subjDIR=$2
subjTAR=$3
template='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/templates'
tool='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/tools/'
parameter='/home/binyin/local4t/research/codes/RJNBscripts/RJNBpreprocCode/hyperparameter/'

#### preprocess for T2_flair
mkdir -p $subjTAR/$1/T2flair
cd $subjTAR/$1/T2flair
cp $subjDIR/$1/T2flair/T2_flair.nii.gz T2_FLAIR_orig_ud.nii.gz
cp $subjDIR/$1/T2flair/T2_flair.nii.gz T2_FLAIR_orig.nii.gz

#Take T2 to T1 and also the brain mask
${FSLDIR}/bin/flirt -in T2_FLAIR_orig_ud -ref ../T1/T1_orig_ud -out T2_FLAIR_tmp -omat T2_FLAIR_tmp.mat -dof 6
${FSLDIR}/bin/convert_xfm -omat T2_FLAIR_tmp2.mat -concat ../T1/transforms/T1_orig_ud_to_T1.mat  T2_FLAIR_tmp.mat
${FSLDIR}/bin/flirt -in T2_FLAIR_orig_ud -ref ../T1/T1_brain -refweight ../T1/T1_brain_mask -nosearch -init T2_FLAIR_tmp2.mat -omat T2_FLAIR_orig_ud_to_T2_FLAIR.mat -dof 6
${FSLDIR}/bin/applywarp --rel  -i T2_FLAIR_orig -r ../T1/T1_brain -o T2_FLAIR --postmat=T2_FLAIR_orig_ud_to_T2_FLAIR.mat --interp=spline
cp ../T1/T1_brain_mask.nii.gz T2_FLAIR_brain_mask.nii.gz
${FSLDIR}/bin/fslmaths T2_FLAIR -mul T2_FLAIR_brain_mask T2_FLAIR_brain

#Generate the linear matrix from T2 to MNI (Needed for defacing)
${FSLDIR}/bin/convert_xfm -omat T2_FLAIR_orig_ud_to_MNI_linear.mat -concat ../T1/transforms/T1_to_MNI_linear.mat T2_FLAIR_orig_ud_to_T2_FLAIR.mat
cp ../T1/transforms/T1_to_MNI_linear.mat T2_FLAIR_to_MNI_linear.mat 

#Generate the non-linearly warped T2 in MNI (Needed for post-freesurfer processing)
#${FSLDIR}/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_1mm --warp1=T2_FLAIR_orig_ud_warp --midmat=T2_FLAIR_orig_ud_to_T2_FLAIR.mat --warp2=../T1/transforms/T1_to_MNI_warp --out=T2_FLAIR_orig_to_MNI_warp
#Alternative
${FSLDIR}/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_1mm --premat=T2_FLAIR_orig_ud_to_T2_FLAIR.mat --warp1=../T1/transforms/T1_to_MNI_warp --out=T2_FLAIR_orig_to_MNI_warp
${FSLDIR}/bin/applywarp --rel  -i T2_FLAIR_orig -r $FSLDIR/data/standard/MNI152_T1_1mm -w T2_FLAIR_orig_to_MNI_warp -o T2_FLAIR_brain_to_MNI --interp=spline
${FSLDIR}/bin/fslmaths T2_FLAIR_brain_to_MNI -mul $template/MNI152_T1_1mm_brain_mask T2_FLAIR_brain_to_MNI

#Defacing T2_FLAIR
${FSLDIR}/bin/convert_xfm -omat grot.mat -concat T2_FLAIR_to_MNI_linear.mat T2_FLAIR_orig_ud_to_T2_FLAIR.mat
${FSLDIR}/bin/convert_xfm -omat grot.mat -concat $template/MNI_to_MNI_BigFoV_facemask.mat grot.mat
${FSLDIR}/bin/convert_xfm -omat grot.mat -inverse grot.mat
${FSLDIR}/bin/flirt -in $template/MNI152_T1_1mm_BigFoV_facemask -ref T2_FLAIR_orig -out grot -applyxfm -init grot.mat
${FSLDIR}/bin/fslmaths grot -binv -mul T2_FLAIR_orig T2_FLAIR_orig_defaced

cp T2_FLAIR.nii.gz T2_FLAIR_not_defaced_tmp.nii.gz  
${FSLDIR}/bin/convert_xfm -omat grot.mat -concat $template/MNI_to_MNI_BigFoV_facemask.mat T2_FLAIR_to_MNI_linear.mat
${FSLDIR}/bin/convert_xfm -omat grot.mat -inverse grot.mat
${FSLDIR}/bin/flirt -in $template/MNI152_T1_1mm_BigFoV_facemask -ref T2_FLAIR -out grot -applyxfm -init grot.mat
${FSLDIR}/bin/fslmaths grot -binv -mul T2_FLAIR T2_FLAIR
rm grot*

 #Clean and reorganize
rm *_tmp*
mkdir transforms
mv *.mat transforms
mv *warp*.* transforms
    
#Apply bias field correction to T2_FLAIR warped
if [ -f ../T1/T1_fast/T1_brain_bias.nii.gz ] ; then
    ${FSLDIR}/bin/fslmaths T2_FLAIR.nii.gz -div ../T1/T1_fast/T1_brain_bias.nii.gz T2_FLAIR_unbiased.nii.gz
    ${FSLDIR}/bin/fslmaths T2_FLAIR_brain.nii.gz -div ../T1/T1_fast/T1_brain_bias.nii.gz T2_FLAIR_unbiased_brain.nii.gz
else
    echo "WARNING: There was no bias field estimation. Bias field correction cannot be applied to T2."
fi

cd ../..

#Run BIANCA
origDir=`pwd`

dirT1=$subjTAR/$1/T1
dirT2=$subjTAR/$1/T2flair

#Check if all required files are in place. In case one is missing, BIANCA will not run
for required_file in "$dirT1/T1_unbiased_brain.nii.gz" "$dirT1/T1_unbiased.nii.gz" "$dirT2/T2_FLAIR_unbiased.nii.gz" "$dirT1/transforms/T1_to_MNI_warp_coef_inv.nii.gz" "$dirT1/transforms/T1_to_MNI_linear.mat" "$dirT1/T1_fast/T1_brain_pve_0.nii.gz" ; do
    if [ ! -f $required_file ] ; then
        echo "Problem running Bianca. File $required_file is missing"
        exit 1
    fi
done

#TODO: Include last version of BIANCA in $FSLDIR

cd $dirT1

#Create an inclusion mask with T1 --> Used to remove GM from BIANCA results
$FSLDIR/bin/make_bianca_mask T1_unbiased.nii.gz T1_fast/T1_brain_pve_0.nii.gz transforms/T1_to_MNI_warp_coef_inv.nii.gz

cd $origDir
mkdir -p $dirT2/lesions

#Move the inclusion mask to T2_FLAIR/lesions directory
mv $dirT1/T1_unbiased_bianca_mask.nii.gz $dirT1/T1_unbiased_ventmask.nii.gz $dirT1/T1_unbiased_brain_mask.nii.gz $dirT2/lesions/

#Generate the configuration file to run Bianca
echo $dirT1/T1_unbiased_brain.nii.gz $dirT2/T2_FLAIR_unbiased.nii.gz $dirT1/transforms/T1_to_MNI_linear.mat > $dirT2/lesions/conf_file.txt;

#Run BIANCA
$FSLDIR/bin/bianca --singlefile=$dirT2/lesions/conf_file.txt --querysubjectnum=1 --brainmaskfeaturenum=1 --loadclassifierdata=$template/bianca_class_data --matfeaturenum=3 --featuresubset=1,2 -o $dirT2/lesions/bianca_mask

#Apply the inclusion mask to BIANCA output to get the final thresholded mask
fslmaths $dirT2/lesions/bianca_mask -mul $dirT2/lesions/T1_unbiased_bianca_mask.nii.gz -thr 0.8 -bin $dirT2/lesions/final_mask

#Get the volume of the lesions
fslstats $dirT2/lesions/final_mask -V | awk '{print $1}' > $dirT2/lesions/volume.txt

