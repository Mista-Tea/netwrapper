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
--	Sets the value at the associated key on the entity.
--	 Value types can be nearly anything, e.g., string, number, table, angle, vector.
--
--	Setting a new value on the entity using the same key will replace the original value.
--	 This allows you to change the value's type without having to use a different function,
--	 unlike the ENTITY:SetNetworked* library.
--
--	This will also store the entity/key/value in a table so that we can network
--	 the data to any clients that connect after the values have initially been networked.
--]]--
function ENTITY:SetNetVar( key, value )
	netwrapper.StoreNetVar( self, key, value )
	
	if ( SERVER ) then
		netwrapper.BroadcastNetVar( self, key, value )
	end
end

--[[--------------------------------------------------------------------------
--
--	ENTITY:GetNetVar( string )
--
--	Returns the value of the associated key from the entity, or nil if 
--	 this key has not been set yet.
--]]--
function ENTITY:GetNetVar( key )
	local values = netwrapper.GetNetVars( self )
	return (values and values[ key ]) or nil
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.StoreNetVar( entity, string, * )
--
--	Stores the key/value pair of the entity into a table so that we can
--	 network the data with any clients that connect afterward.
--]]--
function netwrapper.StoreNetVar( ent, key, value )
	netwrapper.ents = netwrapper.ents or {}
	netwrapper.ents[ ent ] = netwrapper.ents[ ent ] or {}
	netwrapper.ents[ ent ][ key ] = value
end

--[[--------------------------------------------------------------------------
--
--	netwrapper.GetNetVars( entity )
--
--	Retrieves any networked data on the given entity, or nil if nothing
--	 has been networked on the entity yet.
--]]--
function netwrapper.GetNetVars( ent )
	return netwrapper.ents[ ent ]
end