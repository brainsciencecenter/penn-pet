#!/bin/bash
# Processes PET data to create SUVR images.
# Follows BIDS PET standard and expects BIDS-format filenames. 
# Note that subject and session labels cannot contain BIDS-incompatible 
# characters like underscores or periods.
# Command-line arguments.

CmdName=$(basename "$0")

function fwenv { source /project/ftdc_misc/software/pkg/miniconda3/bin/activate; conda activate flywheel; }

  TEMP=$(getopt -o dN:no:t:v --long debug,Networkdir:,noop,outdir:,template-dir:,verbose  -n "$CmdName" -- "$@")

  if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

  # Note the quotes around '$TEMP': they are essential!
  eval set -- "$TEMP"

  Debug=false
  Noop=false
  OutDir=
  Verbose=false

  while true; do
    echo "\$1 = '$1'"
    case "$1" in
      -d | --debug) Debug=true; shift 1;;
      -n | --noop) Noop=true; shift 1;;
      -N | --networkdir) NetworkDir=$2; shift 2;;
      -o | --outdir) OutDir=$2; shift 2;;
      -t | --template-dir) TemplateDir=$2; shift 2;;
      -v | --verbose) verbose=true; shift 1;;

      -- ) shift; break ;;
      * ) break ;;
    esac
  done

petName=$1 # Absolute path of BIDS-format, attentuation-corrected dynamic PET image
t1Name=$2 # Absolute path of N4-corrected, skull-on T1 image from ANTsCT output directory

# Record job ID.
# JSP: useful for job monitoring and debugging failed jobs.
[ -n "${LSB_JOBID}" ] && echo "LSB job ID: ${LSB_JOBID}"

scriptdir=`dirname $0` # Location of this script

# Parse command-line arguments to get working directory, subject ID, tracer, and PET/MRI session labels.
petdir=`dirname ${petName}` # PET session input directory
bn=`basename ${petName}`
id=`echo $bn | grep -oE 'sub-[^_]*' | cut -d '-' -f 2` # Subject ID
petsess=`echo $bn | grep -oE 'ses-[^_]*' | cut -d '-' -f 2` # PET session label
trc=`echo $bn | grep -oE 'trc-[^_]*' | cut -d '-' -f 2` # PET tracer name.

outdir="/project/ftdc_pipeline/data/pet/sub-${id}/ses-${petsess}"
if [ -n "$OutDir" ]
then
	outdir="$OutDir"
fi

t1dir=`dirname ${t1Name}`
t1bn=`basename ${t1Name}`
mrisess=`echo $t1bn | grep -oE 'ses-[^_]*' | cut -d '-' -f 2` # MRI session label
wd=${petdir/sub-${id}\/ses-${petsess}} # Subjects directory

# Define session-specific filename variables.
pfx="${outdir}/sub-${id}_ses-${petsess}_trc-${trc}"

# Python environment.
#source /project/ftdc_misc/software/pkg/miniconda3/bin/activate
#conda activate flywheel

if [ -n "$LSB_JOBID" ]
then
    fwenv
fi

# Get label statistics for multiple atlases using QuANTs.
for metricFile in "${pfx}_desc-suvr${mrisess}_pet.nii.gz" "${pfx}_desc-IY${mrisess}_pet.nii.gz" "${pfx}_desc-RVC${mrisess}_pet.nii.gz"; do
    python ${scriptdir}/pet_quants.py -o "$outdir" -N $NetworkDir -t "$TemplateDir" ${metricFile} ${t1dir}
done

# JSP: need to at least make the template directory writeable; otherwise, if the script crashes out, it can't be deleted.
if [ -n "$LSB_JOBID" ]
then
    chgrp -R ftdclpc ${outdir}
    chmod -R 775 ${outdir}
    rm -rf ${outdir}/template
fi

