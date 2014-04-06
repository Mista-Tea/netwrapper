--[[------------------------------------------------------------------------------
	File name:
		autorun.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (copy/modify/distribute freely!)
	
	File description:
		A simple library for networking data on entities between server and client
		with the use of net messages instead of the standard networking libraries.
		
		Where other libraries are constantly networking data even when the data isn't
		changing, this library will only sync the data when the values change.
		
		This should theoretically provide a lightweight networking solution without
		heavy network traffic.
		
		To network a value on an entity, simply use the ENTITY:SetNetVar function.
		
		[EXAMPLE] To set a networked variable on a connected player, you could
		do the following on from your server console:
			
			Entity(1):SetNetVar( "TeamName", "Example Team" )
			
		Now the player (Entity(1)) has a networked variable with the key "TeamName" 
		and the value "Example Team". We can retrieve this value on both the server
		and client by doing the following:
		
			local teamName = Entity(1):GetNetVar( "TeamName" )
			
		This will return "Example Team". If we were to reassign this value to:
		
			Entity(1):SetNetVar( "TeamName", "Another Example" )
		
		Then any subsequent calls to Entity(1):GetNetVar( "TeamName" ) will 
		return "Another Example".
	
	Changelog:
		- March 9th, 2014:	Created
		- April 5th, 2014:	Added to GitHub
--------------------------------------------------------------------------------]]

print( "[NetWrapper] Initializing netwrapper library" )

local base = "netwrapper/"

if ( SERVER ) then

	-- Server functions
	include( base.."server/sv_netwrapper.lua" )

	-- Shared functions
	include( base.."shared/sh_netwrapper.lua" )

	-- Client functions
	AddCSLuaFile( base.."client/cl_netwrapper.lua" )
	
elseif ( CLIENT ) then
	
	-- Shared functions
	include( base.."shared/sh_netwrapper.lua" )

	-- Client functions
	include( base.."client/cl_netwrapper.lua" )
	
end