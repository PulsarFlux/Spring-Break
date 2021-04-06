require "Guard"
require "Room"

GuardManager = class:new()

GuardManager.tViewConeColour = { 0.5, 0.5, 0.5, 0.2}

function GuardManager:Init(tImageBank, tRooms)
    self.tGuards = {}

    for i, room in ipairs(tRooms) do
        -- Dont put guard in first room or corridors
        if i ~= 1 and not room.bIsCorridor then
            self.tGuards[#self.tGuards + 1] = Guard:new()
            self.tGuards[#self.tGuards]:Init(tImageBank, room)
        end
    end
end

function GuardManager:Update(dt, cMainChar, cCurrentRoom)
    local bCharIsSpotted = false

    for i, guard in ipairs(self.tGuards) do
        bCharIsSpotted = bCharIsSpotted or guard:Update(dt, cMainChar, cCurrentRoom)
    end

    return bCharIsSpotted
end

function GuardManager:Draw()
    for i, guard in ipairs(self.tGuards) do
        guard:DrawGuard()
    end

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(self.tViewConeColour)

    for i, guard in ipairs(self.tGuards) do
        guard:DrawViewCone()
    end

    love.graphics.setColor(r, g, b, a)
end