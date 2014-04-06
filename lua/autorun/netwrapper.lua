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

local net  = net
local util = util

--//------------------------------------------------------------------------------
--		Namespace Functions
------------------------------------------------------------------------------//--

if ( CLIENT ) then

	function ENTITY:GetNetVar( key )
		return self[ key ]
	end
	--//--------------------------------------------------------------------------//--
	function ENTITY:SetNetVar( key, value )
		self[ key ] = value
	end
	--//--------------------------------------------------------------------------//--
	net.Receive( "NetWrapper", function( bytes )
		local ent = net.ReadEntity()
		local key = net.ReadString()
		local tID = net.ReadUInt( 8 )   -- read the prepended type ID that was written automatically by net.WriteType(*)
		local val = net.ReadType( tID ) -- read the data using the corresponding type ID
		ent:SetNetVar( key, val )
	end )
	--//--------------------------------------------------------------------------//--
	hook.Add( "InitPostEntity", "NetWrapperSync", function()
		net.Start( "NetWrapper" )
		net.SendToServer()
	end )
	--//--------------------------------------------------------------------------//--
	hook.Add( "OnEntityCreated", "NetWrapperSync", function( ent )
		net.Start( "NetWrapperSyncEntity" )
			net.WriteEntity( ent )
		net.SendToServer()
	end )
	
elseif ( SERVER ) then
	
	util.AddNetworkString( "NetWrapper" )
	util.AddNetworkString( "NetWrapperSyncEntity" )
	--//--------------------------------------------------------------------------//--
	function ENTITY:GetNetVar( key )
		return self[ key ]
	end
	--//--------------------------------------------------------------------------//--
	function ENTITY:SetNetVar( key, value )
		self[ key ] = value
		netwrapper.StoreNetVar( self, key, value )
		netwrapper.BroadcastNetVar( self, key, value )
	end
	--//--------------------------------------------------------------------------//--
	function netwrapper.BroadcastNetVar( ent, key, value )
		net.Start( "NetWrapper" )
			net.WriteEntity( ent )
			net.WriteString( key )
			net.WriteType( value )
		net.Broadcast()
	end
	--//--------------------------------------------------------------------------//--
	function netwrapper.SendNetVar( ply, ent, key, value )
		net.Start( "NetWrapper" )
			net.WriteEntity( ent )
			net.WriteString( key )
			net.WriteType( value )
		net.Send( ply )
	end
	--//--------------------------------------------------------------------------//--
	function netwrapper.StoreNetVar( ent, key, value )
		netwrapper.ents = netwrapper.ents or {}
		netwrapper.ents[ ent ] = netwrapper.ents[ ent ] or {}
		netwrapper.ents[ ent ][ key ] = value
	end
	--//--------------------------------------------------------------------------//--
	function netwrapper.GetStoredEntVars( ent )
		return netwrapper.ents[ ent ]
	end
	--//--------------------------------------------------------------------------//--
	function netwrapper.SyncClient( ply )
		for ent, values in pairs( netwrapper.ents ) do
			if ( !IsValid( ent ) ) then netwrapper.ents[ ent ] = nil continue; end
			
			for key, value in pairs( values ) do
				if ( IsEntity( value ) and !value:IsValid() ) then netwrapper.ents[ ent ][ key ] = nil continue; end
				
				netwrapper.SendNetVar( ply, ent, key, value )
			end			
		end
	end
	--//--------------------------------------------------------------------------//--
	net.Receive( "NetWrapper", function( bytes, ply )
		netwrapper.SyncClient( ply )
	end )
	--//--------------------------------------------------------------------------//--
	net.Receive( "NetWrapperSyncEntity", function( bytes, ply )
		local ent = net.ReadEntity()
		
		local vars = netwrapper.GetStoredEntVars( ent )
		if ( !vars ) then return; end
		
		for key, val in pairs( vars ) do
			netwrapper.SendNetVar( ply, ent, key, val )
		end
	end )
	
end