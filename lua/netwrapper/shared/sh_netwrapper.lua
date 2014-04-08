--[[--------------------------------------------------------------------------
	File name:
		sh_netwrapper.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (copy/modify/distribute freely!)
		
	Changelog:
		- March 9th, 2014:	Created
		- April 5th, 2014:	Added to GitHub
----------------------------------------------------------------------------]]

AddCSLuaFile()

--[[--------------------------------------------------------------------------
--		Namespace Tables 
--------------------------------------------------------------------------]]--

netwrapper      = netwrapper      or {}
netwrapper.ents = netwrapper.ents or {}

--[[--------------------------------------------------------------------------
--		Localized Variables 
--------------------------------------------------------------------------]]--

local ENTITY = FindMetaTable( "Entity" )

--[[--------------------------------------------------------------------------
--		Namespace Functions
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
	return (values and values[ key ]) or default
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
	netwrapper.ents = netwrapper.ents or {}
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
	
	if ( SERVER ) then
		net.Start( "NetWrapperRemove" )
			net.WriteUInt( id, 16 )
		net.Broadcast()
	end
end
