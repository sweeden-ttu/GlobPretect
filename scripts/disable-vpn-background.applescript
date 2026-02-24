-- disable-vpn-background.applescript
-- Disables the three Palo Alto Networks "Allow in the Background" items in
-- System Settings > General > Login Items to turn off the VPN running in background.
-- Accepts one of the 20 context keys as first argument. Decision: only run when key starts with "owner_" (macOS).
-- Use with macOS Shortcuts for a one-tap "Disable VPN" shortcut.
-- Usage: osascript disable-vpn-background.applescript [owner_hpcc_granite]

on run argv
	set contextKey to ""
	if (count of argv) > 0 then
		set contextKey to item 1 of argv
	end if
	if contextKey is not "" and not (contextKey starts with "owner_") then
		display alert "VPN (macOS only)" message "Context key «" & contextKey & "» is not owner_* (macOS). Disable VPN is only for owner keys. No-op." as warning
		return
	end if
	set success to false
	try
		-- Open System Settings to Login Items (General > Login Items)
		-- Use correct URL scheme (dot, not hyphen) to avoid -10814 (kLSApplicationNotFoundErr)
		try
			open location "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
		on error errMsg number errNum
			if errNum is -10814 then
				do shell script "open \"x-apple.systempreferences:com.apple.LoginItems-Settings.extension\""
			else
				error errMsg number errNum
			end if
		end try
		delay 3
		
		tell application "System Events"
			tell process "System Settings"
				set frontmost to true
				-- Wait for window
				set winCount to 0
				repeat until (count of windows) > 0 or winCount > 10
					delay 0.5
					set winCount to winCount + 1
				end repeat
				if (count of windows) is 0 then
					display alert "Disable VPN Background" message "Could not open Login Items. Open System Settings > General > Login Items manually, then run this shortcut again." as warning
					return
				end if
				
				set toggleCount to 0
				set maxPaloAltoItems to 3
				set matchStrings to {"Palo Alto", "Palo", "GlobalProtect", "Global Protect", "PanGP", "PAN"}
				
				-- Collect checkboxes from window and from nested scroll areas, groups, tables
				set allCheckboxes to {}
				try
					set allCheckboxes to allCheckboxes & (every checkbox of window 1)
				end try
				try
					repeat with g in (every group of window 1)
						set allCheckboxes to allCheckboxes & (every checkbox of g)
					end repeat
				end try
				try
					repeat with s in (every scroll area of window 1)
						set allCheckboxes to allCheckboxes & (every checkbox of s)
					end repeat
				end try
				try
					repeat with s in (every scroll area of window 1)
						repeat with g in (every group of s)
							set allCheckboxes to allCheckboxes & (every checkbox of g)
						end repeat
					end repeat
				end try
				try
					repeat with s in (every scroll area of window 1)
						repeat with t in (every table of s)
							set allCheckboxes to allCheckboxes & (every checkbox of t)
						end repeat
					end repeat
				end try
				try
					repeat with s in (every scroll area of window 1)
						repeat with o in (every outline of s)
							repeat with r in (every row of o)
								try
									set allCheckboxes to allCheckboxes & (every checkbox of r)
								end try
							end repeat
						end repeat
					end repeat
				end try
				
				-- Disable checkboxes that match Palo Alto / GlobalProtect
				repeat with cb in allCheckboxes
					if toggleCount ≥ maxPaloAltoItems then exit repeat
					try
						set desc to ""
						set nm to ""
						try
							set desc to description of cb
						end try
						try
							set nm to name of cb
						end try
						set isMatch to false
						repeat with matchStr in matchStrings
							if (desc contains matchStr) or (nm contains matchStr) then
								set isMatch to true
								exit repeat
							end if
						end repeat
						if isMatch and (value of cb is 1) then
							click cb
							set toggleCount to toggleCount + 1
							delay 0.4
						end if
					end try
				end repeat
				
				-- Fallback: disable last three checked checkboxes (Background section at bottom)
				if toggleCount is 0 and (count of allCheckboxes) > 0 then
					set checkedIndexes to {}
					repeat with i from 1 to (count of allCheckboxes)
						try
							if value of (item i of allCheckboxes) is 1 then
								set end of checkedIndexes to i
							end if
						end try
					end repeat
					set startIdx to (count of checkedIndexes) - maxPaloAltoItems + 1
					if startIdx < 1 then set startIdx to 1
					repeat with j from startIdx to (count of checkedIndexes)
						if toggleCount ≥ maxPaloAltoItems then exit repeat
						try
							set idx to item j of checkedIndexes
							click item idx of allCheckboxes
							set toggleCount to toggleCount + 1
							delay 0.4
						end try
					end repeat
				end if
				
				set success to (toggleCount > 0)
			end tell
		end tell
		
		if success then
			display notification "Palo Alto Networks background items disabled. VPN background off." with title "VPN Disabled"
		else
			display alert "Disable VPN Background" message "Could not find Palo Alto toggles. Open System Settings > General > Login Items, scroll to \"Allow in the Background\", and disable the three Palo Alto Networks items manually." as warning
		end if
		
	on error errMsg number errNum
		display alert "Disable VPN Background" message "Error: " & errMsg as warning
	end try
end run
