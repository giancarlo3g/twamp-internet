#!/bin/bash

# List of files to check
if [ ! -d ./config ]; then
  mkdir -p ./config
fi


yes | cp ./clab-twamp/ce/A/config/cf3/config.cfg ./config/ce.cfg
yes | cp ./clab-twamp/cpe/A/config/cf3/config.cfg ./config/cpe.cfg
yes | cp ./clab-twamp/agg/A/config/cf3/config.cfg ./config/agg.cfg
yes | cp ./clab-twamp/spe/A/config/cf3/config.cfg ./config/spe.cfg
yes | cp ./clab-twamp/coi-l2/A/config/cf3/config.cfg ./config/coi-l2.cfg
yes | cp ./clab-twamp/coi-l3/A/config/cf3/config.cfg ./config/coi-l3.cfg
yes | cp ./clab-twamp/peering/A/config/cf3/config.cfg ./config/peering.cfg
yes | cp ./clab-twamp/originator/A/config/cf3/config.cfg ./config/originator.cfg
