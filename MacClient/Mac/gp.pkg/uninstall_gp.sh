#!/bin/sh

is_debug=1
if [[ "$1" ]] &&  [ $1 = "-d" ]; then
    is_debug=1
fi
echo "is_debug=$is_debug"

USER_ID=`id -u`

if [ "$USER_ID" -ne 0 ]; then
    echo "You must be root to run the script. Use sudo $0"
    exit
fi

CONSOLE_USER=`stat -f "%Su" /dev/console`
CONSOLE_HOME=`eval echo ~${CONSOLE_USER}`
run_as_console_user=1
console_user_id=`id -u ${CONSOLE_USER}`
if [ $CONSOLE_USER = "root" ]; then
    run_as_console_user=0
fi

install_dir=/Applications/GlobalProtect.app/Contents/Resources
app_log_dir=/Library/Logs/PaloAltoNetworks/GlobalProtect

mkdir -p "$app_log_dir"

uninstall_log_dir=$app_log_dir/PanGPInstall.log
if [ $is_debug -eq 1 ]; then
    uninstall_log_dir=/var/log/PanGPUninstall.log
fi

exit_code=0
((
    checkSystemExtensionsExisting()
    {
        sudo launchctl list | grep -i "NetworkExtension.com.paloaltonetworks.GlobalProtect.client.extension" | grep -v grep > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            return 0
        else
            systemextensionsctl list | grep "com.paloaltonetworks.GlobalProtect.client.extension" | grep "activated enabled" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                return 0
            fi
        fi
        return 1
    }
    checkAndWaitSystemExtension()
    {
        CC=0
        TT=30
        while [[ CC -lt $TT ]]
        do
            if checkSystemExtensionsExisting; then
                pan_info "GP system extensions is still there"
                sleep 3
            else
                pan_info "GP system extensions has been uninstalled"
                break
            fi
        done
    }

    checkAndWaitProcess()
    {
        if [[ "$2" ]]; then
            T="$2"
        else
            T=5
        fi

        C=0
        while [[ C -lt $T ]] &&
              ( killall -s "$1" >/dev/null 2>/dev/null )
        do
            let C=C+1
            sleep 1
        done

        killall -s $1 >/dev/null 2>/dev/null
        return $?
    }

    pan_info()
    {
        curtime=`date`
        echo $curtime ' ' $1 >> ${uninstall_log_dir}
    }

    curver=`defaults read ${install_dir}/../Info CFBundleShortVersionString`
    echo "\n\n\n"
    pan_info "Uninstalling GlobalProtect version ${curver}, console user ${CONSOLE_USER}, home ${CONSOLE_HOME}"

    pan_info "unloading gp agent"
    if [ $run_as_console_user -eq 1 ]; then
        launchctl bootout gui/$console_user_id /Library/LaunchAgents/com.paloaltonetworks.gp.pangps.plist
        launchctl bootout gui/$console_user_id /Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist
    else
        launchctl remove com.paloaltonetworks.gp.pangps
        launchctl remove com.paloaltonetworks.gp.pangpa
    fi

    pan_info "unloading gp daemon"
    launchctl remove com.paloaltonetworks.gp.pangpsd

    #wait for 15 sec. while PanGPS quits
    if checkAndWaitProcess "PanGPS" 60; then
        pan_info "PanGPS didn't quit within 60 sec. Killing"
        killall -15 PanGPS
        if checkAndWaitProcess "PanGPS" 30; then
            pan_info "PanGPS didn't quit after SIGTERM within 30 sec."
        fi
    fi

    #wait for 5 sec. while GlobalProtect quits
    if checkAndWaitProcess "GlobalProtect" 5; then
        pan_info "GlobalProtect didn't quit within 5 sec. Killing"
        killall -15 GlobalProtect
        if checkAndWaitProcess "GlobalProtect" 5; then
            pan_info "GlobalProtect didn't quit after kill within 5 sec."
        fi
    fi

    ps aux | grep "/Applications/GlobalProtect.app/Contents/Resources/PanGPS" | grep -v grep
    if [ $? -eq 0 ]; then
        pan_info "PanGPS is still running, force exit"
        killall -9 PanGPS
    else
        pan_info "PanGPS has stopped"
    fi

    ps aux | grep "/Applications/GlobalProtect.app/Contents/MacOS/GlobalProtect" | grep -v grep
    if [ $? -eq 0 ]; then
        pan_info "GlobalProtect is still running, force exit"
        killall -9 GlobalProtect
    else
        pan_info "GlobalProtect has stopped"
    fi

    #check if agent and daemon has been removed from launchd
    if [ $run_as_console_user -eq 1 ]; then
        if launchctl print gui/$console_user_id/com.paloaltonetworks.gp.pangps > /dev/null 2>&1; then
            pan_info "pangps agent not be removed"
            exit_code=249
        else
            pan_info "pangps agent has been removed"
        fi
        if launchctl print gui/$console_user_id/com.paloaltonetworks.gp.pangpa > /dev/null 2>&1; then
            pan_info "pangpa agent not be removed"
            exit_code=249
        else
            pan_info "pangpa agent has been removed"
        fi
    fi
    if launchctl print system/com.paloaltonetworks.gp.pangpsd > /dev/null 2>&1; then
        pan_info "pangpsd daemon not be removed"
        exit_code=249
    else
        pan_info "pangpsd agent has been removed"
    fi

    pan_info "Unloading driver"
    ifconfig gpd0 down > /dev/null 2>&1
    kextstat -b com.paloaltonetworks.kext.pangpd | grep com.paloaltonetworks.kext.pangpd | grep -v grep
    if [ $? -eq 0 ]; then
        pan_info "unloading pangpd driver."
        kextunload -b com.paloaltonetworks.kext.pangpd
    fi
    kextstat -b com.paloaltonetworks.GlobalProtect.gpsplit | grep com.paloaltonetworks.GlobalProtect.gpsplit | grep -v grep
    if [ $? -eq 0 ]; then
        pan_info "unloading split tunnel driver"
        kextunload -b com.paloaltonetworks.GlobalProtect.gpsplit
    fi
    kextstat -b com.paloaltonetworks.GlobalProtect.gplock | grep com.paloaltonetworks.GlobalProtect.gplock | grep -v grep
    if [ $? -eq 0 ]; then
        pan_info "unloading enforcer driver"
        kextunload -b com.paloaltonetworks.GlobalProtect.gplock
    fi

    if kextstat -b com.paloaltonetworks.kext.pangpd | grep com.paloaltonetworks.kext.pangpd | grep -v grep; then
        pan_info "unload pangpd kext failed."
        exit_code=250
    fi
    if kextstat -b com.paloaltonetworks.GlobalProtect.gpsplit | grep com.paloaltonetworks.GlobalProtect.gpsplit | grep -v grep; then
        pan_info "unload gpsplit kext failed."
        exit_code=250
    fi
    if kextstat -b com.paloaltonetworks.GlobalProtect.gplock | grep com.paloaltonetworks.GlobalProtect.gplock | grep -v grep; then
        pan_info "unload gplock kext failed."
        exit_code=250
    fi

    pan_info "cleaning up sso"
    cd ${install_dir}
    ./PanGPS -dsso

    pan_info "Cleanup Dynamic Store"
    echo "remove State:/Network/Service/gpd.pan/IPv4" | scutil
    echo "remove State:/Network/Service/gpd.pan/DNS"  | scutil

    pan_info "rm all"
    rm -f "/Library/LaunchAgents/com.paloaltonetworks.gp.pangps.plist"
    rm -f "/Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist"
    rm -f "/Library/LaunchDaemons/com.paloaltonetworks.gp.pangpsd.plist"

    #for 5.2 uninstall system extension
    osver_major=$(sw_vers -productVersion | cut -d'.' -f1)
    osver_minor=$(sw_vers -productVersion | cut -d'.' -f2)
    osver_bugfix=$(sw_vers -productVersion | cut -d'.' -f3)
    if { [ $osver_major -gt 10 ]; } || { { [ $osver_major -eq 10 ]; } && { [ $osver_minor -gt 15 ] || { [ $osver_minor -eq 15 ] && [ $osver_bugfix -ge 4 ]; }; } }; then
        if checkSystemExtensionsExisting; then
            pan_info "start to uninstall globalprotect system extensions"
            systemextensionsctl uninstall PXPZ95SK77 com.paloaltonetworks.GlobalProtect.client.extension
            if [ $? -eq 0 ]; then
                pan_info "globalprotect system extensions uninstalled"
            else
                if checkSystemExtensionsExisting; then
                    pan_info "uninstalling globalprotect system extensions"
                    open /Applications/GlobalProtect.app --args -uninstall-sys-ext
                    sudo launchctl remove NetworkExtension.com.paloaltonetworks.GlobalProtect.client.extension
                    checkAndWaitSystemExtension
                else
                    pan_info "GP system extensions be uninstalled"
                fi
            fi
        else
            pan_info "globalprotect system extensions is not installed"
        fi
    fi

    rm -rf "/Library/Application Support/PaloAltoNetworks/GlobalProtect"
    rm -rf "/Applications/GlobalProtect.app"
    rm -rf "/Applications/GlobalProtect.app.bak"
    rm -rf "/System/Library/Extensions/gplock.kext"
    rm -rf "/Library/Extensions/gplock.kext"
    rm -rf "/Library/Security/SecurityAgentPlugins/gplogin.bundle"
    rm -rf "$CONSOLE_HOME/Library/Group Containers/group.PXPZ95SK77.com.paloaltonetworks.GlobalProtect.client"

    rm -rf /Library/Preferences/com.paloaltonetworks.GlobalProtect*
    rm -rf /Library/Preferences/PanGPS*

    if [ $run_as_console_user -eq 1 ]; then
        pan_info "removing gp user config files in (${CONSOLE_HOME})."
        rm -rf "$CONSOLE_HOME/Library/Application Support/PaloAltoNetworks/GlobalProtect"
        rm -rf "$CONSOLE_HOME"/Library/Preferences/com.paloaltonetworks.GlobalProtect*
        rm -rf "$CONSOLE_HOME"/Library/Preferences/PanGPS*
        #remove password entry from keychain
        security delete-generic-password -l GlobalProtect -s GlobalProtect "${CONSOLE_HOME}/Library/Keychains/login.keychain-db"
    fi

    #clean up staged kext
    if [ -d "/Library/StagedExtensions/Library/Extensions/gplock.kext" ]; then
        pan_info "staged gplock kext is not removed. removing it now."
        kextcache -clear-staging -v 4
    fi

    #10.9 addition to clear system preferences cache
    killall -SIGTERM cfprefsd

    pan_info "uninstall packages from globalprotect"
    for pkg in `pkgutil --pkgs |grep com.paloaltonetworks.globalprotect`
    do
        pkgutil --forget "$pkg"
    done
    rm -rf /Library/Logs/PaloAltoNetworks/GlobalProtect/*
    rm -rf "$CONSOLE_HOME"/Library/Logs/PaloAltoNetworks/GlobalProtect/*
    # Uninstall DEM agent
    if [ -d "/Applications/Palo Alto Networks DEM.app" ] || [ -f "/Library/Application Support/PaloAltoNetworks/DEM/install_token" ]; then
        pan_info "uninstall DEM Agent"
        sh "/Library/Application Support/PaloAltoNetworks/DEM/uninstall_agents.sh" -f
        for dempkg in `pkgutil --pkgs |grep com.paloaltonetworksdem.dem`
        do
            pkgutil --forget "$dempkg"
        done
    fi

    pan_info "Uninstallation finished."
    exit $exit_code
)  2>&1) >> ${uninstall_log_dir}
