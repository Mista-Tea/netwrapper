==================
    NetWrapper
==================

The netwrapper library is a simple wrapper over the net library to provide lightweight 
networking without hassle of dealing with raw net messages or using ENTITY:SetNW* functions.

The netwrapper library only networks data on an entity when the data is changed or added with
ENTITY:SetNetVar( key, value ) from the server. By broadcasting net messages only when 
the data changes, this library has a relatively low impact on network traffic.

The netwrapper library takes away the hassle of handling net messages directly 
by using a single net message to automatically read and write the corresponding 
values you are networking. Once these values have been broadcasted, all connected 
clients will be able to retrieve the values like you would with the standard networking libraries.

Setting networked values:
	ENTITY:SetNetVar( key, value )
	
Getting networked values:
	ENTITY:GetNetVar( key, default )
	
Where 'default' is the default value you would like returned if the key doesn't exist.
 If default isn't provided and the key doesn't exist, nil will be returned.

[EXAMPLE] To set a networked variable on a connected player, you could
 do the following on from your server console:
	
	Entity(1):SetNetVar( "TeamName", "Example Team" )
	
Now the player (Entity(1)) has a networked variable with the key "TeamName" 
and the value "Example Team". We can retrieve this value on both the server
and client by doing the following:

	local teamName = Entity(1):GetNetVar( "TeamName" )
	
This will return "Example Team". If we were to reassign this value to:

	Entity(1):SetNetVar( "TeamName", "Another Example" )

Any subsequent calls to Entity(1):GetNetVar( "TeamName" ) will return "Another Example".

===================
QUESTIONS & ANSWERS
===================
------------------------------------------------------------------------------------------------------------------------------
| Q: What sort of data can I network with this library?                                                                      |
| -------------------------------------------------------------------------------------------------------------------------- |
| A: Since this is a wrapper library over the standard net library, all limitations of the net library apply here.           |
|       For example, you can't network functions or user data.                                                               |
|                                                                                                                            |
|       What you CAN network:                                                                                                |
|               nil                                                                                                          |
|               string                                                                                                       |
|               number                                                                                                       |
|               table                                                                                                        |
|               bool                                                                                                         |
|               entity                                                                                                       |
|               vector                                                                                                       |
|               angle                                                                                                        |
------------------------------------------------------------------------------------------------------------------------------
| Q: How often is the data networked?                                                                                        |
| -------------------------------------------------------------------------------------------------------------------------- | 
| A: Every time you use SetNetVar on an entity, the data will be networked to any clients using net messages.                |
|                                                                                                                            |
| Instead of constantly syncing the data even when the data hasn't changed, theoretically reducing network traffic.          |
|                                                                                                                            |
| If you set a value on a player and then change the value 5 minutes later, the data will have been broadcasted only 2 times |
| over the span of the last 5 minutes.                                                                                       |
|                                                                                                                            |
| However, this does mean that if you use SetNetVar in a think hook, it will be broadcasting net messages on every think.    |
|                                                                                                                            |
| As with any other function, be sure to set networked data only as often as you need to. Think hooks should typically be    |
| avoided if you plan on networking large amounts of data on large amounts of entities/players.                              |
------------------------------------------------------------------------------------------------------------------------------
| Q: What happens when clients connect after the data has already been broadcasted?                                          |
| -------------------------------------------------------------------------------------------------------------------------- |
| A: When a client fully initializes on the server (during the InitPostEntity hook), they will send a net message to         |
| the server that requests any data that is currently being networked on entities.                                           |
|                                                                                                                            |
| So, if a new player was to connect after we've already been networking Player 1's TeamName, the connecting client will     |
| receive the data that was networked on Player 1. Once they've received the value, using Entity(1):GetNetVar( "TeamName" )  |
| will return the last networked value we set on them.                                                                       |
------------------------------------------------------------------------------------------------------------------------------
| Q: What happens to the networked data on a player that disconnected, or an entity that was removed?                        |
| -------------------------------------------------------------------------------------------------------------------------- |
A: When a player disconnects or an entity is removed, their state will be changed to NULL in our table that holds            |
all of the entities and values currently being networked. This occurs automatically.                                         |
| -------------------------------------------------------------------------------------------------------------------------- |
The next time that a player connects and asks the server for all networked entities, the server will loop through            |
all of the entities and remove any NULL references that it finds, including any disconnected players or removed              |
entities.                                                                                                                    |
| -------------------------------------------------------------------------------------------------------------------------- |
| Because of this automatic sensitization of the netwrapper.ents table, you don't have to worry about accidentally using     |
| NULL references to your connecting players.                                                                                |
------------------------------------------------------------------------------------------------------------------------------