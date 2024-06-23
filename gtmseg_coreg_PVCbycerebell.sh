#!/bin/bash 

#20210813 gtmseg all T1 by freesurfer7.1.1
#a total of 48 cases in subjDIR

subj=$1
subjTAR=$2
SUBJECTS_DIR=$3
subjDIR=$4

##gtmseg, coreg and pvc
mkdir -p $subjTAR/$subj/sv2a_bycerebelgm

#gtmseg --s $subj --keep-hypo --xcerseg
#mri_coreg --s $subj --mov $subjDIR/$subj/sv2a/sv2a_raw.nii.gz --reg $subjTAR/$subj/sv2a_bycerebelgm/toT1.reg.lta --threads 6

#mri_gtmpvc --i $subjDIR/$subj/sv2a/sv2a_raw.nii.gz --reg $subjTAR/$subj/sv2a_bycerebelgm/toT1.reg.lta --o $subjTAR/$subj/sv2a_bycerebelgm --psf 4 --seg gtmseg.mgz --auto-mask 1 0.01 --mgx 0.01 --save-input --rescale 7 8 46 47 --threads 6 --merge-hypos --default-seg-merge

##vol2surface and to common space
mkdir -p $subjTAR/$subj/sv2a_bycerebelgm/reg_surf2fsaverage

mri_vol2surf --mov $subjTAR/$subj/sv2a_bycerebelgm/mgx.ctxgm.nii.gz --ref $SUBJECTS_DIR/$subj/mri/orig.mgz --reg $subjTAR/$subj/sv2a_bycerebelgm/aux/bbpet2anat.lta  --fwhm 0 --surf-fwhm 0 --hemi lh --projfrac 0.5 --o $subjTAR/$subj/sv2a_bycerebelgm/lh.mgx.ctxgm.sm00.nii.gz

mri_surf2surf --srcsubject $subj --srcsurfval $subjTAR/$subj/sv2a_bycerebelgm/lh.mgx.ctxgm.sm00.nii.gz \
                      --trgsubject fsaverage \
                      --trgsurfval $subjTAR/$subj/sv2a_bycerebelgm/reg_surf2fsaverage/lh.mgx.ctxgm.fsaverage.sm00.nii.gz \
                      --hemi lh

mri_vol2surf --mov $subjTAR/$subj/sv2a_bycerebelgm/mgx.ctxgm.nii.gz --ref $SUBJECTS_DIR/$subj/mri/orig.mgz --reg $subjTAR/$subj/sv2a_bycerebelgm/aux/bbpet2anat.lta  --fwhm 0 --surf-fwhm 0 --hemi rh --projfrac 0.5 --o $subjTAR/$subj/sv2a_bycerebelgm/rh.mgx.ctxgm.sm00.nii.gz

mri_surf2surf --srcsubject $subj --srcsurfval $subjTAR/$subj/sv2a_bycerebelgm/rh.mgx.ctxgm.sm00.nii.gz \
                      --trgsubject fsaverage \
                      --trgsurfval $subjTAR/$subj/sv2a_bycerebelgm/reg_surf2fsaverage/rh.mgx.ctxgm.fsaverage.sm00.nii.gz \
                      --hemi rh

# QC check
#export QC='/home/binyin/local4t/research/data_wash/RJ_uMR890_forAD/QC_coreg/'
#mkdir -p $QC

#freeview -viewport z -v $SUBJECTS_DIR/$subj/mri/orig.mgz:name=orig.mgz $subjDIR/$subj/sv2a/sv2a_raw.nii.gz:name=sv2a_raw.nii.gz:reg=$subjTAR/$subj/sv2a_bycerebelgm/toT1.reg.lta:colormap=NIH:opacity=0.15 --surface $SUBJECTS_DIR/$subj/surf/lh.white:edgecolor=yellow --surface $SUBJECTS_DIR/$subj/surf/lh.white:edgecolor=yellow -slice 90 90 90 -ss $QC/$subj.z.jpg

#freeview -viewport y -v $SUBJECTS_DIR/$subj/mri/orig.mgz:name=orig.mgz $subjDIR/$subj/sv2a/sv2a_raw.nii.gz:name=sv2a_raw.nii.gz:reg=$subjTAR/$subj/sv2a_bycerebelgm/toT1.reg.lta:colormap=NIH:opacity=0.15 --surface $SUBJECTS_DIR/$subj/surf/rh.white:edgecolor=yellow --surface $SUBJECTS_DIR/$subj/surf/rh.white:edgecolor=yellow -slice 90 90 90 -ss $QC/$subj.y.jpg



