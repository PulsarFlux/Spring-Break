
require "Vector"
require "GameImage"
require "Character"
require "Input"
require "Room"
require "PhysicsManager"
require "MapGenerator"
require "GuardManager"

function Load()
    tImageBank =
    {
       character = love.graphics.newImage("Images/survivor1_stand.png"),
       prisoner = love.graphics.newImage("Images/manBrown_stand.png"),
       guard = love.graphics.newImage("Images/soldier.png"),
       roomblank = love.graphics.newImage("Images/RoomBlank.png"),
       roomedge = love.graphics.newImage("Images/RoomEdge.png"),
       roomcorner = love.graphics.newImage("Images/RoomCorner.png"),
       corridoredge = love.graphics.newImage("Images/CorridorEdge.png"),
    }

    vScreenCentre = Vector:new()

    cInput = Input:new()
    cInput:Init()

    cPhysicsManager = PhysicsManager:new()
    cPhysicsManager:Init()

    tRooms = MapGenerator.Generate(tImageBank, cPhysicsManager)

    if tRooms == false then
        Load()
    else
        local cFirstRoom = tRooms[1]
        cCurrentRoom = cFirstRoom
        cCurrentRoom:SetGuardViewActive(true)

        local vMainCharSpawn = Vector:new()
        vMainCharSpawn.x = (cFirstRoom.vTilePos.x + cFirstRoom.nWidth) * Room.nTileSize / 2
        vMainCharSpawn.y = (cFirstRoom.vTilePos.y + cFirstRoom.nHeight) * Room.nTileSize / 2

        cMainChar = Character:new()
        cMainChar:Init(cInput, tImageBank, vMainCharSpawn)

        cGuardManager = GuardManager:new()
        cGuardManager:Init(tImageBank, tRooms)

        cFirstRoom:SetAsGoal(tImageBank, "exit")
        cCurrentRoom:SetGuardViewActive(true)

        bGameOver = false
        bWonLevel = false

        cFont = love.graphics.getFont()
        -- vGameOverPos = Vector:new()
        cGameOverText = love.graphics.newText( cFont, "You were spotted! Press 'R' to retry!" )
        cVictoryText = love.graphics.newText( cFont, "Well done! Press 'R' to replay!" )
        cVictoryText = love.graphics.newText( cFont, "You escaped! Well done!" )
        cReplayText = love.graphics.newText( cFont, "Press 'R' to replay!" )
    end

    nStartRunTime = love.timer.getTime()
end

function love.load()
    Load()
end

function love.update(dt)
    dt = ((bGameOver or bWonLevel) and 0) or dt

    cInput:Run()

    if cInput:Restart() then
        Load()
    else
        vScreenCentre.x = love.graphics.getWidth() / 2
        vScreenCentre.y = love.graphics.getHeight() / 2

        cMainChar:Move(dt, vScreenCentre)

        cPhysicsManager:Run(cMainChar, cCurrentRoom)

        local bWonLevelBefore = bWonLevel

        for i, room in ipairs(tRooms) do
            bWonLevel = bWonLevel or room:Update(cMainChar)
        end

        if bWonLevel and bWonLevelBefore == false then
            nRunTime = love.timer.getTime() - nStartRunTime
            if nBestRunTime == nil or nRunTime < nBestRunTime then
                nBestRunTime = nRunTime
            end
            local sVictoryTimeString = string.format("Time to spring/break: %.3f seconds.", nRunTime)
            cVictoryTimeText = love.graphics.newText( cFont, sVictoryTimeString )
            sVictoryTimeString = string.format("Best time this session: %.3f seconds.", nBestRunTime)
            cVictoryTimeText:add(sVictoryTimeString, 0, cVictoryTimeText:getHeight())
        end

        local cMainCharBox = cMainChar:GetCurrentBox()
        local cOldRoom = cCurrentRoom
        for i, tConnection in ipairs(cCurrentRoom.tConnections) do
            if tConnection.Room:Contains(cMainCharBox.vPos, cMainCharBox.vSize) then
                cCurrentRoom = tConnection.Room
                break
            end
        end

        if cCurrentRoom ~= cOldRoom then
            cOldRoom:SetGuardViewActive(false)
            cCurrentRoom:SetGuardViewActive(true)
        end

        bGameOver = cGuardManager:Update(dt, cMainChar)

        if bWonLevel then
            bGameOver = false
        end
    end
end

function love.draw()

    love.graphics.translate(
        vScreenCentre.x - cMainChar.vPos.x, 
        vScreenCentre.y - cMainChar.vPos.y
    )

    for i, room in ipairs(tRooms) do
        room:Draw()
    end

    cGuardManager:Draw()

    cMainChar:Draw()

    if bGameOver then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor({1, 0, 0, 1})

        local nTextWidth = cGameOverText:getWidth()
        love.graphics.draw( cGameOverText, cMainChar.vPos.x, cMainChar.vPos.y, 0, 3, 3, nTextWidth / 2)

        love.graphics.setColor(r, g, b, a)
    end

    if bWonLevel then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor({0, 1, 0, 1})

        local nTextScale = 3
        local nTextWidth = cVictoryText:getWidth()
        local nTextHeight = cVictoryText:getHeight() * 3 * nTextScale -- Three lines
        love.graphics.draw( cVictoryText, cMainChar.vPos.x, cMainChar.vPos.y - nTextHeight, 0, nTextScale, nTextScale, nTextWidth / 2)
        
        nTextWidth = cVictoryTimeText:getWidth()
        nTextHeight = cVictoryTimeText:getHeight() * 2 * nTextScale -- Two lines
        love.graphics.draw( cVictoryTimeText, cMainChar.vPos.x, cMainChar.vPos.y - nTextHeight, 0, nTextScale, nTextScale, nTextWidth / 2)
        
        nTextWidth = cReplayText:getWidth()
        love.graphics.draw( cReplayText, cMainChar.vPos.x, cMainChar.vPos.y, 0, nTextScale, nTextScale, nTextWidth / 2)

        love.graphics.setColor(r, g, b, a)
    end

    -- Debug draw cPhysicsManager:Draw()
end