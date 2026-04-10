#!/usr/bin/env bash
# apple-snapshot.sh — Dump Apple Reminders, Calendar, and Notes to shared files
#
# Runs as danny via LaunchAgent in danny's GUI bootstrap domain.
# TCC grants carry within the user's bootstrap context.
# Fires every 30 min during waking hours (6:50–23:00 ET).
# Output consumed by morning briefing, session prep, and meeting prep.
#
# Sources:
#   tess-operations apple-services-spec §2.3, §3.2
#   tess-operations tasks.md TOP-028, TOP-033

set -eu

# Waking hours gate (6–23 ET). LaunchAgent fires every 30 min;
# skip silently outside this window.
HOUR=$(date +%-H)
if [ "$HOUR" -lt 6 ] || [ "$HOUR" -ge 23 ]; then
  exit 0
fi

readonly STATE_DIR="/Users/tess/crumb-vault/_openclaw/state"
readonly TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Reminders: today + overdue
reminders_today=$(/opt/homebrew/bin/remindctl show today --json 2>&1) || reminders_today='{"error":"remindctl failed"}'
reminders_overdue=$(/opt/homebrew/bin/remindctl show overdue --json 2>&1) || reminders_overdue='{"error":"remindctl failed"}'

cat > "$STATE_DIR/apple-reminders.json" <<EOF
{
  "snapshot_at": "$TIMESTAMP",
  "today": $reminders_today,
  "overdue": $reminders_overdue
}
EOF

# Calendar: today's events
calendar_today=$(/opt/homebrew/bin/icalBuddy -f -nc -nrd eventsToday 2>&1 | sed 's/\x1b\[[0-9;]*m//g') || calendar_today="error: icalBuddy failed"

cat > "$STATE_DIR/apple-calendar.txt" <<EOF
snapshot_at: $TIMESTAMP
---
$calendar_today
EOF

# Notes: "Tess" folder (follow-up items placed by operator)
# Single osascript call with delimiters, parsed to JSON by python3.
# If folder doesn't exist yet, writes empty array gracefully.
notes_raw=$(osascript << 'APPLESCRIPT'
tell application "Notes"
  try
    set tessFolder to folder "Tess"
    set noteList to notes of tessFolder
    if (count of noteList) is 0 then
      return ""
    end if
    set output to ""
    repeat with n in noteList
      set noteTitle to name of n
      set noteBody to plaintext of n
      set modDate to modification date of n
      -- Format date as ISO-ish: YYYY-MM-DD HH:MM:SS
      set y to year of modDate
      set m to (month of modDate as integer)
      set d to day of modDate
      set dateStr to (y as string) & "-" & text -2 thru -1 of ("0" & (m as string)) & "-" & text -2 thru -1 of ("0" & (d as string))
      set output to output & "<<<NOTE_START>>>" & noteTitle & "<<<NOTE_SEP>>>" & dateStr & "<<<NOTE_SEP>>>" & noteBody & "<<<NOTE_END>>>"
    end repeat
    return output
  on error errMsg
    return "<<<ERROR>>>" & errMsg
  end try
end tell
APPLESCRIPT
) || notes_raw="<<<ERROR>>>osascript failed"

if [[ "$notes_raw" == "<<<ERROR>>>"* ]]; then
  err_msg="${notes_raw#<<<ERROR>>>}"
  # "Tess" folder not found is expected before operator creates it
  if echo "$err_msg" | grep -qi "can.t get folder"; then
    printf '{"snapshot_at":"%s","notes":[],"note":"Tess folder not yet created in Notes.app"}\n' "$TIMESTAMP" \
      > "$STATE_DIR/apple-notes-tess.json"
  else
    printf '{"snapshot_at":"%s","notes":[],"error":"%s"}\n' "$TIMESTAMP" "$err_msg" \
      > "$STATE_DIR/apple-notes-tess.json"
  fi
elif [[ -z "$notes_raw" ]]; then
  printf '{"snapshot_at":"%s","notes":[]}\n' "$TIMESTAMP" \
    > "$STATE_DIR/apple-notes-tess.json"
else
  echo "$notes_raw" | python3 -c "
import sys, json
raw = sys.stdin.read()
ts = '$TIMESTAMP'
notes = []
for chunk in raw.split('<<<NOTE_START>>>'):
    parts = chunk.split('<<<NOTE_SEP>>>')
    if len(parts) < 3:
        continue
    title = parts[0]
    modified = parts[1]
    body = parts[2].replace('<<<NOTE_END>>>', '').strip()
    notes.append({'title': title, 'modified': modified, 'body': body})
print(json.dumps({'snapshot_at': ts, 'notes': notes}, indent=2, ensure_ascii=False))
" > "$STATE_DIR/apple-notes-tess.json"
fi

chmod 644 "$STATE_DIR/apple-reminders.json" "$STATE_DIR/apple-calendar.txt" "$STATE_DIR/apple-notes-tess.json" 2>/dev/null
