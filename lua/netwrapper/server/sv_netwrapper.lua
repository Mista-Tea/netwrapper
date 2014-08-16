--[[--------------------------------------------------------------------------
	File name:
		sh_netwrapper.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (copy/modify/distribute freely!)
		
	Changelog:
		- March 9th,   2014:    Created
		- April 5th,   2014:    Added to GitHub
		- August 15th, 2014:    Added Net Requests
----------------------------------------------------------------------------]]

AddCSLuaFile()

--[[--------------------------------------------------------------------------
--	Namespace Tables 
--------------------------------------------------------------------------]]--

netwrapper          = netwrapper          or {}
netwrapper.ents     = netwrapper.ents     or {}
netwrapper.requests = netwrapper.requests or {}

--[[--------------------------------------------------------------------------
-- 	Localized Functions & Variables
--------------------------------------------------------------------------]]--

local ENTITY = FindMetaTable( "Entity" )

-- This is the amount of time (in seconds) to wait before a client will send
-- another request to the server, asking for an non-networked key on an entity.
--
-- For example, if you want prop owners to NOT be networked outright (i.e., with ent:SetNetVar())
-- and instead have the client only ask the server for the owner of the prop they are currently
-- looking at, this convar determines the amount of time that must pass before they
-- can send another request for the prop owner. 
--
-- This is solely to prevent net message spamming until the value has successfully been sent to the client
-- There should be no reason it should take more than at most a few seconds for the value to be sent to the client.
--
-- Examples:
-- Value:  0 :: the client can send successive requests as soon as they want to
-- Value: >0 :: the client can send successive requests only after the specified delay has elapsed
netwrapper.Delay      = CreateConVar( "netwrapper_request_delay", 5, bit.bor( FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE ), "The number of seconds before a client can send a net request to the server"  )

-- This is the total amount of requests a client can send to the server when they are asking for
-- a value at the given key from an entity.
--
-- For example, if the client requests a value on an entity with the key "Owner", but the
-- server has not set a value on the entity at the "Owner" key yet, their number of attempted
-- requests will increment by 1.
--
-- When the max number of allowed requests has been reached, the client will no longer send
-- any more requests for the value at the given key on the entity.
--
-- Examples:
-- Value: -1 :: the client can send an unlimited amount of requests (only limited by the netwrapper_request_delay)
-- Value:  0 :: the client cannot send any requests
-- Value: >0 :: the client can send only the specified amount of requests
netwrapper.MaxRequests = CreateConVar( "netwrapper_max_requests",  -1, bit.bor( FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE ), "The number of requests a client can send when an entity does not have a value stored at the requested key" )

--[[--------------------------------------------------------------------------
--	Namespace Functions
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
--	NET VARS
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
--
--	ENTITY:SetNetVar( string, * )
--
--	Stores the key/value pair of the entity into a table so that we can
--	 retrieve them with ENTITY:GetNetVar( key ), and to network the data with any 
--	 clients that connect after the data has initially been networked.
--
--	Value types can be anything supported by the net library, 
--	 e.g., string, number, table, angle, vector, boolean, entity
--
--	Setting a new value on the entity using the same key will replace the original value.
--	 This allows you to change the value's type without having to use a different function,
--	 unlike the ENTITY:SetNW* library.
--]]--
function ENTITY:SetNetVar( key, value )
	netwrapper.StoreNetVar( self:EntIndex(), key, value )
	
	if ( SERVER ) then 
		netwrapper.BroadcastNetVar( self:EntIndex(), key, value )
	end
end

--[[--------------------------------------------------------------------------
--
--	ENTITY:GetNetVar( string, * )
--
--	Returns:
--	    the value of the associated key from the entity,
--	 OR the default value if this key hasn't been set and the default value was provided,
--	 OR nil if no default was provided and this key hasn't been set.
--]]--
function ENTITY:GetNetVar( key, default )
	local values = netwrapper.GetNetVars( self:EntIndex() )
	if ( values[ key ] ~= nil ) then return values[ key ] else return default end
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.StoreNetVar( int, string, * )
--
--	Stores the key/value pair of the entity into a table so that we can
--	 retrieve them with ENTITY:GetNetVar( key ), and to network the data with any 
--	 clients that connect after the data has initially been networked.
--]]--
function netwrapper.StoreNetVar( id, key, value )
	netwrapper.ents[ id ] = netwrapper.ents[ id ] or {}
	netwrapper.ents[ id ][ key ] = value
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.GetNetVars( id )
--
--	Retrieves any networked data on the given entity index, or an empty table if 
--	 nothing has been networked on the entity yet.
--]]--
function netwrapper.GetNetVars( id )
	return netwrapper.ents[ id ] or {}
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.RemoveNetVars( id )
--
--	Removes any data stored at the entity index. When a player disconnects or
--	 an entity is removed, its index in the table will be removed to ensure that
--	 the next entity to use the same index does not use the first entity's data
--	 and become corrupted.
--]]--
function netwrapper.RemoveNetVars( id )
	netwrapper.ents[ id ] = nil
