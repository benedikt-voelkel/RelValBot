#!/bin/bash

#
# A example workflow MC->RECO->AOD for a simple pp min bias 
# production
#

# if things don't work or if there is any weird CCDB issue try
# alien.py token-init
# before you run this script

# make sure O2DPG + O2 is loaded
[ ! "${O2DPG_ROOT}" ] && echo "Error: This needs O2DPG loaded" && exit 1
[ ! "${O2_ROOT}" ] && echo "Error: This needs O2 loaded" && exit 1

# ALSO MAKE SURE TO HAVE A VALID ALIEN TOKEN

# ----------- SETUP LOCAL CCDB CACHE --------------------------
export ALICEO2_CCDB_LOCALCACHE=$PWD/.ccdb

# ----------- START ACTUAL JOB  ----------------------------- 

NWORKERS=${NWORKERS:-8}
MODULES="--skipModules ZDC"
SIMENGINE=${SIMENGINE:-TGeant4}

# create a simulation workflow
#   5 timeframes, each with 100 pp events @ eCM=14 TeV
#   contains the description of the topology to start from event generation/detector simulation up to AOD production
#   includes description for analysis and QC tasks
#   8 workers for the detector simulation
#   run number 302000
#   possible to choose a seed for the event generation
#   possible to define the interaction diamond
${O2DPG_ROOT}/MC/bin/o2dpg_sim_workflow.py -eCM 14000 -gen pythia8pp -tf 5 -ns 100 -e TGeant4 -j 8 -run 302000 --include-qc --include-analysis # -seed 624 -confKey "Diamond.width[2]=6"


# run simulation workflow
#  this specifies the "target task" (-tt aod) up to where the workflow should be executed. Only necessary tasks are executed to reach that point. No QC or analysis is executed at this point
#  possible to choose number of maximum CPUs to be utilised and maximum RAM to be considered available (in MB)
${O2DPG_ROOT}/MC/bin/o2_dpg_workflow_runner.py -f workflow.json -tt aod # --cpu-limit 32 --mem-limit 12000
# Reruns from a given task
#${O2DPG_ROOT}/MC/bin/o2_dpg_workflow_runner.py -f workflow.json -tt aod --rerun-from itsdigi # --cpu-limit 32 --mem-limit 12000


if [ "$?" = "0" ]; then
  # do QC tasks
  #  if everithing went through before, the QC tasks (--target-labels QC) can be run on top of the previous simulation output
  #  again, CPU and memory can be set
  ${O2DPG_ROOT}/MC/bin/o2_dpg_workflow_runner.py -f workflow.json --target-labels QC # --cpu-limit 32 --mem-limit 12000
else
  echo "ERROR: There was a problem with the simulation"
fi
