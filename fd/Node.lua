local current = (...):gsub('%.[^%.]+$', '');

local Node = {};

local FORCE_SPRING = -0.01;
local FORCE_CHARGE = 100000;

local FORCE_MAX = 4;
local NODE_SPEED = 8;
local DAMPING_FACTOR = 0.95;

local DEFAULT_MASS = 0.05;

---
-- @param id - A unique id which will be used to reference this node.
-- @param x  - The x coordinate the Node should be spawned at (optional).
-- @param y  - The y coordinate the Node should be spawned at (optional).
-- @param anchor - Wether the node should be locked in place or not (optional).
--
function Node.new( id, x, y, anchor, ... )
    local self = {};

    local px, py = x or 0, y or 0;
    local ax, ay = 0, 0;
    local vx, vy = 0, 0;
    local mass = DEFAULT_MASS;

    ---
    -- Clamps a value to a certain range.
    -- @param min
    -- @param val
    -- @param max
    --
    local function clamp( min, val, max )
        return math.max( min, math.min( val, max ) );
    end

    ---
    -- Calculates the new xy-acceleration for this node.
    -- The values are clamped to keep the graph from "exploding".
    -- @param fx - The force to apply in x-direction.
    -- @param fy - The force to apply in y-direction.
    --
    local function applyForce( fx, fy )
        ax = clamp( -FORCE_MAX, ax + fx, FORCE_MAX );
        ay = clamp( -FORCE_MAX, ay + fy, FORCE_MAX );
    end

    ---
    -- Attract this node to another node.
    -- @param node - The node to use for force calculation.
    --
    function self:attractTo( node )
        local dx, dy = px - node:getX(), py - node:getY();
        local distance = math.sqrt(dx * dx + dy * dy);
        dx = dx / distance;
        dy = dy / distance;

        local strength = FORCE_SPRING * distance;
        applyForce( dx * strength, dy * strength );
    end

    ---
    -- Repel this node from another node.
    -- @param node - The node to use for force calculation.
    --
    function self:repelFrom( node )
        local dx, dy = px - node:getX(), py - node:getY();
        local distance = math.sqrt(dx * dx + dy * dy);
        dx = dx / distance;
        dy = dy / distance;

        local strength = FORCE_CHARGE * ( mass / ( distance * distance ));
        applyForce(dx * strength, dy * strength);
    end

    ---
    -- Update the node's position based on the calculated velocity and
    -- acceleration.
    -- @param dt - The delta time between frames.
    --
    function self:move( dt )
        vx = (vx + ax * dt * NODE_SPEED) * DAMPING_FACTOR;
        vy = (vy + ay * dt * NODE_SPEED) * DAMPING_FACTOR;
        px = px + vx;
        py = py + vy;
        ax, ay = 0, 0;
    end

    function self:getID()
        return id;
    end

    function self:getX()
        return px;
    end

    function self:getY()
        return py;
    end

    function self:getPosition()
        return px, py;
    end

    function self:setPosition( nx, ny )
        px, py = nx, ny;
    end

    function self:setAnchor( nanchor )
        anchor = nanchor;
    end

    function self:isAnchor()
        return anchor;
    end

    function self:setMass( nmass )
        mass = nmass;
    end

    return self;
end

return Node;
