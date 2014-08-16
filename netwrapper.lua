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
		Changelog:
		- March 9th,   2014:    Created
		- April 5th,   2014:    Added to GitHub
		- August 15th, 2014:    Added Net Requests
----------------------------------------------------------------------------]]

print( "[NetWrapper] Initializing netwrapper library" )

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
local GetConVarNumber = GetConVarNumber

local ENTITY = FindMetaTable( "Entity" )

netwrapper.Delay = CreateConVar( "netwrapper_request_delay", 5, bit.bor( FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE ), "The number of seconds before a client can send a net request to the server"  )
netwrapper.MaxRequests = CreateConVar( "netwrapper_max_requests",  -1, bit.bor( FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE ), "The number of requests a client can send when an entity does not have a value stored at the requested key" )

--[[--------------------------------------------------------------------------
--	Namespace Functions
--------------------------------------------------------------------------]]--

if ( SERVER ) then 

	util.AddNetworkString( "NetWrapperVar" )
	util.AddNetworkString( "NetWrapperRequest" )

	--[[----------------------------------------------------------------------]]--
	net.Receive( "NetWrapperVar", function( len, ply )
		netwrapper.SyncClient( ply )
	end )
	--[[----------------------------------------------------------------------]]--
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
	--[[----------------------------------------------------------------------]]--
	function netwrapper.BroadcastNetVar( id, key, value )
		net.Start( "NetWrapperVar" )
			net.WriteUInt( id, 16 )
			net.WriteString( key )
			net.WriteType( value )
		net.Broadcast()
	end
	--[[----------------------------------------------------------------------]]--
	function netwrapper.SendNetVar( ply, id, key, value )
		net.Start( "NetWrapperVar" )
			net.WriteUInt( id, 16 )
			net.WriteString( key )
			net.WriteType( value )
		net.Send( ply )
	end
	--[[----------------------------------------------------------------------]]--
	net.Receive( "NetWrapperRequest", function( bits, ply )
		local ent = net.ReadEntity()
		local key = net.ReadString()
		
		if ( ent:GetNetRequest( key ) ~= nil ) then
			netwrapper.SendNetRequest( ply, ent, key, ent:GetNetRequest( key ) )
		end
	end )
	--[[----------------------------------------------------------------------]]--
	function netwrapper.SendNetRequest( ply, ent, key, value )
		net.Start( "NetWrapperRequest" )
			net.WriteEntity( ent )
			net.WriteString( key )
			net.WriteType( value )
		net.Send( ply )
	end
	
elseif ( CLIENT ) then

	net.Receive( "NetWrapperVar", function( len )
		local entid  = net.ReadUInt( 16 )
		local key    = net.ReadString()
		local typeid = net.ReadUInt( 8 )
		local value  = net.ReadType( typeid )

		netwrapper.StoreNetVar( entid, key, value )
	end )
	--[[----------------------------------------------------------------------]]--
	net.Receive( "NetWrapperRemove", function( len )
		local entid = net.ReadUInt( 16 )
		netwrapper.RemoveNetVars( entid )
	end )
	--[[----------------------------------------------------------------------]]--
	hook.Add( "InitPostEntity", "NetWrapperSync", function()
		net.Start( "NetWrapperVar" )
		net.SendToServer()
	end )
	--[[----------------------------------------------------------------------]]--
	hook.Add( "OnEntityCreated", "NetWrapperSync", function( ent )
		local id = ent:EntIndex()
		local values = netwrapper.GetNetVars( id )
		
		for key, value in pairs( values ) do
			ent:SetNetVar( key, value )
		end
	end )
	--[[----------------------------------------------------------------------]]--
	function ENTITY:SendNetRequest( key )
		netwrapper.SendNetRequest( self, key )
	end
	--[[----------------------------------------------------------------------]]--
	function netwrapper.SendNetRequest( ent, key )
		local requests = netwrapper.requests

		if ( !requests[ ent ] )                  then requests[ ent ] = {} end
		if ( !requests[ ent ][ "NumRequests" ] ) then requests[ ent ][ "NumRequests" ] = 0 end
		if ( !requests[ ent ][ "NextRequest" ] ) then requests[ ent ][ "NextRequest" ] = CurTime() end
		
		local maxRetries = netwrapper.MaxRequests:GetInt()
		
		-- if the client tries to send another request when they have already hit the maximum number of requests, just ignore it
		if ( maxRetries >= 0 and requests[ ent ][ "NumRequests" ] >= maxRetries ) then return end
		
		-- if the client tries to send another request before the netwrapper_request_delay time has passed, just ignore it
		if ( requests[ ent ][ "NextRequest" ] > CurTime() ) then return end
		
		net.Start( "NetWrapperRequest" )
			net.WriteEntity( ent )
			net.WriteString( key )
		net.SendToServer()
		
		requests[ ent ][ "NextRequest" ] = CurTime() + netwrapper.Delay:GetInt()
		requests[ ent ][ "NumRequests" ] = requests[ ent ][ "NumRequests" ] + 1
	end
	--[[----------------------------------------------------------------------]]--
	net.Receive( "NetWrapperRequest", function( bits )
		local ent    = net.ReadEntity()
		local key    = net.ReadString()
		local typeid = net.ReadUInt( 8 )
		local value  = net.ReadType( typeid )
		
		ent:SetNetRequest( key, value )
	end )
end


--[[----------------------------------------------------------------------]]--
function ENTITY:SetNetVar( key, value )
	netwrapper.StoreNetVar( self:EntIndex(), key, value )
	
	if ( SERVER ) then 
		netwrapper.BroadcastNetVar( self:EntIndex(), key, value )
	end
end
--[[----------------------------------------------------------------------]]--
function ENTITY:GetNetVar( key, default )
	local values = netwrapper.GetNetVars( self:EntIndex() )
	if ( values[ key ] ~= nil ) then return values[ key ] else return default end
end
--[[----------------------------------------------------------------------]]--
function netwrapper.StoreNetVar( id, key, value )
	netwrapper.ents[ id ] = netwrapper.ents[ id ] or {}
	netwrapper.ents[ id ][ key ] = value
end
--[[----------------------------------------------------------------------]]--
function netwrapper.GetNetVars( id )
	return netwrapper.ents[ id ] or {}
end
--[[----------------------------------------------------------------------]]--
function netwrapper.RemoveNetVars( id )
	netwrapper.ents[ id ] = nil
end
--[[----------------------------------------------------------------------]]--
function ENTITY:SetNetRequest( key, value )
	netwrapper.StoreNetRequest( self, key, value )
end
--[[----------------------------------------------------------------------]]--
function ENTITY:GetNetRequest( key, default )
	local values = netwrapper.GetNetRequests( self )
	if ( values[ key ] ~= nil ) then return values[ key ] else return default end
end
--[[----------------------------------------------------------------------]]--
function netwrapper.StoreNetRequest( ent, key, value )
	netwrapper.requests[ ent ] = netwrapper.requests[ ent ] or {}
	netwrapper.requests[ ent ][ key ] = value
end
--[[----------------------------------------------------------------------]]--
function netwrapper.GetNetRequests( ent )
	return netwrapper.requests[ ent ] or {}
end
--[[----------------------------------------------------------------------]]--
function netwrapper.RemoveNetRequests( ent )
	netwrapper.requests[ ent ] = nil
end
--[[----------------------------------------------------------------------]]--
hook.Add( "EntityRemoved", "NetWrapperRemove", function( ent )
	netwrapper.RemoveNetVars( ent:EntIndex() )
	netwrapper.RemoveNetRequests( ent )
end )