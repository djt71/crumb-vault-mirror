-- A1/A4 probe v2: cleanup-aware, uses `folder` instead of `container`
-- Designed for obsidian-applenotes-import SPECIFY-phase exit gate.

tell application "Notes"
	set probeBody to "<div><h1>Crumb probe</h1><p>Throwaway note created by obsidian-applenotes-import SPECIFY-phase A1 probe. Safe to delete from Recently Deleted.</p><p>Date: 2026-04-25</p></div>"
	set probeNameTarget to "crumb-probe-DELETE-2026-04-25"

	-- Cleanup: delete any leftover probe notes from prior runs (any folder, by name)
	set cleanedUp to 0
	try
		repeat with f in folders
			set notesToCleanup to {}
			repeat with n in notes of f
				if name of n is probeNameTarget then
					set end of notesToCleanup to n
				end if
			end repeat
			repeat with n in notesToCleanup
				delete n
				set cleanedUp to cleanedUp + 1
			end repeat
		end repeat
	end try

	-- Step 1: create the probe note
	set newNote to make new note with properties {name:probeNameTarget, body:probeBody}
	set probeId to id of newNote

	-- Capture original folder name (defensively)
	set originalFolder to "unknown"
	try
		set originalFolder to name of folder of newNote
	end try

	-- Step 2: verify it exists pre-delete
	set existsBefore to false
	try
		if (exists note id probeId) then set existsBefore to true
	end try

	-- Step 3: delete the probe note via AppleScript
	delete newNote
	delay 2

	-- Step 4: check whether note is queryable by id after delete
	set existsAfterById to false
	try
		if (exists note id probeId) then set existsAfterById to true
	end try

	-- Step 5: enumerate every folder and look for the probe note by name
	set folderNamesAll to ""
	set foundInFolder to "none"
	try
		repeat with f in folders
			set fName to name of f
			if folderNamesAll is "" then
				set folderNamesAll to fName
			else
				set folderNamesAll to folderNamesAll & ", " & fName
			end if
			repeat with n in notes of f
				if name of n is probeNameTarget then
					if foundInFolder is "none" then
						set foundInFolder to fName
					else
						set foundInFolder to foundInFolder & "+" & fName
					end if
				end if
			end repeat
		end repeat
	end try

	-- Step 6: report
	set report to "PRIOR_PROBES_CLEANED=" & cleanedUp & "\n"
	set report to report & "PROBE_ID=" & probeId & "\n"
	set report to report & "PROBE_NAME=" & probeNameTarget & "\n"
	set report to report & "ORIGINAL_FOLDER=" & originalFolder & "\n"
	set report to report & "EXISTS_BY_ID_BEFORE_DELETE=" & existsBefore & "\n"
	set report to report & "EXISTS_BY_ID_AFTER_DELETE=" & existsAfterById & "\n"
	set report to report & "FOUND_AFTER_DELETE_IN_FOLDER=" & foundInFolder & "\n"
	set report to report & "ALL_FOLDERS=" & folderNamesAll & "\n"

	return report
end tell
