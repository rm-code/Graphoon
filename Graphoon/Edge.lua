local current = (...):gsub('%.[^%.]+$', '');

local Edge = {};

function Edge.new( id, origin, target )
    local self = {};

    self.id = id;
    self.origin = origin;
    self.target = target;

    return self;
end

return Edge;
