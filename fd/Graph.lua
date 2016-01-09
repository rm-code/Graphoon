local current = (...):gsub('%.[^%.]+$', '');
local Node = require(current .. '.Node');
local Edge = require(current .. '.Edge');

local Graph = {};

function Graph.new()
    local self = {};

    local nodes = {};
    local edges = {};
    local edgeIDs = 0;

    local minX, maxX, minY, maxY;

    -- ------------------------------------------------
    -- Local Functions
    -- ------------------------------------------------

    ---
    -- Sets the graph's boundaries to nil.
    --
    local function resetBoundaries()
        minX, maxX, minY, maxY = nil, nil, nil, nil;
    end

    ---
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
    -- Creates a new graph based on the information passed via the table
    -- parameter. It creates all nodes and connects them via edges.
    -- @param table - A table containing information about nodes and edges.
    -- @param x - The minimum x value to use when randomly spawning nodes.
    -- @param y - The minimum y value to use when randomly spawning nodes.
    -- @param w - The maximum x value to use when randomly spawning nodes.
    -- @param h - The maximum y value to use when randomly spawning nodes.
    --
    function self:create( table, x, y, w, h )
        math.randomseed( os.time() );

        for _, node in pairs( table.nodes ) do
            local rx, ry = math.random( x, w ), math.random( y, h );
            if type( node ) == 'string' then
                self:addNode( node, rx, ry );
            elseif type( node ) == 'table' then
                self:addNode( node.id, node.x or rx, node.y or ry, node.anchor );
            end
        end

        for _, edge in pairs( table.edges ) do
            addEdge( nodes[edge.origin], nodes[edge.target] );
        end
    end

    ---
    -- Add a node to the graph.
    -- @param id - The ID will be used to reference the Node inside of the graph.
    -- @param x  - The x coordinate the Node should be spawned at (optional).
    -- @param y  - The y coordinate the Node should be spawned at (optional).
    -- @param anchor - Wether the node should be locked in place or not (optional).
    --
    function self:addNode( id, x, y, anchor )
        assert( not nodes[id], "Node IDs must be unique." );
        nodes[id] = Node.new( id, x, y, anchor );
        return nodes[id];
    end

    ---
    -- Remove a node from the graph.
    -- This will also remove all edges pointing to or originating from this node.
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
        addEdge( nodes[originID], nodes[targetID] );
    end

    ---
    -- Removes all edges leading to or originating from a node.
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
    --
    function self:update( dt )
        for _, edge in pairs( edges ) do
            edge.origin:attractTo( edge.target );
            edge.target:attractTo( edge.origin );
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

            minX, maxX, minY, maxY = updateBoundaries( minX, maxX, minY, maxY, nodeA:getPosition() );
        end
    end

    ---
    -- Checks if the id points to an existing node.
    -- @param id - The id to check for.
    --
    function self:exists( id )
        return nodes[id] ~= nil;
    end

    ---
    -- This function receives a single parameter of type function to which it
    -- will pass the edges and nodes tables. This means the user has to provide
    -- his own drawing function.
    -- @param func - The function to pass the tables to.
    --
    function self:draw( func )
        func( edges, nodes );
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
    -- @param y  - The x coordinate to anchor the node to.
    --
    function self:setAnchor( id, x, y )
        nodes[id]:setPosition( x, y );
        nodes[id]:setAnchor( true );
    end

    return self;
end

return Graph;
