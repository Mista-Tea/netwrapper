--[[--------------------------------------------------------------------------
	File name:
		sv_netwrapper.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (copy/modify/distribute freely!)
			
	Changelog:
		- March 9th, 2014:	Created
		- April 5th, 2014:	Added to GitHub
----------------------------------------------------------------------------]]

--[[--------------------------------------------------------------------------
--		Namespace Tables 
--------------------------------------------------------------------------]]--

netwrapper      = netwrapper      or {}
netwrapper.ents = netwrapper.ents or {}

--[[--------------------------------------------------------------------------
--		Localized Functions 
--------------------------------------------------------------------------]]--

local net     = net
local util    = util
local ipairs  = ipairs
local IsValid = IsValid

--[[--------------------------------------------------------------------------
--		Namespace Functions
--------------------------------------------------------------------------]]--

util.AddNetworkString( "NetWrapper" )
util.AddNetworkString( "NetWrapperSyncEntity" )

--[[--------------------------------------------------------------------------
--
--	Net - NetWrapper
--
--	Received when a player fully initializes with the InitPostEntity hook.
--	 This will sync all currently networked entities to the client.
--]]--
net.Receive( "NetWrapper", function( len, ply )
	netwrapper.SyncClient( ply )
end )

--[[--------------------------------------------------------------------------
--
--	Net - NetWrapperSyncEntity( entity )
--
--	Received when an entity is created on the client.
--	 This will attempt to find any networked data on the given entity
--	 and sync it back to the client.
--]]--
net.Receive( "NetWrapperSyncEntity", function( len, ply )
	local ent = net.ReadEntity()
	
	local vars = netwrapper.GetNetVars( ent )
	if ( !vars ) then return; end
	
	for key, val in pairs( vars ) do
		netwrapper.SendNetVar( ply, ent, key, val )
	end
end )

--[[--------------------------------------------------------------------------
--
--	netwrapper.SyncClient( player )
--
--	Loops through every entity currently networked and sends the networked
--	 data to the client.
--
--	While looping, any NULL entities (disconnected players, removed entities) 
--	 will automatically be removed from the table.
--]]--
function netwrapper.SyncClient( ply )
	for ent, values in ipairs( netwrapper.ents ) do
		if ( !IsValid( ent ) ) then netwrapper.ents[ ent ] = nil continue; end
		
		for key, value in ipairs( values ) do
			if ( IsEntity( value ) and !value:IsValid() ) then netwrapper.ents[ ent ][ key ] = nil continue; end
			
			netwrapper.SendNetVar( ply, ent, key, value )
		end			
	end
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.BroadcastNetVar( entity, string, * )
--
--	Broadcasts a net message to all connected clients that contains the
--	 key/value pair to assign on the given entity.
--]]--
function netwrapper.BroadcastNetVar( ent, key, value )
	net.Start( "NetWrapper" )
		net.WriteEntity( ent )
		net.WriteString( key )
		net.WriteType( value )
	net.Broadcast()
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.SendNetVar( player, entity, string, * )
--
--	Sends a net message to the specified client that contains the
--	 key/value pair to assign on the given entity.
--]]--
function netwrapper.SendNetVar( ply, ent, key, value )
	net.Start( "NetWrapper" )
		net.WriteEntity( ent )
		net.WriteString( key )
		net.WriteType( value )
	net.Send( ply )
end