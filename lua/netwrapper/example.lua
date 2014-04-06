--[[--------------------------------------------------------------------------
	File name:
		example.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (copy/modify/distribute freely!)
		
	Changelog:
		- March 9th, 2014:	Created
		- April 5th, 2014:	Added to GitHub
----------------------------------------------------------------------------]]

--[[
	EXAMPLE:
	 
	If you use a round-based gamemode with teams, you might want to network each
	 player's custom team name to it can be drawn in a HUD hook.
	 
	To begin, pick a player you want to network some data with.
	
	If you or someone else is currently on your server, you can use Entity(1) to get a player entity.
	
	To network this player's Team Name, we can do the following:
]]

Entity(1):SetNetVar( "TeamName", "Example Team" )

--[[
	We've just networked the TeamName of this player between the server and any connected clients.
	
	To retrieve the value on either the server or client, do the following:
]]

Entity(1):GetNetVar( "TeamName" )

--[[
	This will return the string, "Example Team".
	
	You can change the type of value stored at the "TeamName" to just about anything:
]]

Entity(1):SetNetVar( "TeamName", Vector(123,123,123) ) -- now it returns a vector

Entity(1):SetNetVar( "TeamName", Color(255,0,0,100) ) -- now a table

Entity(1):SetNetVar( "TeamName", 1000 ) -- now a number

--[[	Questions & Answers
	
	Q: What sort of data can I network with this library?
	
	A: Since this is a wrapper library over the standard net library, all limitations of the net library apply here.
		For example, you can't network functions or user data.
		
		What you CAN network:
			nil
			string
			number
			table
			bool
			entity
			vector
			angle
	
	-----------------------------------------------------------------------------------------------------------------------
	
	Q: How often is the data networked?
	
	A: Every time you use SetNetVar on an entity, the data will be networked to any clients using net messages.
	
	Instead of constantly syncing the data even when the data hasn't changed (like the standard GMod networking libraries do),
	 this will only send out a broadcasted net message when the data changes, theoretically reducing network traffic.
	 
	If you set a value on a player and then change the value 5 minutes later, the data will have been broadcasted only 2 times
	 over the span of the last 5 minutes.
	
	However, this does mean that if you use SetNetVar in a think hook, it will be broadcasting net messages on every think.
	
	As with any other function, be sure to set networked data only as often as you need to. Think hooks should typically be
	 avoided if you plan on networking large amounts of data on large amounts of entities/players.
	
	-----------------------------------------------------------------------------------------------------------------------
	
	Q: What happens when clients connect after the data has already been broadcasted?

	A: When a client fully initalizes on the server (during the InitPostEntity hook), they will send a net message to
	 the server that requests any data that is currently being networked on entities.
	 
	So, if a new player was to connect after we've already been networking Player 1's TeamName, the connecting client will
	 receive the data that was networked on Player 1. Once they've received the value, using Entity(1):GetNetVar( "TeamName" )
	 will return the last networked value we set on them.
	 
	-----------------------------------------------------------------------------------------------------------------------
	 
	Q: What happens to the networked data on a player that disconnected, or an entity that was removed?
	
	A: When a player disconnects or an entity is removed, their state will be changed to NULL in our table that holds
	 all of the entities and values currently being networked. This occurs automatically.
	
	The next time that a player connects and asks the server for all networked entities, the server will loop through
	 all of the entities and remove any NULL references that it finds, including any disconnected players or removed 
	 entities.
	 
	Because of this automatic sanitization of the netwrapper.ents table, you don't have to worry about sending NULL references
	 to your connecting players.
]]