#!/bin/bash 

subj=$1
subjTAR=$2
SUBJECTS_DIR=$3
subjDIR=$4

#####################################preproc for av45###########

##gtmseg, coreg and pvc

mkdir -p $subjTAR/$subj/av45_bycerebelgm
gtmseg --s $subj --keep-hypo --xcerseg
mri_coreg --s $subj --mov $subjDIR/$subj/AV45PET/AV45raw.nii.gz --reg $subjTAR/$subj/av45_bycerebelgm/toT1.reg.lta --threads 8

mri_gtmpvc --i $subjDIR/$subj/AV45PET/AV45raw.nii.gz --reg $subjTAR/$subj/av45_bycerebelgm/toT1.reg.lta --o $subjTAR/$subj/av45_bycerebelgm --psf 4 --seg gtmseg.mgz --auto-mask 1 0.01 --mgx 0.01 --save-input --rescale 7 8 46 47 --threads 8 --merge-hypos --default-seg-merge --replace 29 24

##vol2surface and to common space
mkdir -p $subjTAR/$subj/av45_bycerebelgm/reg_surf2fsaverage

mri_vol2surf --mov $subjTAR/$subj/av45_bycerebelgm/mgx.ctxgm.nii.gz --ref $SUBJECTS_DIR/$subj/mri/orig.mgz --reg $subjTAR/$subj/av45_bycerebelgm/aux/bbpet2anat.lta  --fwhm 0 --surf-fwhm 0 --hemi lh --projfrac 0.5 --o $subjTAR/$subj/av45_bycerebelgm/lh.mgx.ctxgm.sm00.nii.gz
mri_surf2surf --srcsubject $subj --srcsurfval $subjTAR/$subj/av45_bycerebelgm/lh.mgx.ctxgm.sm00.nii.gz \
                      --trgsubject fsaverage \
                      --trgsurfval $subjTAR/$subj/av45_bycerebelgm/reg_surf2fsaverage/lh.mgx.ctxgm.fsaverage.sm00.nii.gz \
                      --hemi lh

mri_vol2surf --mov $subjTAR/$subj/av45_bycerebelgm/mgx.ctxgm.nii.gz --ref $SUBJECTS_DIR/$subj/mri/orig.mgz --reg $subjTAR/$subj/av45_bycerebelgm/aux/bbpet2anat.lta  --fwhm 0 --surf-fwhm 0 --hemi rh --projfrac 0.5 --o $subjTAR/$subj/av45_bycerebelgm/rh.mgx.ctxgm.sm00.nii.gz
mri_surf2surf --srcsubject $subj --srcsurfval $subjTAR/$subj/av45_bycerebelgm/rh.mgx.ctxgm.sm00.nii.gz \
                      --trgsubject fsaverage \
                      --trgsurfval $subjTAR/$subj/av45_bycerebelgm/reg_surf2fsaverage/rh.mgx.ctxgm.fsaverage.sm00.nii.gz \
                      --hemi rh
##vol to common space
mkdir -p $subjTAR/$subj/av45_bycerebelgm/reg_vol2fsaverage
mri_vol2vol --mov $subjTAR/$subj/av45_bycerebelgm/mgx.subctxgm.nii.gz --reg $subjTAR/$subj/av45_bycerebelgm/aux/bbpet2anat.lta --tal --talres 2  --o $subjTAR/$subj/av45_bycerebelgm/reg_vol2fsaverage/subctxgm.mni305.2mm.sm00.nii.gz
cd $subjTAR/$subj/av45_bycerebelgm/reg_vol2fsaverage
mri_fwhm --smooth-only --i subctxgm.mni305.2mm.sm00.nii.gz --fwhm 5 --o subctxgm.mni305.2mm.sm05.nii.gz --mask $FREESURFER_HOME/subjects/fsaverage/mri.2mm/subcort.mask.mgz


# QC check
export QC='/home/binyin/local4t/research/data_wash/RJ_uMR890_forAD/QC_coreg/AV45'
mkdir -p $QC

freeview -viewport z -v $SUBJECTS_DIR/$subj/mri/orig.mgz:name=orig.mgz $subjDIR/$subj/AV45PET/AV45raw.nii.gz:name=AV45raw.nii.gz:reg=$subjTAR/$subj/av45_bycerebelgm/toT1.reg.lta:colormap=NIH:opacity=0.15 --surface $SUBJECTS_DIR/$subj/surf/lh.white:edgecolor=yellow --surface $SUBJECTS_DIR/$subj/surf/lh.white:edgecolor=yellow -slice 90 90 90 -ss $QC/$subj.z.jpg

freeview -viewport y -v $SUBJECTS_DIR/$subj/mri/orig.mgz:name=orig.mgz $subjDIR/$subj/AV45PET/AV45raw.nii.gz:name=AV45raw.nii.gz:reg=$subjTAR/$subj/av45_bycerebelgm/toT1.reg.lta:colormap=NIH:opacity=0.15 --surface $SUBJECTS_DIR/$subj/surf/rh.white:edgecolor=yellow --surface $SUBJECTS_DIR/$subj/surf/rh.white:edgecolor=yellow -slice 90 90 90 -ss $QC/$subj.y.jpg
