NetWrapper
==========

The NetWrapper library is a simple wrapper over Garry's standard net library to provide lightweight 
networking without needing to care about the type of data you are networking (unlike the ENTITY:SetNetworked* library)
and without needing to create dozens of networked strings for net messages.

There are 2 ways to network data with the NetWrapper library:
* Net Vars
* Net Requests

#### Net Vars
If you are looking to replace your existing scripts' use of the ENTITY:SetNW*/ENTITY:SetDT* functions, Net Vars
are the way to go.

With Net Vars, data set on entities is only networked when the data is added or changed with
ENTITY:SetNetVar( key, value ) from the server. By broadcasting net messages only when 
the data changes, this library has a relatively low impact on network traffic.

Once these values have been broadcasted, all connected clients will be able to retrieve the values like you 
would with the standard networking libraries.

* Setting networked values:

```
-- if run on the server, this key/value pair will be networked to all clients
ENTITY:SetNetVar( key, value )
```

* Getting networked values:

```
-- if run on the client, this will attempt to grab the value stored at the key
ENTITY:GetNetVar( key, default )
```
	
Where 'default' is the default value you would like returned if the key doesn't exist.
If a default value isn't provided and the key doesn't exist, nil will be returned.

##### Example:

If you wanted to network a title on a player when they connect, you could do something like the following:
```
hook.Add( "PlayerInitialSpawn", "SetPlayerTitle", function( ply )
    local title = ... -- grab the title somewhere
    ply:SetNetVar( "Title", title )
end )
```
As soon as ply:SetNetVar() is called, a net message will be broadcasted to all connected clients with the
key/value pair for the title.

If you wanted to show the player's title in a GM:PostPlayerDraw hook, you could do something like the following:
```
hook.Add( "PostPlayerDraw", "ShowPlayerTitle", function( ply )
    -- retrieve the player's title if one has been networked, otherwise returns nil
    -- if a title hasn't been networked yet, don't try drawing it
    
    local title = ply:GetNetVar( "Title" )
    if ( !title ) then return end 
    
    draw.SimpleText( title, ...  -- etc

end )
```

#### Net Requests
Net Requests are a new feature in the NetWrapper library. They allow you to determine exactly when a client asks the server
for a value to be networked to them by using ENTITY:SendNetRequest( key ). 

If the server has set data on the entity with ENTITY:SetNetRequest( key, value ), the value will be sent back to the client
when they request it. If the server has not set any data on the entity at the given key, the client will keep sending requests
(as long as you use ENTITY:SendNetRequest( key ) again) until they have either reached the maximum amount of requests that can
be sent per entity+key (netwrapper_max_requests cvar) or the value has been set by the server.

This is especially useful if you have hundreds or thousands of entities spawned out when clients join the server. If you networked
a value using ENTITY:SetNetVar() on every entity, that means that the client will receive hundreds or thousands of net messages to
sync all of the Net Vars when they initialize during GM:InitPostEntity. However, by using Net Requests instead you can network data
to the client only when they ask for it (such as when they look directly at it).

* Setting net requests:

```
ENTITY:SetNetRequest( key, value ) -- if run on the server, this key/value pair will be stored in a serverside table that the client can request from
```
	
* Getting net requests:

```
ENTITY:SendNetRequest( key ) -- when run on the client, this will send a net message to the server asking for the value stored on the entity at the given key
ENTITY:GetNetRequest( key, default ) -- once the client has received the value from the server, subsequent calls to ENTITY:GetNetRequest() will return the value
```

Where 'default' is the default value you would like returned if the key doesn't exist.
If a default value isn't provided and the key doesn't exist, nil will be returned.
	
##### Example:

If you want to network the owner's name on props but don't want to flood connecting clients with hundreds of possible net messages, 
you can do something like the following:
```
-- some serverside function that pairs up the player with the entity they spawned
ent:SetNetRequest( "Owner", ply:Nick() )
```

Now the value has been stored in the netwrapper.requests table and can be accessed by clients when they request it:
```
-- somewhere clientside
local owner = ent:GetNetRequest( "Owner" )
if ( !owner ) then ent:SendNetRequest( "Owner" ) end
```

Assuming you use the above in a HUDPaint hook or something that gets repeatedly gets called, this will check to see if the 'Owner' value has
already been requested from the server. If it hasn't (and therefore returns nil), ent:SendNetRequest( "Owner" ) is called which sends a request
to the server asking for the value stored at the 'Owner' key.

Since the 'Owner' was set earlier, the server will reply to the client's request by sending a net message back with the entity and key/value pair.
When the clients receives the message, the value is stored in the netwrapper.requests table and will be retrieved with any subsequent calls to ent:GetNetRequest( "Owner" ).

QUESTIONS & ANSWERS
-------------------

### Q: What sort of data can I network with this library? 

A: Since this is a wrapper library over the standard net library, all limitations of the net library apply here.
For example, you can't network functions or user data.

What you CAN network:
* nil
* strings
* numbers
* tables
* booleans
* entities
* vectors
* angles

---------------------------------------------------------------------------------------------------------------------------
### Q: How often is the data networked? 

A: 
##### For Net Vars:
Every time you use ENTITY:SetNetVar( key, value ) from the server, the data will be networked to any clients via net message.

If you set a value on a player and then change that value 5 minutes later, the data will have been broadcasted only 2 times
over the span of that 5 minutes.

However, this does mean that if you use ENTITY:SetNetVar( key value ) in a think hook, it will be broadcasting net messages every frame. 

As with any other function, be sure to set networked data only as often as you need to. Think hooks should typically be 
avoided if you plan on networking large amounts of data on a large amount of entities/players.

##### For Net Requests:
Whereas Net Vars are automatically broadcasted to connected clients, and synced to connecting clients during GM:InitPostEntity, Net Requests are only networked
on a 'need-to-know' basis, which significantly reduces the amount of network traffic that connecting players receive.

---------------------------------------------------------------------------------------------------------------------------
### Q: What happens when clients connect after the data has already been broadcasted? 

A: 
##### For Net Vars:
When a client fully initializes on the server (during the GM:InitPostEntity hook, clientside), they will send a net message to
the server that requests any data that is currently being networked on any entities.

This happens automatically so that you don't have to rebroadcast the data yourself.

##### For Net Requests:
Net Requests are not networked to the client unless they specifically ask the server for a value from an entity. You must manually
use ENTITY:SendNetRequest( key ) to network the value.

---------------------------------------------------------------------------------------------------------------------------
### Q: What happens to the networked data on a player that disconnected, or an entity that was removed? 

A: When a player disconnects or an entity is removed, the netwrapper library will automatically sanitize its tables by 
using the GM:EntityRemoved hook on the server and removing any data it currently has networked with that entity. The server will then send a net message to the client informing them to sanitize their clientside tables.
