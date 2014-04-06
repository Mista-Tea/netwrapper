--[[--------------------------------------------------------------------------------
	Custom Networking Script
	
	File description:
		- TODO
		
	Changelog:
		- Added March 9th, 2014
----------------------------------------------------------------------------------]]

--//------------------------------------------------------------------------------
--		Namespace Tables 
------------------------------------------------------------------------------//--

netwrapper      = netwrapper      or {}
netwrapper.ents = netwrapper.ents or {}

--//------------------------------------------------------------------------------
--		Localized Functions 
------------------------------------------------------------------------------//--

local ENTITY = FindMetaTable( "Entity" )

local net     = net
local util    = util
local ipairs  = ipairs
local IsValid = IsValid

--//------------------------------------------------------------------------------
--		Namespace Functions
------------------------------------------------------------------------------//--

if ( CLIENT ) then
	
	--//--------------------------------------------------------------------------//--
	--//
	--//	ENTITY:GetNetVar( string )
	--//
	--//	Returns the value of the associated key from the entity, or nil if 
	--//	 this key has not been set yet.
	--//--
	function ENTITY:GetNetVar( key )
		return self[ key ]
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	ENTITY:SetNetVar( string, * )
	--//
	--//	Sets the value at the associated key on the entity.
	--//	 Value types can be nearly anything, e.g., string, number, table, angle, vector.
	--//
	--//	Setting a new value on the entity using the same key will replace the original value.
	--//	 This allows you to change the value's type without having to use a different function,
	--//	 unlike the ENTITY:SetNetworked* library.
	--//--
	function ENTITY:SetNetVar( key, value )
		self[ key ] = value
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	Net - NetWrapper( entity, string, uint, * )
	--//
	--//	Retrieves a networked key/value pair from the server to assign on the entity.
	--//	 The value is written on the server using WriteType, so ReadType is used
	--//	 on the client to automatically retrieve the value for us without relying
	--//	 on multiple functions (like ReadEntity, ReadString, etc).
	--//--
	net.Receive( "NetWrapper", function( bytes )
		local ent = net.ReadEntity()
		local key = net.ReadString()
		local id  = net.ReadUInt( 8 )   -- read the prepended type ID that was written automatically by net.WriteType(*)
		local val = net.ReadType( id ) -- read the data using the corresponding type ID
		ent:SetNetVar( key, val )
	end )
	--//--------------------------------------------------------------------------//--
	--//
	--//	Hook - InitPostEntity
	--//
	--//	When the client has fully initialized in the server, this will send a
	--//	 request to retrieve all currently networked values from the server.
	--//--
	hook.Add( "InitPostEntity", "NetWrapperSync", function()
		net.Start( "NetWrapper" )
		net.SendToServer()
	end )
	--//--------------------------------------------------------------------------//--
	--//
	--//	Hook - OnEntityCreated
	--//
	--//	This hook is called any time an entity is created and polls the server
	--//	 to see if there is any networked data on the entity that we need to grab.
	--//
	--//	When creating a new entity on the server and instantly assignment networked
	--//	 values using this library, there is a very short time period where the entity
	--//	 has not been created on the client yet. By using this hook, we ensure that the
	--//	 entity is fully initialized before attempting to assign any networked values.
	--//--
	hook.Add( "OnEntityCreated", "NetWrapperSync", function( ent )
		net.Start( "NetWrapperSyncEntity" )
			net.WriteEntity( ent )
		net.SendToServer()
	end )
	
