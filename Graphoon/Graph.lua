local current = (...):gsub('%.[^%.]+$', '');

-- ------------------------------------------------
-- Required Modules
-- ------------------------------------------------

local Node = require(current .. '.Node');
local Edge = require(current .. '.Edge');

-- ------------------------------------------------
-- Module
-- ------------------------------------------------

local Graph = {};

function Graph.new()
    local self = {};

    local nodes = {};   -- Contains all nodes in the graph.
    local edges = {};   -- Contains all edges in the graph.
    local edgeIDs = 0;  -- Used to create a unique ID for new edges.

    local minX, maxX, minY, maxY; -- The boundaries of the graph.

    -- ------------------------------------------------
    -- Local Functions
    -- ------------------------------------------------

    ---
    -- (Re-)Sets the graph's boundaries to nil.
    --
    local function resetBoundaries()
        minX, maxX, minY, maxY = nil, nil, nil, nil;
    end

    ---
    -- Updates the boundaries of the graph.
    -- This represents the rectangular area in which all nodes are contained.
    -- @param minX - The current minimum x position.
    -- @param maxX - The current maximum y position.
    -- @param minY - The current minimum x position.
    -- @param maxY - The current maximum y position.
    -- @param nx - The new x position to check.
    -- @param ny - The new y position to check.
    --
    local function updateBoundaries( minX, maxX, minY, maxY, nx, ny )
        return math.min( minX or nx, nx ), math.max( maxX or nx, nx ), math.min( minY or ny, ny ), math.max( maxY or ny, ny );
    end

    ---
    -- Adds a new edge between two nodes.
    -- @param origin - The node from which the edge originates.
    -- @param target - The node to which the edge is pointing to.
    --
    local function addEdge( origin, target )
        for _, edge in pairs( edges ) do
            if edge.origin == origin and edge.target == target then
                error "Trying to connect nodes which are already connected.";
            end
        end

        assert( origin ~= target, "Tried to connect a node with itself." );
        edges[edgeIDs] = Edge.new( edgeIDs, origin, target );
        edgeIDs = edgeIDs + 1;
    end

    -- ------------------------------------------------
    -- Public Functions
    -- ------------------------------------------------

    ---
    -- Adds a node to the graph.
    -- @param id - The ID will be used to reference the Node inside of the graph.
    -- @param x  - The x coordinate the Node should be spawned at (optional).
    -- @param y  - The y coordinate the Node should be spawned at (optional).
    -- @param anchor - Wether the node should be locked in place or not (optional).
    -- @param ... - Additional parameters (useful when a custom Node class is used).
    --
    function self:addNode( id, x, y, anchor, ... )
        assert( not nodes[id], "Node IDs must be unique." );
        nodes[id] = Node.new( id, x, y, anchor, ... );
        return nodes[id];
    end

    ---
    -- Removes a node from the graph.
    -- This will also remove all edges pointing to, or originating from this
    -- node.
    -- @param node - The node to remove from the graph.
    --
    function self:removeNode( node )
        nodes[node:getID()] = nil;

        self:removeEdges( node );
    end

    ---
    -- Adds a new edge between two nodes.
    -- @param origin - The node from which the edge originates.
    -- @param target - The node to which the edge is pointing to.
    --
    function self:connectNodes( origin, target )
        addEdge( origin, target );
    end

    ---
    -- Adds a new edge between two nodes referenced by their IDs.
    -- @param origin - The node id from which the edge originates.
    -- @param target - The node id to which the edge is pointing to.
    --
    function self:connectIDs( originID, targetID )
        assert( nodes[originID], string.format( "Tried to add an Edge to the nonexistent Node \"%s\".", originID ));
        assert( nodes[targetID], string.format( "Tried to add an Edge to the nonexistent Node \"%s\".", targetID ));
        addEdge( nodes[originID], nodes[targetID] );
    end

    ---
    -- Removes all edges leading to, or originating from a node.
    -- @param node - The node to remove all edges from.
    --
    function self:removeEdges( node )
        for id, edge in pairs( edges ) do
            if edge.origin == node or edge.target == node then
                edges[id] = nil;
            end
        end
    end

    ---
    -- Updates the graph.
    -- @param dt - The delta time between frames.
    -- @param nodeCallback - A callback called on every node (optional).
    -- @param edgeCallback - A callback called on every edge (optional).
    --
    function self:update( dt, nodeCallback, edgeCallback )
        for _, edge in pairs( edges ) do
            edge.origin:attractTo( edge.target );
            edge.target:attractTo( edge.origin );

            if edgeCallback then
                edgeCallback( edge );
            end
        end

        resetBoundaries();

        for _, nodeA in pairs( nodes ) do
            if not nodeA:isAnchor() then
                for _, nodeB in pairs( nodes ) do
                    if nodeA ~= nodeB then
                        nodeA:repelFrom( nodeB );
                    end
                end
                nodeA:move( dt );
            end

            if nodeCallback then
                nodeCallback( nodeA );
            end

            minX, maxX, minY, maxY = updateBoundaries( minX, maxX, minY, maxY, nodeA:getPosition() );
        end
    end

    ---
    -- Draws the graph.
    -- Takes two callback functions as a parameter. These will be called
    -- on each edge and node in the graph and will be used to wite a custom
    -- drawing function.
    -- @param nodeCallback - A callback called on every node.
    -- @param edgeCallback - A callback called on every edge.
    --
    function self:draw( nodeCallback, edgeCallback )
        for _, edge in pairs( edges ) do
            if not edgeCallback then break end
            edgeCallback( edge );
        end

        for _, node in pairs( nodes ) do
            if not nodeCallback then break end
            nodeCallback( node );
        end
    end

    ---
    -- Checks if a certain Node ID already exists.
    -- @param id - The id to check for.
    --
    function self:hasNode( id )
        return nodes[id] ~= nil;
    end

    ---
    -- Returns the node the id is pointing to.
    -- @param id - The id to check for.
    --
    function self:getNode( id )
        return nodes[id];
    end

    ---
    -- Gets a node at a certain point in the graph.
    -- @param x - The x coordinate to check.
    -- @param y - The y coordinate to check.
    -- @param range - The range in which to check around the given coordinates.
    --
    function self:getNodeAt(x, y, range)
        for _, node in pairs( nodes ) do
            local nx, ny = node:getPosition();
            if x < nx + range and x > nx - range and y < ny + range and y > ny - range then
                return node;
            end
        end
    end

    ---
    -- Returns the graph's minimum and maxmimum x and y values.
    --
    function self:getBoundaries()
        return minX, maxX, minY, maxY;
    end

    ---
    -- Returns the x and y coordinates of the graph's center.
    --
    function self:getCenter()
        return ( ( maxX - minX ) * 0.5 ) + minX, ( ( maxY - minY ) * 0.5 ) + minY;
    end

    ---
    -- Turn a node into an anchor.
    -- Anchored nodes have fixed positions and can't be moved by the physical
    -- forces.
    -- @param id - The node's id.
    -- @param x  - The x coordinate to anchor the node to.
    -- @param y  - The y coordinate to anchor the node to.
    --
    function self:setAnchor( id, x, y )
        nodes[id]:setPosition( x, y );
        nodes[id]:setAnchor( true );
    end

    return self;
end

---
-- Replaces the default Edge class with a custom one.
-- @param class - The custom Edge class to use.
--
function Graph.setEdgeClass( class )
    Edge = class;
end

---
-- Replaces the default Node class with a custom one.
-- @param class - The custom Node class to use.
--
function Graph.setNodeClass( class )
    Node = class;
end

return Graph;
