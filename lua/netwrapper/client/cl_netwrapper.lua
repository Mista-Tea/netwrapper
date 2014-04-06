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
	local ent = net.ReadEntity()
	local key = net.ReadString()
	local id  = net.ReadUInt( 8 )   -- read the prepended type ID that was written automatically by net.WriteType(*)
	local val = net.ReadType( id ) -- read the data using the corresponding type ID

	ent:SetNetVar( key, val )
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
--	This hook is called any time an entity is created and polls the server
--	 to see if there is any networked data on the entity that we need to sync.
--
--	When creating a new entity on the server and instantly assigning networked
--	 values using this library, there is a very short time period where the entity
--	 has not been created on the client yet. By using this hook, we ensure that the
--	 entity is fully initialized before attempting to retrieve any networked values.
--]]--
hook.Add( "OnEntityCreated", "NetWrapperSync", function( ent )
	net.Start( "NetWrapperSyncEntity" )
		net.WriteEntity( ent )
	net.SendToServer()
end )