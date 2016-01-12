# Graphoon

A force directed graph algorithm written in Lua.

## Introduction

_Graphoon_ emerged from the graph calculation code used in both [LoGiVi](https://github.com/rm-code/logivi) and [LoFiVi](https://github.com/rm-code/lofivi).

A force directed graph layout is achieved by simulating physical forces, which push and pull each node in the graph until a nice layout is found.

## Basic Usage

The basic idea is that you create a new graph object, to which you can then add nodes and edges.

```lua
local GraphLibrary = require('Graphoon').Graph

graph = GraphLibrary.new()
graph:addNode( "Ash Williams" )
graph:addNode( "Necronomicon" )
graph:connectIDs( "Ash Williams", "Necronomicon" )
```

By itself Graphoon only provides functionality for creating the graph and calculating the layout based on physical attraction and repulsion forces.

It provides a ```draw``` and ```update``` function, which can be used to easily write your own rendering code.

The ```draw``` function should be called with two callback functions. The first callback will be used for all nodes and the second one for all the edges.

```lua
graph:draw( function( node )
				local x, y = node:getPosition()
				drawCircle( 'fill', x, y, 10 )
			end,
			function( edge )
				local ox, oy = edge.origin:getPosition()
				local tx, ty = edge.target:getPosition()
				drawLine( ox, oy, tx, ty )
			end)
```

At its simplest the force calculations can be updated via ```graph:update( dt )```, but the ```update``` function also can receive optional callbacks for both nodes and edges.

## Advanced usage

### Using anchors

Anchors can be used to attach a node to a certain position on the screen. This can be useful if you want to center a certain node for example.

This can either be done directly via the constructor of the node:

```lua
-- Anchor the node to the center of the screen.
graph:addNode( "Ash Williams", screenX * 0.5, screenY * 0.5, true )
```

Or by using the ```setAnchor``` function:

```lua
-- Invert anchor status
node:setAnchor( not node:isAnchor(), mouseX, mouseY )
```
