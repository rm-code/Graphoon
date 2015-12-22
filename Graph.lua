local Node = require('Node');
local Edge = require('Edge');

local Graph = {};

-- TODO remove / replace LÖVE functions
function Graph.new()
    local self = {};

    -- Node Objects are stored in a table using their ID as an index.
    local nodes = {};
    local edges = {};
    local edgeIDs = 0;

    local center = Node.new( 'center ', love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5);

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

        for _, id in pairs( table.nodes ) do
            local rx, ry = math.random( x, w ), math.random( y, h );
            self:addNode( Node.new( id, rx, ry ));
        end

        for _, edge in pairs( table.edges ) do
            self:addEdge( nodes[edge.origin], nodes[edge.target] );
        end
    end

    function self:addNode( node )
        assert( not nodes[node:getID()], "Node IDs must be unique." );
        nodes[node:getID()] = node;
    end

    function self:removeNode( node )
        nodes[node:getID()] = nil;

        self:removeEdges( node );
    end

    function self:addEdge( origin, target )
        for _, edge in pairs(edges) do
            if edge.origin == origin and edge.target == target then
                error "Trying to connect nodes which are already connected.";
            end
        end

        assert(origin ~= target, "Tried to connect a node with itself.");
        edges[edgeIDs] = Edge.new( edgeIDs, origin, target );
        edgeIDs = edgeIDs + 1;
    end

    function self:removeEdges( node )
        for id, edge in pairs( edges ) do
            if edge.origin == node or edge.target == node then
                edges[id] = nil;
            end
        end
    end

    function self:update( dt, ... )
        for _, edge in pairs( edges ) do
            edge.origin:attractTo( edge.target );
            edge.target:attractTo( edge.origin );
        end

        for _, nodeA in pairs( nodes ) do
            nodeA:attractTo( center );
            for _, nodeB in pairs( nodes ) do
                if nodeA ~= nodeB then
                    nodeA:repelFrom( nodeB );
                end
            end
            nodeA:move( dt );
        end
    end

    function self:draw()
        for _, edge in pairs( edges ) do
            love.graphics.line( edge.origin:getX(), edge.origin:getY(), edge.target:getX(), edge.target:getY() );
        end

        for _, nodeA in pairs( nodes ) do
            love.graphics.points( nodeA:getX(), nodeA:getY() );
            love.graphics.print( nodeA:getID(), nodeA:getX(), nodeA:getY() );
        end
    end

    function self:getNodeAt(x, y, range)
        for _, node in pairs( nodes ) do
            local nx, ny = node:getPosition();
            if x < nx + range and x > nx - range and y < ny + range and y > ny - range then
                return node;
            end
        end
    end

    return self;
end

return Graph;
