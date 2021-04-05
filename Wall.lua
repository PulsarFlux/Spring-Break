require "class"
require "Vector"

Wall = class:new()

Wall.vPos = Vector:new(0, 0)

Wall.vSize = Vector:new(100, 100)

function Wall:Init(vPos, vSize)
    self.vPos = vPos
    self.vSize = vSize
end

function Wall:Collides(vPos, vSize)
    if (vPos.x + vSize.x > self.vPos.x and vPos.x < self.vPos.x + self.vSize.x) and
        (vPos.y + vSize.y > self.vPos.y and vPos.y < self.vPos.y + self.vSize.y)
    then
        return true
    end
    return false
end

function Wall:GetClosest(vPos, vSize)
    local closest = Vector:new()
    
    local x1 = (self.vPos.x + self.vSize.x) - vPos.x
    local x2 = self.vPos.x - (vPos.x + vSize.x)

    if math.abs(x1) < math.abs(x2) then
        closest.x = x1
    else
        closest.x = x2
    end

    local y1 = (self.vPos.y + self.vSize.y) - vPos.y
    local y2 = self.vPos.y - (vPos.y + vSize.y)

    if math.abs(y1) < math.abs(y2) then
        closest.y = y1
    else
        closest.y = y2
    end

    return closest
end