elseif ( SERVER ) then
	
	util.AddNetworkString( "NetWrapper" )
	util.AddNetworkString( "NetWrapperSyncEntity" )
	--//--------------------------------------------------------------------------//--
	--//
	--//	ENTITY:GetNetVar( string )
	--//
	--//	Returns the value of the associated key from the entity, or nil if 
	--//	 this key has not been set yet.
	--//--
	function ENTITY:GetNetVar( key )
		return self[ key ]
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	ENTITY:SetNetVar( string, * )
	--//
	--//	Sets the value at the associated key on the entity.
	--//	 Value types can be nearly anything, e.g., string, number, table, angle, vector.
	--//
	--//	Setting a new value on the entity using the same key will replace the original value.
	--//	 This allows you to change the value's type without having to use a different function,
	--//	 unlike the ENTITY:SetNetworked* library.
	--//
	--//	This will also store the entity/key/value in a table so that we can network
	--//	 the data to any clients that connect after the values have initially been networked.
	--//--
	function ENTITY:SetNetVar( key, value )
		self[ key ] = value
		netwrapper.StoreNetVar( self, key, value )
		netwrapper.BroadcastNetVar( self, key, value )
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	netwrapper.BroadcastNetVar( entity, string, * )
	--//
	--//	Broadcasts a net message to all connected clients that contains the
	--//	 key/value pair to assign on the given entity.
	--//--
	function netwrapper.BroadcastNetVar( ent, key, value )
		net.Start( "NetWrapper" )
			net.WriteEntity( ent )
			net.WriteString( key )
			net.WriteType( value )
		net.Broadcast()
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	netwrapper.SendNetVar( player, entity, string, * )
	--//
	--//	Sends a net message to the specified client that contains the
	--//	 key/value pair to assign on the given entity.
	--//--
	function netwrapper.SendNetVar( ply, ent, key, value )
		net.Start( "NetWrapper" )
			net.WriteEntity( ent )
			net.WriteString( key )
			net.WriteType( value )
		net.Send( ply )
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	netwrapper.StoreNetVar( entity, string, * )
	--//
	--//	Stores the key/value pair of the entity into a table so that we can
	--//	 network the data with any clients that connect afterward.
	--//--
	function netwrapper.StoreNetVar( ent, key, value )
		netwrapper.ents = netwrapper.ents or {}
		netwrapper.ents[ ent ] = netwrapper.ents[ ent ] or {}
		netwrapper.ents[ ent ][ key ] = value
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	netwrapper.GetStoredEntVars( entity )
	--//
	--//	Retrieves any networked data on the given entity, or nil if nothing
	--//	 has been networked on the entity yet.
	--//--
	function netwrapper.GetStoredEntVars( ent )
		return netwrapper.ents[ ent ]
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	netwrapper.SyncClient( player )
	--//
	--//	Loops through every entity currently networked and sends the networked
	--//	 data to the client.
	--//
	--//	While looping, any NULL entities (disconnected players, removed entities) 
	--//	 will automatically be removed from the table.
	--//--
	function netwrapper.SyncClient( ply )
		for ent, values in ipairs( netwrapper.ents ) do
			if ( !IsValid( ent ) ) then netwrapper.ents[ ent ] = nil continue; end
			
			for key, value in ipairs( values ) do
				if ( IsEntity( value ) and !value:IsValid() ) then netwrapper.ents[ ent ][ key ] = nil continue; end
				
				netwrapper.SendNetVar( ply, ent, key, value )
			end			
		end
	end
	--//--------------------------------------------------------------------------//--
	--//
	--//	Net - NetWrapper
	--//
	--//	Received when a player fully initializes with the InitPostEntity hook.
	--//	 This will sync all currently networked entities to the client.
	--//--
	net.Receive( "NetWrapper", function( bytes, ply )
		netwrapper.SyncClient( ply )
	end )
	--//--------------------------------------------------------------------------//--
	--//
	--//	Net - NetWrapperSyncEntity( entity )
	--//
	--//	Received when an entity is created on the client.
	--//	 This will attempt to find any networked data on the given entity
	--//	 and sync it back to the client.
	--//--
	net.Receive( "NetWrapperSyncEntity", function( bytes, ply )
		local ent = net.ReadEntity()
		
		local vars = netwrapper.GetStoredEntVars( ent )
		if ( !vars ) then return; end
		
		for key, val in pairs( vars ) do
			netwrapper.SendNetVar( ply, ent, key, val )
		end
	end )
	
end