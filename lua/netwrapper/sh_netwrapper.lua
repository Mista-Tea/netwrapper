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
--	ENTITY:SetNetVar( string, *, boolean [optional] )
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
--
--	Trying to set the same exact value at a key will result in nothing happening. This is
--	 done to prevent unnecessary networking, since there is generally no reason to network
--	 the same value consecutively. However, if for any reason you need to network the value
--	 again, you can set the 3rd argument, 'force', to true.
--]]--
function ENTITY:SetNetVar( key, value, force )

	if ( netwrapper.GetNetVars( self:EntIndex() )[ key ] == value and not force ) then return end

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
	netwrapper.StoreNetRequest( self:EntIndex(), key, value )
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
	local values = netwrapper.GetNetRequests( self:EntIndex() )
	if ( values[ key ] ~= nil ) then return values[ key ] else return default end
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.StoreNetRequest( number, string, * )
--
--	Stores the key/value pair of the entity into a table so that we can
--	 retrieve them with ENTITY:GetNetRequest( key ).
--
--	**See special notes on ENTITY:SetNetRequest()
--]]--
function netwrapper.StoreNetRequest( id, key, value )
	netwrapper.requests[ id ] = netwrapper.requests[ id ] or {}
	netwrapper.requests[ id ][ key ] = value
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.GetNetRequests( number )
--
--	Retrieves any stored requested data on the given entity, or an empty table if 
--	 nothing has been stored on the entity yet.
--]]--
function netwrapper.GetNetRequests( id )
	return netwrapper.requests[ id ] or {}
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.RemoveNetVars( number )
--
--	Removes any data stored at the entity index. When a player disconnects or
--	 an entity is removed, its index in the table will be removed to ensure that
--	 the next entity to use the same index does not use the first entity's data
--	 and become corrupted.
--]]--
function netwrapper.RemoveNetRequests( id )
	netwrapper.requests[ id ] = nil
end



--[[--------------------------------------------------------------------------
--
--	netwrapper.ClearData( id )
--
--	Removes any data stored at the entity index. When a player disconnects or
--	 an entity is removed, its index in the table will be removed to ensure that
--	 the next entity to use the same index does not use the first entity's data
--	 and become corrupted.
--]]--
function netwrapper.ClearData( id )
	netwrapper.ents[ id ]     = nil
	netwrapper.requests[ id ] = nil

	if ( SERVER ) then
		net.Start( "NetWrapperClear" )
			net.WriteUInt( id, 16 )
		net.Broadcast()
	end
end
