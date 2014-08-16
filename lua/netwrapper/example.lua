--[[--------------------------------------------------------------------------
	File name:
		example.lua
	
	Author:
		Mista-Tea ([IJWTB] Thomas)
	
	License:
		The MIT License (copy/modify/distribute freely!)
		
	Changelog:
		- March   9th, 2014:    Created
		- April   5th, 2014:    Added to GitHub
		- August 16th, 2014:    Rewrote example for Net Vars / Net Requests
----------------------------------------------------------------------------]]

-- In this example, we will assign a player's name to the prop they spawn in PlayerSpawnedProp.
-- We'll use Net Vars in the first example to show how they automatically network themselves,
-- and then show how Net Requests can be used to ask for the value to be networked manually.






--[[-------------------------------------------]]--
--                    Net Vars
--[[-------------------------------------------]]--

if ( SERVER ) then
	
	-- when a player spawns a prop, assign the owner's name to it with ent:SetNetVar()
	hook.Add( "PlayerSpawnedProp", "AssignOwner", function( ply, mdl, ent )
	
		ent:SetNetVar( "Owner", ply:Nick() ) -- stores and networks the value to clients

	end )
	
elseif ( CLIENT ) then
	
	-- draw the owner's name of any entity we look at during HUDPaint
	hook.Add( "HUDPaint", "DrawOwner", function()
	
		if ( !IsValid( LocalPlayer() ) ) then return end
		
		local ent = LocalPlayer():GetEyeTrace().Entity -- get the entity we're looking at
		if ( !IsValid( ent ) or ent:IsPlayer() ) then return end
		
		local owner = ent:GetNetVar( "Owner", "N/A" ) -- get the owner's name, but if it hasn't been networked to us yet, use N/A
		
		surface.SetFont( "default" )
		local w, h = surface.GetTextSize( owner )
		local x = ScrW() - w - 15
		local y = ScrH() / 2.3
		
		draw.SimpleText( owner, "default", x, y, color_white, 0, 0 )
	
	end )
	-- As soon as the server called ent:SetNetVar( "Owner", ply:Nick() ), the owner's name would be broadcasted to all clients.
	-- The moment we look at the prop after it has been spawned, we'll be able to get the networked name with ent:GetNetVar( "Owner" ).
	
end






--[[-------------------------------------------]]--
--                 Net Requests
--[[-------------------------------------------]]--

if ( SERVER ) then
	
	-- when a player spawns a prop, assign the owner's name to it with ent:SetNetRequest()
	hook.Add( "PlayerSpawnedProp", "AssignOwner", function( ply, mdl, ent )
	
		ent:SetNetRequest( "Owner", ply:Nick() ) -- stores the value but does not network it

	end )
	
elseif ( CLIENT ) then
	
	-- draw the owner's name of any entity we look at during HUDPaint
	hook.Add( "HUDPaint", "DrawOwner", function()
	
		if ( !IsValid( LocalPlayer() ) ) then return end
		
		local ent = LocalPlayer():GetEyeTrace().Entity -- get the entity we're looking at
		if ( !IsValid( ent ) or ent:IsPlayer() ) then return end
		
		local owner = ent:GetNetRequest( "Owner" ) -- get the owner's name
		if ( !owner ) then ent:SendNetRequest( "Owner" ) end -- if the owner's name hasn't been networked to us yet, send a Net Request that asks for it
		
		owner = owner or "N/A" -- until we have the actual owner's name, we can just use N/A
		
		surface.SetFont( "default" )
		local w, h = surface.GetTextSize( owner )
		local x = ScrW() - w - 15
		local y = ScrH() / 2.3
		
		draw.SimpleText( owner, "default", x, y, color_white, 0, 0 )
	
	end )
	-- when ent:SendNetRequest( "Owner" ) is used on the client, the client will ask the server if it has any data stored on the entity at the key "Owner"
	-- if it does, it will reply with the value and the client will automatically use ent:SetNetRequest( "Owner", value ) so that any
	-- subsequent calls to ent:GetNetRequest( "Owner" ) returns the value
	
end
