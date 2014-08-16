--[[--------------------------------------------------------------------------
	File name:
		sv_netwrapper.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (copy/modify/distribute freely!)
			
	Changelog:
		- March 9th,   2014:    Created
		- April 5th,   2014:    Added to GitHub
		- August 15th, 2014:    Added Net Requests
----------------------------------------------------------------------------]]

--[[--------------------------------------------------------------------------
-- 	Namespace Tables
--------------------------------------------------------------------------]]--

netwrapper          = netwrapper          or {}
netwrapper.ents     = netwrapper.ents     or {}
netwrapper.requests = netwrapper.requests or {}

--[[--------------------------------------------------------------------------
-- 	Localized Functions & Variables
--------------------------------------------------------------------------]]--

local net = net
local util = util
local pairs = pairs
local IsEntity = IsEntity
local CreateConVar = CreateConVar
local FindMetaTable = FindMetaTable

util.AddNetworkString( "NetWrapperVar" )
util.AddNetworkString( "NetWrapperRequest" )
util.AddNetworkString( "NetWrapperClear" )

local ENTITY = FindMetaTable( "Entity" )

--[[--------------------------------------------------------------------------
-- 	Namespace Functions
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
--	NET VARS
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
--
--	Net - NetWrapperVar
--
--	Received when a player fully initializes with the InitPostEntity hook.
--	 This will sync all currently networked entities to the client.
--]]--
net.Receive( "NetWrapperVar", function( len, ply )
	netwrapper.SyncClient( ply )
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
	net.Start( "NetWrapperVar" )
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
	net.Start( "NetWrapperVar" )
		net.WriteUInt( id, 16 )
		net.WriteString( key )
		net.WriteType( value )
	net.Send( ply )
end



--[[--------------------------------------------------------------------------
--	NET REQUESTS
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
--
--	Net - NetWrapperRequest
--
--	Received from a client when they are requesting a certain key on an entity
--	 that was set using ENTITY:SetNetRequest().
--
--	**UNLIKE the NetVars portion of the netwrapper library, Net Requests are stored
--	 on the server and are ONLY networked when the client sends a request for it.
--	 This can be incredibly helpful in reducing network traffic for connecting clients
--	 when you have data that doesn't need to be networked instantly.
--
--	For example, if you wanted to network the owner's name of a prop to clients, but
--	 fear you may be sending too much network traffic to connecting clients because there
--	 are hundreds or thousands of props out, you can use ENTITY:SetNetRequest() instead.
--	 When the client looks at a prop, you can add a check to see if ENTITY:GetNetRequest()
--	 doesn't return anything and then use ENTITY:SendNetRequest() to request the prop owner's
--	 name from the server.
--]]--
net.Receive( "NetWrapperRequest", function( bits, ply )
	local id  = net.ReadUInt( 16 )
	local ent = Entity( id )
	local key = net.ReadString()
	
	if ( ent:GetNetRequest( key ) ~= nil ) then
		netwrapper.SendNetRequest( ply, id, key, ent:GetNetRequest( key ) )
	end
end )

--[[--------------------------------------------------------------------------
--
--	netwrapper.SendNetRequest( player, number, string, * )
--
--	Called when a client is asking the server to network a stored value on entity
--	 with the given key. In combination with ENTITY:SendNetRequest() on the client,
--	 these functions give you control of when a client asks for entity values to be
--	 networked to them, unlike the netwrapper.SendNetVar() function.
--]]--
function netwrapper.SendNetRequest( ply, id, key, value )
	net.Start( "NetWrapperRequest" )
		net.WriteUInt( id, 16 )
		net.WriteString( key )
		net.WriteType( value )
	net.Send( ply )
end

--[[--------------------------------------------------------------------------
-- 
-- 	Hook - EntityRemoved( entity )
-- 
-- 	Called when an entity has been removed. This will automatically remove the
-- 	 data at the entity's index if any was being networked. This will prevent
-- 	 data corruption where a future entity may be using the data from a previous
--	 entity that used the same EntIndex
--]]--
hook.Add( "EntityRemoved", "NetWrapperClear", function( ent )
	netwrapper.ClearData( ent:EntIndex() )
end )