#!/usr/bin/osascript

#
# Get Playing Song
# ScriptFilter-GetPlayingSong.applescript
#
# Looks up current song playing in iTunes if playing and returns contextual command information about it to Alfred's Script Filter like _Love_ or _Don't love_ _“Current Song Name” by Artist_ depending whether the song is already loved or not.
#
# Created by Chris White on 7/4/2018
# License: MIT License / https://opensource.org/licenses/MIT
#



# Functions

(* getTrackInfo() Get iTunes track information

Check if iTunes track is playing and generate query for Alfred's string filter, if not generate a failure messege.

- `workflowPath`:  string  Path to workflow script directory or script location if not run from Alfred workflow.
- `return`:        string  JSON string for query

*)
on getTrackInfo(workflowPath)
	
	tell application "iTunes"
		if player state is playing then
			
			-- Set name and artist
			set currentTrackInfo to "“" & name of current track & "” by " & artist of current track
			set currentTrackName to name of current track
			
			-- Set command and loved status
			if loved of the current track is true then
				set command to "Don't love " & currentTrackInfo
				set lovedStatus to "loved ♥"
				set icon to "loved"
			else
				set command to "Love " & currentTrackInfo
				if disliked of current track is false then
					set lovedStatus to "not loved ♡"
					set icon to "unloved"
				else
					set lovedStatus to "disliked ⚠"
					set icon to "disliked"
				end if
			end if
			
			-- Set rating
			set ratingStatus to rating of current track
			if ratingStatus is 0 then
				set ratingStatus to "not yet rated"
			else if ratingStatus is 10 then
				set ratingStatus to "½☆☆☆☆"
			else if ratingStatus is 20 then
				set ratingStatus to "★☆☆☆☆"
			else if ratingStatus is 30 then
				set ratingStatus to "★½☆☆☆"
			else if ratingStatus is 40 then
				set ratingStatus to "★★☆☆☆"
			else if ratingStatus is 50 then
				set ratingStatus to "★★½☆☆"
			else if ratingStatus is 60 then
				set ratingStatus to "★★★☆☆"
			else if ratingStatus is 70 then
				set ratingStatus to "★★★½☆"
			else if ratingStatus is 80 then
				set ratingStatus to "★★★★☆"
			else if ratingStatus is 90 then
				set ratingStatus to "★★★★½"
			else if ratingStatus is 100 then
				set ratingStatus to "★★★★★"
			end if
			
			-- Construct context
			set context to "“" & currentTrackName & "” / " & lovedStatus & " / " & ratingStatus
			
			-- Construct icon path
			set iconPath to workflowPath & "/icons/" & icon & ".png"
			
			return my generateQuery(command, context, context, true, iconPath)
			
		else
			
			-- Construct icon path
			set iconPath to workflowPath & "/icons/notplaying.png"
			return my generateFailure("No track is currently playing", "You need to play a song before you can love it", iconPath)
			
		end if
	end tell
end getTrackInfo


(* generateFailure() Generate failure query

Function to generate a query for a failure including title, subtitle and setting valid to false.

- `failure`:  string  Sets the title, copy and large text to failure messege
- `context`:  string  Provide additional context as the subtitle.
- `icon`:     string  Path to icon or `missing value` to omit icon.
- `return`:   string  JSON string for query

*)
on generateFailure(failure, context, icon)
	
	return generateQuery(failure, context, failure, false, icon)
	
end generateFailure


(* generateQuery() Generate JSON query

Generates the JSON string required to provide result for Alfred's string filter.

There are better ways to generate JSON via AppleScript but given that we aren't doing anything beyond a few short lines for this workflow we're doing it manually.

- `title`:     string   The title text for item, if success the action, “song name” and artist name.
- `subtitle`:  string   The subtitle text for item, if success the song name and loved status.
- `info`:      string   The info text to be used for the item's copy and large-type options, if success the “song name” and artist.
- `valid`:     boolean  Indicate whether a current song was returned or not.
- `icon`:      string   Path to icon or `missing value` to omit icon.
- `return`:    string   JSON string for query.

*)
on generateQuery(title, subtitle, info, valid, iconPath)
	
	set query to "{
	\"items\": [
		{
			\"uid\": \"love\",
			\"type\": \"default\",
			\"autocomplete\": \"love\",
			"
	set query to query & "\"title\": \"" & title & "\",
			"
	set query to query & "\"subtitle\": \"" & subtitle & "\",
			"
	set query to query & "\"valid\": " & valid & ",
			"
	set query to query & "\"copy\": \"" & info & "\",
			"
	set query to query & "\"largetype\": \"" & info & "\",
		"
	if iconPath is not missing value then
		set query to query & "	\"icon\": {
				"
		set query to query & "\"path\": \"" & iconPath & "\"
			"
		set query to query & "},
		"
	end if
	set query to query & "}
	]
}"
	return query
end generateQuery



# Run

(* run() Script Filter Function


The function actually run by Alfred's Script Filter.


- `argv`:    argument  List of string arguments passed by Alfred via the osascript shell command. For this function, we don't do anything with it.
- `return`:  string    JSON string for query


*)
on run argv
	
	-- Get workflow path, if the script isn't run from an Alfred workflow then get the script's parent folder path instead for running in another environment such as Script Editor.
	set pwd to (do shell script "pwd")
	if pwd is not "/" then
		set workflowPath to pwd
	else
		set workflowPath to text 1 through -2 of (POSIX path of ((path to me as text) & "::"))
	end if
	
	-- Check if iTunes is running
	if application "iTunes" is running then
		set query to getTrackInfo(workflowPath)
	else
		-- Construct icon path
		set iconPath to workflowPath & "/icons/notplaying.png"
		set query to generateFailure("iTunes isn't currently running", "Please launch iTunes and start playing a song", iconPath)
	end if
	return query
end run