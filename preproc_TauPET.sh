#!/bin/bash 

subj=$1
subjTAR=$2
SUBJECTS_DIR=$3
subjDIR=$4

#####################################preproc for tau###########

#mkdir -p $subjTAR/$subj/tau_bycerebelgm
gtmseg --s $subj --keep-hypo --xcerseg
mri_coreg --s $subj --mov $subjDIR/$subj/MK6240/MK6540raw.nii.gz --reg $subjTAR/$subj/tau_bycerebelgm/toT1.reg.lta --threads 8
mri_gtmpvc --i $subjDIR/$subj/MK6240/MK6540raw.nii.gz --reg $subjTAR/$subj/tau_bycerebelgm/toT1.reg.lta --o $subjTAR/$subj/tau_bycerebelgm --psf 4 --seg gtmseg.mgz --auto-mask 1 0.01 --mgx 0.01 --save-input --rescale 7 8 46 47 --threads 8 --merge-hypos --default-seg-merge --replace 29 24

##vol2surface and to common space
mkdir -p $subjTAR/$subj/tau_bycerebelgm/reg_surf2fsaverage

mri_vol2surf --mov $subjTAR/$subj/tau_bycerebelgm/mgx.ctxgm.nii.gz --ref $SUBJECTS_DIR/$subj/mri/orig.mgz --reg $subjTAR/$subj/tau_bycerebelgm/aux/bbpet2anat.lta  --fwhm 0 --surf-fwhm 0 --hemi lh --projfrac 0.5 --o $subjTAR/$subj/tau_bycerebelgm/lh.mgx.ctxgm.sm00.nii.gz

mri_surf2surf --srcsubject $subj --srcsurfval $subjTAR/$subj/tau_bycerebelgm/lh.mgx.ctxgm.sm00.nii.gz \
                      --trgsubject fsaverage \
                      --trgsurfval $subjTAR/$subj/tau_bycerebelgm/reg_surf2fsaverage/lh.mgx.ctxgm.fsaverage.sm00.nii.gz \
                      --hemi lh

mri_vol2surf --mov $subjTAR/$subj/tau_bycerebelgm/mgx.ctxgm.nii.gz --ref $SUBJECTS_DIR/$subj/mri/orig.mgz --reg $subjTAR/$subj/tau_bycerebelgm/aux/bbpet2anat.lta  --fwhm 0 --surf-fwhm 0 --hemi rh --projfrac 0.5 --o $subjTAR/$subj/tau_bycerebelgm/rh.mgx.ctxgm.sm00.nii.gz

mri_surf2surf --srcsubject $subj --srcsurfval $subjTAR/$subj/tau_bycerebelgm/rh.mgx.ctxgm.sm00.nii.gz \
                      --trgsubject fsaverage \
                      --trgsurfval $subjTAR/$subj/tau_bycerebelgm/reg_surf2fsaverage/rh.mgx.ctxgm.fsaverage.sm00.nii.gz \
                      --hemi rh


