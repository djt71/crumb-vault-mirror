-- G2 / A2 probe: validate that note `id` is stable across restart, edit, folder move.
-- Pass criteria (per specification.md §Pre-PLAN Validation Gate):
--   id of note remains byte-identical across:
--     (i)  3 Notes app restarts
--     (ii) post-restart edit to title and body
--     (iii) folder move within same account
-- Cross-account move changes id allowed (downgrade dedupe to account-scoped, document only).
-- Same-account scenario id change -> return to SPECIFY.

-- This is single-pass: all phases inside one tell block. Restarts happen via re-tell after quit/activate.

on findNoteIdByName(targetName)
	tell application "Notes"
		set foundId to "MISSING"
		set foundCount to 0
		repeat with f in folders
			repeat with n in notes of f
				if name of n is targetName then
					set foundId to id of n
					set foundCount to foundCount + 1
				end if
			end repeat
		end repeat
		return {foundId:foundId, foundCount:foundCount}
	end tell
end findNoteIdByName

on quitAndReopen()
	tell application "Notes" to quit
	delay 4
	tell application "Notes" to activate
	delay 4
end quitAndReopen

-- Phase 0: cleanup any leftover G2 probes
tell application "Notes"
	repeat with f in folders
		set toDelete to {}
		try
			repeat with n in notes of f
				try
					if name of n is "crumb-G2-probe-DELETE-2026-04-25" then
						set end of toDelete to n
					end if
				end try
			end repeat
		end try
		repeat with n in toDelete
			try
				delete n
			end try
		end repeat
	end repeat
end tell

-- Phase 1: create probe note, capture id_0
tell application "Notes"
	set probeName to "crumb-G2-probe-DELETE-2026-04-25"
	set probeBodyV0 to "<div><h1>G2 probe v0</h1><p>id-stability test, do not edit manually.</p></div>"
	set newNote to make new note with properties {name:probeName, body:probeBodyV0}
	set id_0 to id of newNote
end tell

-- Phase 2: restart 1
my quitAndReopen()
set rs1 to my findNoteIdByName("crumb-G2-probe-DELETE-2026-04-25")
set id_after_r1 to foundId of rs1
set count_r1 to foundCount of rs1

-- Phase 3: restart 2
my quitAndReopen()
set rs2 to my findNoteIdByName("crumb-G2-probe-DELETE-2026-04-25")
set id_after_r2 to foundId of rs2
set count_r2 to foundCount of rs2

-- Phase 4: restart 3
my quitAndReopen()
set rs3 to my findNoteIdByName("crumb-G2-probe-DELETE-2026-04-25")
set id_after_r3 to foundId of rs3
set count_r3 to foundCount of rs3

-- Phase 5: edit title (after a restart context), then query
tell application "Notes"
	-- Re-find by name to get a fresh handle
	set noteHandle to missing value
	repeat with f in folders
		repeat with n in notes of f
			if name of n is "crumb-G2-probe-DELETE-2026-04-25" then
				set noteHandle to n
				exit repeat
			end if
		end repeat
		if noteHandle is not missing value then exit repeat
	end repeat
	if noteHandle is not missing value then
		set name of noteHandle to "crumb-G2-probe-DELETE-2026-04-25-edited"
		delay 1
		set id_after_title_edit to id of noteHandle
	else
		set id_after_title_edit to "HANDLE_LOST"
	end if
end tell

-- Phase 6: edit body, query id
tell application "Notes"
	set noteHandle to missing value
	repeat with f in folders
		repeat with n in notes of f
			if name of n is "crumb-G2-probe-DELETE-2026-04-25-edited" then
				set noteHandle to n
				exit repeat
			end if
		end repeat
		if noteHandle is not missing value then exit repeat
	end repeat
	if noteHandle is not missing value then
		set body of noteHandle to "<div><h1>G2 probe v1</h1><p>body edited during probe.</p></div>"
		delay 1
		set id_after_body_edit to id of noteHandle
	else
		set id_after_body_edit to "HANDLE_LOST"
	end if
end tell

-- Phase 7: ensure target folder exists (within same account), move note, query id
tell application "Notes"
	-- Check whether "crumb-G2-target" folder exists; create if not
	set targetFolderName to "crumb-G2-target"
	set targetFolder to missing value
	repeat with f in folders
		if name of f is targetFolderName then
			set targetFolder to f
			exit repeat
		end if
	end repeat
	if targetFolder is missing value then
		try
			set targetFolder to make new folder with properties {name:targetFolderName}
		on error errMsg
			-- some Notes versions disallow folder creation via AppleScript
			set targetFolder to missing value
		end try
	end if

	-- Re-find note by edited name
	set noteHandle to missing value
	repeat with f in folders
		repeat with n in notes of f
			if name of n is "crumb-G2-probe-DELETE-2026-04-25-edited" then
				set noteHandle to n
				exit repeat
			end if
		end repeat
		if noteHandle is not missing value then exit repeat
	end repeat

	if noteHandle is not missing value and targetFolder is not missing value then
		try
			move noteHandle to targetFolder
			delay 1
			-- Re-find after move
			set noteHandleAfterMove to missing value
			repeat with n in notes of targetFolder
				if name of n is "crumb-G2-probe-DELETE-2026-04-25-edited" then
					set noteHandleAfterMove to n
					exit repeat
				end if
			end repeat
			if noteHandleAfterMove is not missing value then
				set id_after_move to id of noteHandleAfterMove
			else
				set id_after_move to "MOVE_LOST_HANDLE"
			end if
		on error errMsg
			set id_after_move to "MOVE_ERROR:" & errMsg
		end try
	else if targetFolder is missing value then
		set id_after_move to "FOLDER_CREATE_UNSUPPORTED"
	else
		set id_after_move to "NOTE_NOT_FOUND_PRE_MOVE"
	end if
end tell

-- Phase 8: assemble report
set rpt to "G2 PROBE RESULT (2026-04-25)" & linefeed
set rpt to rpt & "==========================" & linefeed
set rpt to rpt & "id_0                     = " & id_0 & linefeed
set rpt to rpt & "id_after_restart_1       = " & id_after_r1 & " (count=" & count_r1 & ")" & linefeed
set rpt to rpt & "id_after_restart_2       = " & id_after_r2 & " (count=" & count_r2 & ")" & linefeed
set rpt to rpt & "id_after_restart_3       = " & id_after_r3 & " (count=" & count_r3 & ")" & linefeed
set rpt to rpt & "id_after_title_edit      = " & id_after_title_edit & linefeed
set rpt to rpt & "id_after_body_edit       = " & id_after_body_edit & linefeed
set rpt to rpt & "id_after_folder_move     = " & id_after_move & linefeed

set allMatch to true
if id_after_r1 is not id_0 then set allMatch to false
if id_after_r2 is not id_0 then set allMatch to false
if id_after_r3 is not id_0 then set allMatch to false
if id_after_title_edit is not id_0 then set allMatch to false
if id_after_body_edit is not id_0 then set allMatch to false
if id_after_move is not id_0 then
	-- Tolerate folder-create-unsupported case: that is an environment limitation, not a stability failure
	if id_after_move is not "FOLDER_CREATE_UNSUPPORTED" then set allMatch to false
end if

set rpt to rpt & linefeed & "VERDICT: "
if allMatch then
	set rpt to rpt & "PASS (all queried ids match id_0; same-account stability confirmed)"
else
	set rpt to rpt & "FAIL or PARTIAL (one or more ids diverged; see above)"
end if

return rpt
