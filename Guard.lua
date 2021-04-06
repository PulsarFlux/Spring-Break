require "class"
require "Vector"
require "GameImage"

Guard = class:new()

Guard.nSpeed = 150
Guard.nTurnTime = 0.75

Guard.vPos = nil
Guard.vSize = nil
Guard.nSize = 25

Guard.nViewConeRadius = 150
Guard.nViewConeRadiusSq = Guard.nViewConeRadius * Guard.nViewConeRadius
Guard.nViewConeHalfAngle = math.pi / 4

Guard.tSpottedViewConeColour = { 1, 0, 0, 0.2}

Guard.tPhases =
{
    [1] = { ["End"] = 0.25, ["Dir"] = Vector:new(1,0), ["Angle"] = 2 * math.pi, },
    [2] = { ["End"] = 0.5, ["Dir"] = Vector:new(0,1), ["Angle"] = (math.pi / 2), },
    [3] = { ["End"] = 0.75, ["Dir"] = Vector:new(-1,0), ["Angle"] = math.pi, },
    [4] = { ["End"] = 1.0, ["Dir"] = Vector:new(0,-1), ["Angle"] = 3 * math.pi / 2, },
}

function Guard:Init(tImageBank, cRoom)

    local nStartPhase = love.math.random()

    self.cRoom = cRoom
    self.tPhaseInfos = {}
    self.bViewConeActive = false

    local vRoomPos = Vector:new(cRoom.vTilePos.x * cRoom.nTileSize, cRoom.vTilePos.y * cRoom.nTileSize)
    local vRoomWidth = Vector:new(cRoom.nWidth * cRoom.nTileSize, 0)
    local vRoomHeight = Vector:new(0, cRoom.nHeight * cRoom.nTileSize)
    local vTilePlus = Vector:new(cRoom.nTileSize, cRoom.nTileSize)
    local vTileNeg = Vector:new(-cRoom.nTileSize, cRoom.nTileSize)

    self.tPhaseInfos[1] = 
    { 
        ["Start"] = vRoomPos + vTilePlus, 
        ["End"] = vRoomPos + vRoomWidth + vTileNeg, 
        ["Length"] = cRoom.nTileSize * (cRoom.nWidth - 2)
    }
    self.tPhaseInfos[2] = 
    { 
        ["Start"] = vRoomPos + vRoomWidth + vTileNeg,
        ["End"] = vRoomPos + vRoomWidth + vRoomHeight - vTilePlus,
        ["Length"] = cRoom.nTileSize * (cRoom.nHeight - 2)
    }
    self.tPhaseInfos[3] = 
    { 
        ["Start"] = vRoomPos + vRoomWidth + vRoomHeight - vTilePlus,
        ["End"] = vRoomPos + vRoomHeight - vTileNeg, 
        ["Length"] = cRoom.nTileSize * (cRoom.nWidth - 2)
    }
    self.tPhaseInfos[4] = 
    { 
        ["Start"] = vRoomPos + vRoomHeight - vTileNeg,
        ["End"] = vRoomPos + vTilePlus,
        ["Length"] = cRoom.nTileSize * (cRoom.nHeight - 2)
    }

    for i, phase in ipairs(self.tPhases) do
        if nStartPhase <= phase.End then
            self.nCurrentPhase = i
            self.nPhaseProp = 1 - (phase.End - nStartPhase) / 0.25

            --print("nCurrentPhase " .. tostring(self.nCurrentPhase))
            --print("nPhaseProp " .. tostring(self.nPhaseProp))
            --print("nStartPhase " .. tostring(nStartPhase))
            --print("phase.End " .. tostring(phase.End))

            local nDist = self.nPhaseProp * self.tPhaseInfos[i].Length
            local vPhaseStart = self.tPhaseInfos[i].Start
            local vDir = phase.Dir
            self.vPos = Vector:new(vPhaseStart.x + nDist * vDir.x, vPhaseStart.y + nDist * vDir.y)

            break
        end
    end

    self.vSize = Vector:new(self.nSize, self.nSize)

    local imagePos = Vector:new(self.vPos.x, self.vPos.y)

    self.cImage = GameImage:new()
    self.cImage:Init(tImageBank, imagePos, self.vSize, "guard")

    self.nTurnProp = 0
    self.nAngle = self.tPhases[self.nCurrentPhase].Angle
    if self.nAngle >= 2 * math.pi then
        self.nAngle = self.nAngle - 2 * math.pi
    end
end

