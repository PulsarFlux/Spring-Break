require "class"
require "Vector"

PhysicsManager = class:new()

function PhysicsManager:Init()
    self.tWalls = {}
end

function PhysicsManager:AddWall(cWall)
    self.tWalls[#self.tWalls + 1] = cWall
end

function PhysicsManager:Run(cMainChar)
    self:RunWallCollision(cMainChar, self.tWalls)

    cMainChar:UpdateImage()
end

function PhysicsManager:RunWallCollision(cMainChar, tWalls)

    local charBox = cMainChar:GetCurrentBox()

    local collidingWalls = {}

    for i, wall in ipairs(self.tWalls) do
        if wall:Collides(charBox.vPos, charBox.vSize) then
            collidingWalls[#collidingWalls + 1] = wall
        end
    end

    local minDistX = nil
    local minDistY = nil
    local closestWallX = nil
    local closestWallY = nil

    local lastCharBox = cMainChar:GetLastBox()

    if #collidingWalls > 0 then
        for i, wall in ipairs(collidingWalls) do
            local dist = wall:GetClosest(lastCharBox.vPos, lastCharBox.vSize)
            if not minDistX or math.abs(dist.x) < math.abs(minDistX) then
                minDistX = dist.x
                closestWallX = wall
            end
            if not minDistY or math.abs(dist.y) < math.abs(minDistY) then
                minDistY = dist.y
                closestWallY = wall
            end
        end

        local charDir = cMainChar.vPos - cMainChar.vLastPos
        local collisionTimeX = charDir.x ~= 0 and math.abs(minDistX / charDir.x) or 10000
        local collisionTimeY = charDir.y ~= 0 and math.abs(minDistY / charDir.y) or 10000

        if collisionTimeX < collisionTimeY then
            local newX = cMainChar.vLastPos.x + minDistX
            cMainChar.vLastPos.x = newX
            cMainChar.vPos.x = newX
        else
            local newY = cMainChar.vLastPos.y + minDistY
            cMainChar.vLastPos.y = newY
            cMainChar.vPos.y = newY
        end

        if #collidingWalls > 1 then
            -- If we hit multiple walls, rerun collisions from the new
            -- position so that we handle colliding with different walls
            -- on different axes in one update.
            -- It should not be possible to get stuck calling this since
            -- we should only be able to colide with one wall per dimension
            -- and hence the second call should only find at most 1 wall.
            self:RunWallCollision(cMainChar, collidingWalls)
        end
    end
end

function PhysicsManager:Draw()

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor({1, 0, 0, 1})

    for i, wall in ipairs(self.tWalls) do
        love.graphics.rectangle("line", wall.vPos.x, wall.vPos.y, wall.vSize.x, wall.vSize.y)
    end

    love.graphics.setColor(r, g, b, a)
end