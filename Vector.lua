Vector = {}

function Vector:new(x, y)
    local object = { x = x or 0, y = y or 0 }
    setmetatable(object, self)
    self.__index = self

    self.__add = function(r, l)
        return Vector:new(r.x + l.x, r.y + l.y)
    end

    self.__sub = function(r, l)
        return Vector:new(r.x - l.x, r.y - l.y)
    end

    self.__tostring = function(object)
        return tostring(object.x) .. " " .. tostring(object.y)
    end

    return object
end

return Vector