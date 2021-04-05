
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

        local font = love.graphics.getFont()
        -- vGameOverPos = Vector:new()
        cGameOverText = love.graphics.newText( font, "You were spotted! Press 'R' to retry!" )
        cVictoryText = love.graphics.newText( font, "Well done! Press 'R' to replay!" )
    end
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

        cPhysicsManager:Run(cMainChar)

        for i, room in ipairs(tRooms) do
            bWonLevel = bWonLevel or room:Update(cMainChar)
        end

        local cMainCharBox = cMainChar:GetCurrentBox()
        local cOldRoom = cCurrentRoom
        cCurrentRoom = (cCurrentRoom:Contains(cMainCharBox.vPos, cMainCharBox.vSize) and cCurrentRoom) or cCurrentRoom
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

        local nTextWidth = cVictoryText:getWidth()
        love.graphics.draw( cVictoryText, cMainChar.vPos.x, cMainChar.vPos.y, 0, 3, 3, nTextWidth / 2)

        love.graphics.setColor(r, g, b, a)
    end

    --cPhysicsManager:Draw()

    --love.graphics.draw(textObject, 400, 300)
    --love.graphics.print(textObject:getWidth() .. " " .. textObject:getHeight(), x, y)
end