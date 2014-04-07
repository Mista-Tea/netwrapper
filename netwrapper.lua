--[[--------------------------------------------------------------------------
	File name:
		netwrapper.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (MIT)

		Copyright (c) 2014 Mista-Tea

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
			
	Changelog:
		- April 7th, 2014:
			- Created
			- Added to GitHub
			- Added license in file to make copying into addons not require the LICENSE file
----------------------------------------------------------------------------]]

print( "[NetWrapper] Initializing netwrapper library" )

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
--		Localized Functions 
--------------------------------------------------------------------------]]--

local net      = net
local hook     = hook
local util     = util
local pairs    = pairs
local IsValid  = IsValid
local IsEntity = IsEntity

--[[--------------------------------------------------------------------------
--		Namespace Functions
--------------------------------------------------------------------------]]--

if ( SERVER ) then 

	util.AddNetworkString( "NetWrapper" )
	util.AddNetworkString( "NetWrapperSyncEntity" )

	--\\----------------------------------------------------------------------\\--
	net.Receive( "NetWrapper", function( len, ply )
		netwrapper.SyncClient( ply )
	end )
	--\\----------------------------------------------------------------------\\--
	net.Receive( "NetWrapperSyncEntity", function( len, ply )
		local ent = net.ReadEntity()
		
		for key, val in pairs( netwrapper.GetNetVars( ent ) ) do
			netwrapper.SendNetVar( ply, ent, key, val )
		end
	end )
	--\\----------------------------------------------------------------------\\--
	function netwrapper.SyncClient( ply )
		for ent, values in pairs( netwrapper.ents ) do
			if ( !IsValid( ent ) ) then netwrapper.ents[ ent ] = nil continue; end
			
			for key, value in pairs( values ) do
				if ( IsEntity( value ) and !value:IsValid() ) then netwrapper.ents[ ent ][ key ] = nil continue; end
				
				netwrapper.SendNetVar( ply, ent, key, value )
			end			
		end
	end
	--\\----------------------------------------------------------------------\\--
	function netwrapper.BroadcastNetVar( ent, key, value )
		net.Start( "NetWrapper" )
			net.WriteEntity( ent )
			net.WriteString( key )
			net.WriteType( value )
		net.Broadcast()
	end
	--\\----------------------------------------------------------------------\\--
	function netwrapper.SendNetVar( ply, ent, key, value )
		net.Start( "NetWrapper" )
			net.WriteEntity( ent )
			net.WriteString( key )
			net.WriteType( value )
		net.Send( ply )
	end
	
elseif ( CLIENT ) then

	net.Receive( "NetWrapper", function( len )
		local ent = net.ReadEntity()
		local key = net.ReadString()
		local id  = net.ReadUInt( 8 )  -- read the prepended type ID that was written automatically by net.WriteType(*)
		local val = net.ReadType( id ) -- read the data using the corresponding type ID

		ent:SetNetVar( key, val )
	end )
	--\\----------------------------------------------------------------------\\--
	hook.Add( "InitPostEntity", "NetWrapperSync", function()
		net.Start( "NetWrapper" )
		net.SendToServer()
	end )
	--\\----------------------------------------------------------------------\\--
	hook.Add( "OnEntityCreated", "NetWrapperSync", function( ent )
		net.Start( "NetWrapperSyncEntity" )
			net.WriteEntity( ent )
		net.SendToServer()
	end )
	--\\----------------------------------------------------------------------\\--
end

--\\----------------------------------------------------------------------\\--
function ENTITY:SetNetVar( key, value )
	netwrapper.StoreNetVar( self, key, value )
	
	if ( SERVER ) then
		netwrapper.BroadcastNetVar( self, key, value )
	end
end
--\\----------------------------------------------------------------------\\--
function ENTITY:GetNetVar( key )
	local values = netwrapper.GetNetVars( self )
	return (values and values[ key ]) or nil
end
--\\----------------------------------------------------------------------\\--
function netwrapper.StoreNetVar( ent, key, value )
	netwrapper.ents = netwrapper.ents or {}
	netwrapper.ents[ ent ] = netwrapper.ents[ ent ] or {}
	netwrapper.ents[ ent ][ key ] = value
end
--\\----------------------------------------------------------------------\\--
function netwrapper.GetNetVars( ent )
	return netwrapper.ents[ ent ] or {}
end
