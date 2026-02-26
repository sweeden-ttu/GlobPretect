#!/bin/sh

# Define constants
readonly LOG_DIR="${HOME}/Library/Logs/PaloAltoNetworks/GlobalProtect"
readonly GLOBAL_LOG_DIR="/Library/Logs/PaloAltoNetworks/GlobalProtect"
readonly DEM_LOG_DIR="/Library/Logs/PaloAltoNetworks/DEM"

# Validate input
if [ $# -ne 1 ] || [ -z "$1" ]; then
    echo "Usage: $0 <output_directory>"
    exit 1
fi

output_dir="$1"
tmpdir=$(mktemp -d "${output_dir}/.gp_XXXXXX")

# Function to safely copy files
safe_copy() {
    source_dir="$1"
    dest_dir="$2"
    pattern="$3"

    find "${source_dir}" -name "${pattern}" -type f -print0 | xargs -0 -I {} cp -f {} "${dest_dir}" || echo "Warning: Failed to copy some files matching ${pattern} from ${source_dir} to ${dest_dir}"
}

# Collect system information
system_profiler -detailLevel mini SPHardwareDataType > "${tmpdir}/SystemInfo.txt"
system_profiler SPSoftwareDataType SPNetworkDataType >> "${tmpdir}/SystemInfo.txt"

# Collect network information
netstat -avn > "${tmpdir}/NetStat.txt"
netstat -rn > "${tmpdir}/RoutePrint.txt"
ifconfig > "${tmpdir}/IfConfig.txt"

# Collect machine state
{
    w
    df -k
    ps axu
    kextstat
    launchctl list
    last
    sysctl -a
    ping -t 4 -c 3 www.google.com
    ping -t 4 -c 3 www.paloaltonetworks.com
} > "${tmpdir}/MachineState.txt"

# Collect DNS and proxy information
scutil --dns > "${tmpdir}/DNS.txt"
scutil --proxy > "${tmpdir}/Proxy.txt"

# Collect system extension information
systemextensionsctl list > "${tmpdir}/systemextensionsctl.txt"

# Collect network extension logs
log show --last 8h --predicate 'subsystem == "com.apple.networkextension"' --info --debug > "${tmpdir}/networkextension.txt"

# Collect top information
/usr/bin/top -S -n0 -l2 > "${tmpdir}/Top.txt"

# Copy log files
for log_file in \
    "${LOG_DIR}/PanGPA.log" \
    "${LOG_DIR}/hip_remediation_script.log" \
    "${LOG_DIR}/PanGPA.log.old" \
    "${GLOBAL_LOG_DIR}/PanGPS.log" \
    "${GLOBAL_LOG_DIR}/PanGPS.log.old" \
    "${GLOBAL_LOG_DIR}/PanProxyAgent.log" \
    "${GLOBAL_LOG_DIR}/PanProxyAgent.1.log" \
    "${GLOBAL_LOG_DIR}/PanNExt.log" \
    "${GLOBAL_LOG_DIR}/PanNExt.log.old" \
    "${GLOBAL_LOG_DIR}/gplogin.log" \
    "${GLOBAL_LOG_DIR}/gplogin.log.old" \
    "${GLOBAL_LOG_DIR}/PanGpHip.log" \
    "${GLOBAL_LOG_DIR}/PanGpHip.log.old" \
    "${GLOBAL_LOG_DIR}/PanGpHipMp.log" \
    "${GLOBAL_LOG_DIR}/PanGpHipMp.log.old" \
    "${GLOBAL_LOG_DIR}/debug_drv.log" \
    "${GLOBAL_LOG_DIR}/debug_drv_old.log" \
    "${GLOBAL_LOG_DIR}/PanGPInstall.log" \
    "${GLOBAL_LOG_DIR}/pan_gp_event.log" \
    "${GLOBAL_LOG_DIR}/pan_gp_event.log.old" \
    "${GLOBAL_LOG_DIR}/sysext.service.log" \
    "${GLOBAL_LOG_DIR}/pan_gp_hrpt.xml"
do
    cp -f "${log_file}" "${tmpdir}/" || true
done

# Copy diagnostic reports
for dir in "/Library/Logs/DiagnosticReports" "${HOME}/Library/Logs/DiagnosticReports"; do
    safe_copy "${dir}" "${tmpdir}" "PanGPS*.crash"
    safe_copy "${dir}" "${tmpdir}" "PanGPS*.ips"
    safe_copy "${dir}" "${tmpdir}" "PanGpHip*.crash"
    safe_copy "${dir}" "${tmpdir}" "PanGpHip*.ips"
    safe_copy "${dir}" "${tmpdir}" "PanGpHipMp*.crash"
    safe_copy "${dir}" "${tmpdir}" "PanGpHipMp*.ips"
    safe_copy "${dir}" "${tmpdir}" "com.paloaltonetworks.GlobalProtect.client*.crash"
    safe_copy "${dir}" "${tmpdir}" "com.paloaltonetworks.GlobalProtect.client*.ips"
    safe_copy "${dir}" "${tmpdir}" "*panic*"
    safe_copy "${dir}" "${tmpdir}" "DemPortalService*.crash"
    safe_copy "${dir}" "${tmpdir}" "DemPortalService*.ips"
    safe_copy "${dir}" "${tmpdir}" "DemNetworkTestService*.crash"
    safe_copy "${dir}" "${tmpdir}" "DemNetworkTestService*.ips"
    safe_copy "${dir}" "${tmpdir}" "DemPathTestService*.crash"
    safe_copy "${dir}" "${tmpdir}" "DemPathTestService*.ips"
    safe_copy "${dir}" "${tmpdir}" "DemCollectionService*.crash"
    safe_copy "${dir}" "${tmpdir}" "DemCollectionService*.ips"
    safe_copy "${dir}" "${tmpdir}" "DemTransmissionService*.crash"
    safe_copy "${dir}" "${tmpdir}" "DemTransmissionService*.ips"
    safe_copy "${dir}" "${tmpdir}" "DemUpdateService*.crash"
    safe_copy "${dir}" "${tmpdir}" "DemUpdateService*.ips"
    safe_copy "${dir}" "${tmpdir}" "DemWebTestService*.crash"
    safe_copy "${dir}" "${tmpdir}" "DemWebTestService*.ips"
done

# Copy additional logs
safe_copy "${GLOBAL_LOG_DIR}" "${tmpdir}" "gpsplit.*"
safe_copy "${GLOBAL_LOG_DIR}" "${tmpdir}" "pan_gp_diag*"
safe_copy "${GLOBAL_LOG_DIR}" "${tmpdir}" "pan_gp_trb*"
safe_copy "/var/log" "${tmpdir}" "kernel.log*"
safe_copy "/var/log" "${tmpdir}" "system.log*"
safe_copy "${DEM_LOG_DIR}" "${tmpdir}" "com.paloaltonetworks.Dem*"

# Copy specific files
cp -f /var/log/PanGPUninstall.log "${tmpdir}/PanGPUninstall.log" || true
cp -f /Library/Preferences/com.paloaltonetworks.GlobalProtect.settings.plist "${tmpdir}/" || true
cp -f "/Library/Application Support/PaloAltoNetworks/GlobalProtect/PXYSettings.plist" "${tmpdir}/" || true

# Create archive
(cd "${tmpdir}" && tar czf "${output_dir}/GlobalProtect_Logs.tgz" .)

# Clean up
cd "${output_dir}" || exit
rm -rf "${tmpdir}"

echo "The support file is saved to ${output_dir}/GlobalProtect_Logs.tgz"