function Guard:Update(dt, cMainChar, cCurrentRoom)
    self.bCharSpotted = false
    self.bViewConeActive = false

    if self.nPhaseProp ~= 1 then
        local nMovement = dt * self.nSpeed
        local nPhaseDiff = nMovement / self.tPhaseInfos[self.nCurrentPhase].Length
        self.nPhaseProp = math.min(self.nPhaseProp + nPhaseDiff, 1)

        local nDist = self.nPhaseProp * self.tPhaseInfos[self.nCurrentPhase].Length
        local vPhaseStart = self.tPhaseInfos[self.nCurrentPhase].Start
        local vDir = self.tPhases[self.nCurrentPhase].Dir
        self.vPos = Vector:new(vPhaseStart.x + nDist * vDir.x, vPhaseStart.y + nDist * vDir.y)
    else
        local tNextPhase = self.tPhases[1 + (self.nCurrentPhase) % 4]
        local turnPropDiff = dt / self.nTurnTime
        self.nAngle = math.min(tNextPhase.Angle, self.nAngle + (math.pi / 2) * turnPropDiff)

        if self.nAngle >= tNextPhase.Angle then
            self.nPhaseProp = 0
            self.nCurrentPhase = 1 + (self.nCurrentPhase) % 4
            if self.nAngle >= 2 * math.pi then
                self.nAngle = self.nAngle - 2 * math.pi
            end
        end
    end

    self.cImage.vPos.x = self.vPos.x
    self.cImage.vPos.y = self.vPos.y
    self.cImage.nAngle = self.nAngle

    self.bGuardViewActive = self.cRoom:GuardViewActive()
    self.bGuardViewVisible = self.cRoom:GuardViewVisible()
    if self.bGuardViewActive then
        local vMainCharRel = cMainChar.vPos - self.vPos
        self.bCharSpotted = self:CanSeeCharacter(vMainCharRel, cCurrentRoom)
    end

    return self.bCharSpotted
end

function Guard:CanSeeCharacter(vMainCharRel, cCurrentRoom)
    local nMainCharDistSq = vMainCharRel.x * vMainCharRel.x + vMainCharRel.y * vMainCharRel.y
    local nMainCharDist = math.sqrt(nMainCharDistSq)

    if nMainCharDistSq < self.nViewConeRadiusSq then
        if nMainCharDist == 0 then
            return true
        end

        local vPointing = Vector:new(math.cos(self.nAngle), math.sin(self.nAngle))
        local nDot = (vMainCharRel.x * vPointing.x + vMainCharRel.y * vPointing.y) / nMainCharDist

        if (nDot > math.cos(self.nViewConeHalfAngle)) then
            -- Check if view is blocked

            local tBlockingRooms = { cCurrentRoom, (cCurrentRoom ~= self.cRoom and self.cRoom) or nil}
            for i, tConnection in ipairs(self.cRoom.tConnections) do
                -- If the character is in the same room we have to consider all
                -- corridors as blocking, otherwise only the connecting corridor
                local bAddCorridor = self.cRoom == cCurrentRoom or tConnection.Room == cCurrentRoom
                if bAddCorridor then
                    tBlockingRooms[#tBlockingRooms + 1] = tConnection.Corridor
                end
            end

            local bIsViewBlocked = false
            for i, cRoom in ipairs(tBlockingRooms) do
                for k, cWall in ipairs(cRoom.tWalls) do
                    bIsViewBlocked = cWall:Intersects(
                        self.vPos, vMainCharRel, nMainCharDist, nMainCharDistSq)
                    if bIsViewBlocked then
                        cWall.bHighlight = true
                        break
                    end
                end

                if bIsViewBlocked then
                    break
                end
            end

            return bIsViewBlocked == false
        end
    end

    return false
end

function Guard:DrawGuard()

    for i, info in ipairs(self.tPhaseInfos) do
        love.graphics.line(info.Start.x, info.Start.y, info.End.x, info.End.y)
    end

    self.cImage:Draw()
end

function Guard:DrawViewCone()
    
    if self.bGuardViewVisible then
        local r, g, b, a
        if self.bCharSpotted then
            r, g, b, a = love.graphics.getColor()
            love.graphics.setColor(self.tSpottedViewConeColour)
        end

        love.graphics.arc(
            "fill", self.vPos.x, self.vPos.y,
            self.nViewConeRadius, 
            self.nAngle - self.nViewConeHalfAngle,
            self.nAngle + self.nViewConeHalfAngle
        )

        if self.bCharSpotted then
            love.graphics.setColor(r, g, b, a)
        end
    end
end
