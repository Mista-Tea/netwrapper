--[[--------------------------------------------------------------------------
	File name:
		cl_netwrapper.lua
	
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

netwrapper = netwrapper or {}

--[[--------------------------------------------------------------------------
--		Localized Variables 
--------------------------------------------------------------------------]]--

local net  = net
local hook = hook

--[[--------------------------------------------------------------------------
--		Namespace Functions
--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------
--
--	Net - NetWrapper( entity, string, uint, * )
--
--	Retrieves a networked key/value pair from the server to assign on the entity.
--	 The value is written on the server using WriteType, so ReadType is used
--	 on the client to automatically retrieve the value for us without relying
--	 on multiple functions (like ReadEntity, ReadString, etc).
--]]--
net.Receive( "NetWrapper", function( len )
	local entid  = net.ReadUInt( 16 )
	local key    = net.ReadString()
	local typeid = net.ReadUInt( 8 )      -- read the prepended type ID that was written automatically by net.WriteType(*)
	local value  = net.ReadType( typeid ) -- read the data using the corresponding type ID

	netwrapper.StoreNetVar( entid, key, value )
end )

--[[--------------------------------------------------------------------------
--
--	Net - NetWrapperRemove( uint )
--
--	Removes any networked data on the id-associated entity. This will occur
--	 any time an entity has been removed and the EntityRemoved hook has been
--	 called on the server.
--]]--
net.Receive( "NetWrapperRemove", function( len )
	local entid  = net.ReadUInt( 16 )
	netwrapper.RemoveNetVars( entid )
end )

--[[--------------------------------------------------------------------------
--
--	Hook - InitPostEntity
--
--	When the client has fully initialized in the server, this will send a
--	 request to retrieve all currently networked values from the server.
--]]--
hook.Add( "InitPostEntity", "NetWrapperSync", function()
	net.Start( "NetWrapper" )
	net.SendToServer()
end )

--[[--------------------------------------------------------------------------
--
--	Hook - OnEntityCreated
--
--	This hook is called every time an entity is created. This will automatically
--	 assign any networked values that are associated with the entity's EntIndex.
--	 This saves us the trouble of polling the server to retrieve the values.
--]]--
hook.Add( "OnEntityCreated", "NetWrapperSync", function( ent )
	local id = ent:EntIndex()
	local values = netwrapper.GetNetVars( id )
	
	for key, value in pairs( values ) do
		ent:SetNetVar( key, value )
	end
end )