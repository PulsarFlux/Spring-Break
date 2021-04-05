require "class"
require "GameImage"
require "Vector"
require "Wall"
require "Goal"

Room = class:new()

Room.nTileSize = 50

Room.nWallThickness = 12

function Room:Init(vXBounds, vYBounds, vTilePos)
    self.nWidth = love.math.random( vXBounds.x, vXBounds.y )
    self.nHeight = love.math.random( vYBounds.x, vYBounds.y )

    self.vTilePos = vTilePos

    self.tTiles = {}
    self.tWalls = {}

    self.nNumChildren = 0

    if self.tConnections == nil then
        self.tConnections = {}
    end
end

function Room:SetAsGoal(tImageBank, sType)
    self.bHasGoal = true
    self.cGoal = Goal:new()
    local vGoalPos = Vector:new()
    vGoalPos.x = (2 * self.vTilePos.x + self.nWidth) * self.nTileSize / 2
    vGoalPos.y = (2 * self.vTilePos.y + self.nHeight) * self.nTileSize / 2
    self.cGoal:Init(tImageBank, vGoalPos, sType)
end

function Room:Create(tImageBank, cPhysicsManager, tConnectionInfos, bIsCorridor)

    self.bIsCorridor = bIsCorridor

    local tCornerInfos =
    {
        [1] = { [1] = {math.pi / 2, { "top", "left"}}, [self.nHeight] = {0, {"left", "bottom"}} },
        [self.nWidth] = { [1] = {math.pi, {"top", "right"}}, [self.nHeight] = {-math.pi / 2, {"right", "bottom"}} },
    }

    local tWallInfos =
    {
        top = { Vector:new(0, 0), Vector:new(self.nTileSize, self.nWallThickness)},
        left = { Vector:new(0, 0), Vector:new(self.nWallThickness, self.nTileSize)},
        bottom = { Vector:new(0, self.nTileSize - self.nWallThickness), Vector:new(self.nTileSize, self.nWallThickness)},
        right = { Vector:new(self.nTileSize - self.nWallThickness, 0), Vector:new(self.nWallThickness, self.nTileSize)},
        ctop = { Vector:new(0, -self.nWallThickness), Vector:new(self.nTileSize, self.nWallThickness)},
        cleft = { Vector:new(-self.nWallThickness, 0), Vector:new(self.nWallThickness, self.nTileSize)},
        cbottom = { Vector:new(0, self.nTileSize), Vector:new(self.nTileSize, self.nWallThickness)},
        cright = { Vector:new(self.nTileSize, 0), Vector:new(self.nWallThickness, self.nTileSize)},
    }

    local tCorridorInfos =
    {
        ctop = { ["vOff"] = Vector:new(0, -self.nTileSize), ["xOff"] = 0, ["yOff"] = -1, },
        cleft = { ["vOff"] = Vector:new(-self.nTileSize, 0), ["xOff"] = -1, ["yOff"] = 0, },
        cbottom = { ["vOff"] = Vector:new(0, self.nTileSize), ["xOff"] = 0, ["yOff"] = 1, },
        cright = { ["vOff"] = Vector:new(self.nTileSize, 0), ["xOff"] = 1, ["yOff"] = 0, },
    }

    for row = ((self.bIsCorridor and 0) or 1), self.nHeight + ((self.bIsCorridor and 1) or 0), 1 do
        self.tTiles[row] = {}
    end

    for nCounter = 0, self.nWidth * self.nHeight - 1, 1 do
        local xIndex = 1 + (nCounter % self.nWidth)
        local yIndex = 1 + math.floor(nCounter / self.nWidth)

        local roomPos = Vector:new(
            (self.vTilePos.x + (xIndex - 1)) * self.nTileSize,
            (self.vTilePos.y + (yIndex - 1)) * self.nTileSize
        )

        local roomImagePos = Vector:new(
            self.nTileSize / 2 + roomPos.x,
            self.nTileSize / 2 + roomPos.y
        )

        --print(xIndex, yIndex)
        --print(roomPos)

        local sImageName = "roomblank"
        local nAngle = 0
        local tWallsToAdd = {}
        local bAddXWall = false
        local bAddYWall = false
        -- Corner
        if (xIndex == 1 or xIndex == self.nWidth) and 
            (yIndex == 1 or yIndex == self.nHeight)
        then
            bAddXWall = not Room.NoWall(xIndex == 1 and "left" or "right", yIndex, tConnectionInfos)
            bAddYWall = not Room.NoWall(yIndex == 1 and "top" or "bottom", xIndex, tConnectionInfos)

            if (bAddXWall and bAddYWall) then
                sImageName = "roomcorner"
                nAngle = tCornerInfos[xIndex][yIndex][1]
                tWallsToAdd[1] = tCornerInfos[xIndex][yIndex][2][1]
                tWallsToAdd[2] = tCornerInfos[xIndex][yIndex][2][2]
                bAddXWall = false
                bAddYWall = false
            end

        -- Edge X
        elseif (xIndex == 1 or xIndex == self.nWidth) then

            bAddXWall = not Room.NoWall(xIndex == 1 and "left" or "right", yIndex, tConnectionInfos)

        -- Edge Y
        elseif (yIndex == 1 or yIndex == self.nHeight) then

            bAddYWall = not Room.NoWall(yIndex == 1 and "top" or "bottom", xIndex, tConnectionInfos)
        end

        if bIsCorridor then
            if bAddXWall then
                nAngle = (xIndex == 1 and math.pi) or 0
                tWallsToAdd[1] = (xIndex == 1 and "cleft") or "cright"
                if self.nWidth == 1 then
                    tWallsToAdd[2] = (xIndex == 1 and "cright") or "cleft"
                end
            elseif bAddYWall then
                nAngle = (yIndex == 1 and -math.pi / 2) or math.pi / 2
                tWallsToAdd[1] = (yIndex == 1 and "ctop") or "cbottom"
                if self.nHeight == 1 then
                    tWallsToAdd[2] = (yIndex == 1 and "cbottom") or "ctop"
                end
            end
        else
            if bAddXWall then
                sImageName = "roomedge"
                nAngle = (xIndex == 1 and math.pi) or 0

                tWallsToAdd[1] = (xIndex == 1 and "left") or "right"
            elseif bAddYWall then
                sImageName = "roomedge"
                nAngle = (yIndex == 1 and -math.pi / 2) or math.pi / 2

                tWallsToAdd[1] = (yIndex == 1 and "top") or "bottom"
            end
        end

        self.tTiles[yIndex][xIndex] = GameImage:new()
        self.tTiles[yIndex][xIndex]:Init(tImageBank, roomImagePos, 
            Vector:new(self.nTileSize, self.nTileSize), sImageName)
        self.tTiles[yIndex][xIndex].nAngle = nAngle

        if bIsCorridor then
            for i, wallToAdd in ipairs(tWallsToAdd) do
                local tCorridorInfo = tCorridorInfos[wallToAdd]
                --print("CreateCorridor " .. "y " .. yIndex .. " x " .. "xIndex")
                self.tTiles[yIndex + tCorridorInfo.yOff][xIndex + tCorridorInfo.xOff] = GameImage:new()
                self.tTiles[yIndex + tCorridorInfo.yOff][xIndex + tCorridorInfo.xOff]:Init(tImageBank, roomImagePos + tCorridorInfo.vOff, 
                    Vector:new(self.nTileSize, self.nTileSize), "corridoredge")
                if bIsCorridor and wallToAdd == tWallsToAdd[2] then
                    nAngle = nAngle + math.pi
                end
                self.tTiles[yIndex + tCorridorInfo.yOff][xIndex + tCorridorInfo.xOff].nAngle = nAngle
            end
        end

        for i, wallToAdd in ipairs(tWallsToAdd) do
            local newWall = Wall:new()
            local tWallInfo = tWallInfos[wallToAdd]
            newWall:Init(roomPos + tWallInfo[1], tWallInfo[2])
            cPhysicsManager:AddWall(newWall)

            self.tWalls[#self.tWalls + 1] = newWall
        end
    end
end

function Room.NoWall(sEdge, nIndex, tConnectionInfos)
    if tConnectionInfos[sEdge] == nil then
        return false
    end

    local nConnectionStart = 1 + tConnectionInfos[sEdge].Offset
    local nConnectionEnd = nConnectionStart + tConnectionInfos[sEdge].Width - 1

    if (nIndex >= nConnectionStart and nIndex <= nConnectionEnd) then
        return true
    else
        return false
    end
end

function Room:Update(cMainChar)
    local bHasWonGame = false
    if self.bHasGoal then
        bHasWonGame = bHasWonGame or self.cGoal:Check(cMainChar)
    end
    return bHasWonGame
end

function Room:SetGuardViewActive(bValue)
    self.bGuardViewActive = bValue
    self.bGuardViewVisible = bValue
    for i, tConnection in ipairs(self.tConnections) do
        tConnection.Room.bGuardViewActive = bValue
        tConnection.Room.bGuardViewVisible = bValue
        -- Cones are visible but not active in even further rooms
        for k, tFurtherConnection in ipairs(tConnection.Room.tConnections) do
            if tFurtherConnection.Room ~= tConnection.Room then
                tFurtherConnection.Room.bGuardViewVisible = bValue
            end
        end
    end
end

function Room:SetConnection(cOtherRoom, cCorridor)
    self.tConnections[#self.tConnections + 1] = { ["Room"] = cOtherRoom, ["Corridor"] = cCorridor }

    if cOtherRoom.tConnections == nil then
        cOtherRoom.tConnections = {}
    end

    cOtherRoom.tConnections[#cOtherRoom.tConnections + 1] = { ["Room"] = self, ["Corridor"] = cCorridor }
end

function Room:GuardViewActive()
    return self.bGuardViewActive
end

function Room:GuardViewVisible()
    return self.bGuardViewVisible
end

function Room:Contains(vPos, vSize)    
    local vOurPos = Vector:new(self.vTilePos.x * self.nTileSize, self.vTilePos.y * self.nTileSize)
    local vOurSize = Vector:new(self.nWidth * self.nTileSize, self.nHeight * self.nTileSize)

    if (vPos.x + vSize.x > vOurPos.x and vPos.x < vOurPos.x + vOurSize.x) and
        (vPos.y + vSize.y > vOurPos.y and vPos.y < vOurPos.y + vOurSize.y)
    then
        return true
    end
    return false
end

function Room:Draw()

    local nStartIndex = (self.bIsCorridor and 0) or 1
    local nEndX = self.nWidth + ((self.bIsCorridor and 1) or 0)
    local nEndY = self.nHeight + ((self.bIsCorridor and 1) or 0)

    for xIndex = nStartIndex, nEndX, 1 do
        for yIndex = nStartIndex, nEndY, 1 do
            if not self.bIsCorridor or self.tTiles[yIndex][xIndex] then
                self.tTiles[yIndex][xIndex]:Draw()
            end
        end
    end

    if self.bHasGoal then
        self.cGoal:Draw()
    end
end

