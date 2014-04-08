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

local net      = net
local util     = util
local pairs    = pairs
local IsEntity = IsEntity

--[[--------------------------------------------------------------------------
--		Namespace Functions
--------------------------------------------------------------------------]]--

util.AddNetworkString( "NetWrapper" )
util.AddNetworkString( "NetWrapperRemove" )

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
--	Hook - EntityRemoved( entity )
--	
--	Called when an entity has been removed. This will automatically remove the
--	 data at the entity's index if any was being networked. This will prevent
--	 data corruption where a future entity may be using the data from a previous
--	 entity that used the same EntIndex
--]]--
hook.Add( "EntityRemoved", "NetWrapperRemove", function( ent )
	netwrapper.RemoveNetVars( ent:EntIndex() )
end )

--[[--------------------------------------------------------------------------
--
--	netwrapper.SyncClient( player )
--
--	Loops through every entity currently networked and sends the networked
--	 data to the client.
--
--	While looping, any values that are NULL (disconnected players, removed entities) 
--	 will automatically be removed from the table and not synced to the client.
--]]--
function netwrapper.SyncClient( ply )
	for id, values in pairs( netwrapper.ents ) do			
		for key, value in pairs( values ) do
			if ( IsEntity( value ) and !value:IsValid() ) then 
				netwrapper.ents[ id ][ key ] = nil 
				continue; 
			end
			
			netwrapper.SendNetVar( ply, id, key, value )
		end			
	end
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.BroadcastNetVar( int, string, * )
--
--	Sends a net message to all connectect clients containing the
--	 key/value pair to assign on the associated entity.
--]]--
function netwrapper.BroadcastNetVar( id, key, value )
	net.Start( "NetWrapper" )
		net.WriteUInt( id, 16 )
		net.WriteString( key )
		net.WriteType( value )
	net.Broadcast()
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.SendNetVar( player, int, string, * )
--
--	Sends a net message to the specified client containing the
--	 key/value pair to assign on the associated entity.
--]]--
function netwrapper.SendNetVar( ply, id, key, value )
	net.Start( "NetWrapper" )
		net.WriteUInt( id, 16 )
		net.WriteString( key )
		net.WriteType( value )
	net.Send( ply )
end