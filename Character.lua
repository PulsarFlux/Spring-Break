require "class"
require "Vector"
require "GameImage"

Character = class:new()

Character.nSpeed = 150

Character.vPos = nil
Character.vSize = nil
Character.nSize = 25

function Character:Init(cInput, tImageBank, vPos)
    self.cInput = cInput

    self.vPos = vPos or Vector:new(0, 0)
    self.vLastPos = Vector:new(0, 0)
    self.vSize = Vector:new(self.nSize, self.nSize)

    local imagePos = Vector:new(self.vPos.x, self.vPos.y)

    self.cImage = GameImage:new()
    self.cImage:Init(tImageBank, imagePos, self.vSize, "character")

    self.cPrisonerImage = GameImage:new()
    self.cPrisonerImage:Init(tImageBank, imagePos, self.vSize, "prisoner")

    self.nAngle = 0
end

function Character:Move(dt, vScreenCentre)

    self.vLastPos.x = self.vPos.x
    self.vLastPos.y = self.vPos.y

    local nMovement = dt * self.nSpeed

    if self.cInput:Right() then
        self.vPos.x = self.vPos.x + nMovement
    end

    if self.cInput:Left() then
        self.vPos.x = self.vPos.x - nMovement
    end

    if self.cInput:Up() then
        self.vPos.y = self.vPos.y - nMovement
    end

    if self.cInput:Down() then
        self.vPos.y = self.vPos.y + nMovement
    end

    self:UpdateImage()

    -- Assuming now screen is character aliged
    local mouseRelPos = self.cInput:MousePos() - vScreenCentre

    if mouseRelPos.x == 0 then
        if mouseRelPos.y > 0 then
            self.nAngle = math.pi / 2
        else
            self.nAngle = -math.pi / 2
        end
    else
        self.nAngle = math.atan(mouseRelPos.y / mouseRelPos.x)

        if mouseRelPos.x < 0 then
            self.nAngle = math.pi + self.nAngle
        end
    end

    self.cImage.nAngle = self.nAngle
    self.cPrisonerImage.nAngle = self.nAngle
end

function Character:UpdateImage()
    self.cImage.vPos.x = self.vPos.x
    self.cImage.vPos.y = self.vPos.y

    self.cPrisonerImage.vPos.x = self.vPos.x
    self.cPrisonerImage.vPos.y = self.vPos.y
end

function Character:Draw()

    if self.bHasPrisoner then
        self.cPrisonerImage:Draw(true)
    end

    self.cImage:Draw()
end

-- Box for collisions
function Character:GetCurrentBox()
    return self:_GetBox(self.vPos)
end

-- Box for collisions
function Character:GetLastBox()
    return self:_GetBox(self.vLastPos)
end

-- Box for collisions
function Character:_GetBox(vPos)
    local box = {}
    box.vPos = Vector:new(vPos.x - self.vSize.x / 2, vPos.y - self.vSize.y / 2)
    box.vSize = Vector:new(self.vSize.x, self.vSize.y)

    return box
end
