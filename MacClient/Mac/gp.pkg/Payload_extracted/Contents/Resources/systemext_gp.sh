#!/bin/sh

out_dir="/Library/Logs/PaloAltoNetworks/GlobalProtect"

pan_info()
{
    curtime=`date`
    echo $curtime " " $1 >> ${out_dir}/PanGPInstall.log
}
pan_info "Install system extensions after installation"
sudo mkdir -p "/Library/Application Support/PaloAltoNetworks/GlobalProtect"
sudo touch "/Library/Application Support/PaloAltoNetworks/GlobalProtect/install_system_extensions.now"


