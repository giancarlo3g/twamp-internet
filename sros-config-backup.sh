#!/bin/bash

yes | cp ./clab-twamp/ce/tftpboot/config.txt ./config/ce.cfg
yes | cp ./clab-twamp/cpe/tftpboot/config.txt ./config/cpe.cfg
yes | cp ./clab-twamp/agg/tftpboot/config.txt ./config/agg.cfg
yes | cp ./clab-twamp/spe/tftpboot/config.txt ./config/spe.cfg
yes | cp ./clab-twamp/coi-l2/tftpboot/config.txt ./config/coi-l2.cfg
yes | cp ./clab-twamp/coi-l3/tftpboot/config.txt ./config/coi-l3.cfg
yes | cp ./clab-twamp/peering/tftpboot/config.txt ./config/peering.cfg
yes | cp ./clab-twamp/reflector/tftpboot/config.txt ./config/reflector.cfg
