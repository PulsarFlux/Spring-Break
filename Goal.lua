require "class"
require "Vector"
require "GameImage"

Goal = class:new()

Goal.tGoalTypes =
{
    ["prisoner"] = 
    {
        ["Size"] = Vector:new(30, 30),
        ["ImageSize"] = Vector:new(25, 25),
        ["ImageName"] = "prisoner",
    },

    ["exit"] = 
    {
        ["Size"] = Vector:new(50, 50),
        ["ImageSize"] = Vector:new(25, 25),
        ["ImageName"] = "",
    },
}

function Goal:Init(tImageBank, vGoalPos, sType)
    self.sType = sType
    self.vPos = vGoalPos
    self.vSize = self.tGoalTypes[sType].Size

    if self.tGoalTypes[sType].ImageName ~= "" then
        self.cImage = GameImage:new()
        self.cImage:Init(tImageBank, self.vPos, self.tGoalTypes[sType].ImageSize, self.tGoalTypes[sType].ImageName)
    end

    self.bAchieved = false
end

function Goal:Check(cMainChar)

    if not self.bAchieved then

        local box = cMainChar:GetCurrentBox()
        local vPos = box.vPos
        local vSize = box.vSize

        if (vPos.x + vSize.x > self.vPos.x and vPos.x < self.vPos.x + self.vSize.x) and
            (vPos.y + vSize.y > self.vPos.y and vPos.y < self.vPos.y + self.vSize.y)
        then
            if self.sType == "prisoner" then
                self.bAchieved = true
                cMainChar.bHasPrisoner = true
                return false
            end
            if self.sType == "exit" and cMainChar.bHasPrisoner then
                self.bAchieved = true
                return true
            end
        end
            
        return false
    end

    return false
end

function Goal:Draw()
    if not self.bAchieved then
        if self.cImage then
            self.cImage:Draw()
        end

        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor({0, 1, 0, 1})

        love.graphics.rectangle(
            "line", 
            self.vPos.x - self.vSize.x / 2, 
            self.vPos.y - self.vSize.y / 2,
            self.vSize.x, self.vSize.y
        )

        love.graphics.setColor(r, g, b, a)
    end
end