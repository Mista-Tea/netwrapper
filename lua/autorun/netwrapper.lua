--[[------------------------------------------------------------------------------
	File name:
		autorun.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (copy/modify/distribute freely!)
	
	File description:
		The netwrapper library is a simple wrapper over the net library to provide lightweight 
		 networking without hassle of dealing with raw net messages or using ENTITY:SetNW* functions.
		
		The netwrapper library only networks data on an entity when the data is changed or added with
		 ENTITY:SetNetVar( key, value ) from the server. By broadcasting net messages only when 
		 the data changes, this library has a relatively low impact on network traffic.

		The netwrapper library takes away the hassle of handling net messages directly 
		 by using a single net message to automatically read and write the corresponding 
		 values you are networking. Once these values have been broadcasted, all connected 
		 clients will be able to retrieve the values like you would with the standard networking libraries.
		
		Setting networked values:
			ENTITY:SetNetVar( key, value )
			
		Getting networked values:
			ENTITY:GetNetVar( key, default )
			
		Where 'default' is the default value you would like returned if the key doesn't exist.
		 If default isn't provided and the key doesn't exist, nil will be returned.
		
		[EXAMPLE] To set a networked variable on a connected player, you could
		 do the following on from your server console:
			
			Entity(1):SetNetVar( "TeamName", "Example Team" )
			
		Now the player (Entity(1)) has a networked variable with the key "TeamName" 
		 and the value "Example Team". We can retrieve this value on both the server
		 and client by doing the following:
		
			local teamName = Entity(1):GetNetVar( "TeamName" )
			
		This will return "Example Team". If we were to reassign this value to:
		
			Entity(1):SetNetVar( "TeamName", "Another Example" )
		
		Any subsequent calls to Entity(1):GetNetVar( "TeamName" ) will 
		 return "Another Example".
	
	Changelog:
		- March   9th, 2014:    Created
		- April   5th, 2014:    Added to GitHub
		- April   7th, 2014:    Reworded file description
		- August 15th, 2014:    Added Net Requests
--------------------------------------------------------------------------------]]

print( "[NetWrapper] Initializing netwrapper library" )

local base = "netwrapper/"

if ( SERVER ) then

	-- Server functions
	include( base .. "sv_netwrapper.lua" )

	-- Shared functions
	include( base .. "sh_netwrapper.lua" )

	-- Client functions
	AddCSLuaFile( base .. "cl_netwrapper.lua" )
	
elseif ( CLIENT ) then
	
	-- Shared functions
	include( base .. "sh_netwrapper.lua" )

	-- Client functions
	include( base .. "cl_netwrapper.lua" )
	
end