end



--[[--------------------------------------------------------------------------
--	NET REQUESTS
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
--
--	ENTITY:SetNetRequest( string, * )
--
--	Stores the key/value pair of the entity into a table so that we can
--	 retrieve them with ENTITY:GetNetRequest( key ).
--
--	**UNLIKE the ENTITY:SetNetVar() function, ENTITY:SetNetRequest() does NOT network
--	 the value to connecting clients or get broadcasted to all connected clients when set.
--	 Instead, this value will be stored separately and will ONLY be networked when a client
--	 sends a request to the server asking for the specified key. For example, instead of
--	 possibly overflowing the client with networked vars from SetNetVar when they join, you can
--	 specify exactly when the client needs retrieve the value from the server.
--
--	Value types can be anything supported by the net library, 
--	 e.g., string, number, table, angle, vector, boolean, entity
--
--	Setting a new value on the entity using the same key will replace the original value.
--	 This allows you to change the value's type without having to use a different function,
--	 unlike the ENTITY:SetNW* library.
--]]--
function ENTITY:SetNetRequest( key, value )
	netwrapper.StoreNetRequest( self, key, value )
end

--[[--------------------------------------------------------------------------
--
--	ENTITY:GetNetRequest( string, * )
--
--	Returns:
--	    the value of the associated key from the entity,
--	 OR the default value if this key hasn't been set and the default value was provided,
--	 OR nil if no default was provided and this key hasn't been set.
--]]--
function ENTITY:GetNetRequest( key, default )
	local values = netwrapper.GetNetRequests( self )
	if ( values[ key ] ~= nil ) then return values[ key ] else return default end
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.StoreNetRequest( entity, string, * )
--
--	Stores the key/value pair of the entity into a table so that we can
--	 retrieve them with ENTITY:GetNetRequest( key ).
--
--	**See special notes on ENTITY:SetNetRequest()
--]]--
function netwrapper.StoreNetRequest( ent, key, value )
	netwrapper.requests[ ent ] = netwrapper.requests[ ent ] or {}
	netwrapper.requests[ ent ][ key ] = value
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.GetNetRequests( entity )
--
--	Retrieves any stored requested data on the given entity, or an empty table if 
--	 nothing has been s--[[--------------------------------------------------------------------------
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
	local ent = net.ReadEntity()
	local key = net.ReadString()
	
	if ( ent:GetNetRequest( key ) ~= nil ) then
		netwrapper.SendNetRequest( ply, ent, key, ent:GetNetRequest( key ) )
	end
end )

--[[--------------------------------------------------------------------------
--
--	netwrapper.SendNetRequest( player, entity, string, * )
--
--	Called when a client is asking the server to network a stored value on entity
--	 with the given key. In combination with ENTITY:SendNetRequest() on the client,
--	 these functions give you control of when a client asks for entity values to be
--	 networked to them, unlike the netwrapper.SendNetVar() function.
--]]--
function netwrapper.SendNetRequest( ply, ent, key, value )
	net.Start( "NetWrapperRequest" )
		net.WriteEntity( ent )
		net.WriteString( key )
		net.WriteType( value )
	net.Send( ply )
endtored on the entity yet.
--]]--
function netwrapper.GetNetRequests( ent )
	return netwrapper.requests[ ent ] or {}
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.RemoveNetVars( ent )
--
--	Removes any data stored at the entity index. When a player disconnects or
--	 an entity is removed, its index in the table will be removed to ensure that
--	 the next entity to use the same index does not use the first entity's data
--	 and become corrupted.
--]]--
function netwrapper.RemoveNetRequests( ent )
	netwrapper.requests[ ent ] = nil
end



--[[--------------------------------------------------------------------------
--
--	Hook - EntityRemoved( entity )
--	
--	Called when an entity has been removed. This will automatically remove the
--	 data at the entity's index if any was being networked. This will prevent
--	 data corruption where a future entity may be using the data from a previous
--	 entity that used the same EntIndex.
--
--	This now also removes any requests data on the entity to clean the 
--	 netwraper.requests table.
--]]--
hook.Add( "EntityRemoved", "NetWrapperRemove", function( ent )
	netwrapper.RemoveNetVars( ent:EntIndex() )
	netwrapper.RemoveNetRequests( ent )
end )