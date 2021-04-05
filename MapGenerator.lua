require "Vector"
require "Room"

MapGenerator = {}

local nGridWidth = 5
local nGridHeight = 5

local nMaxRoomDimension = 6
local nMaxCorridorLength = 3

function MapGenerator.Generate(tImageBank, cPhysicsManager)

    nDepthCriteria = math.floor(nGridHeight * nGridWidth / 2) - 1
    local nNumRooms = love.math.random(nDepthCriteria + 2, nGridHeight * nGridWidth)
    local tRoomGrid = {}
    local tRooms = {}
    tDeepRooms = {}

    for row = 1, nGridHeight, 1 do
        tRoomGrid[row] = {}
        for column = 1, nGridWidth, 1 do
            tRoomGrid[row][column] = { }
        end
    end

    local nCurrentRow = 1
    local nCurrentColumn = 1

    local tConnectionInfo = {}

    MapGenerator.GenerateRoom(
        tImageBank, cPhysicsManager,
        tRoomGrid, tRooms, nNumRooms - 1, 
        nCurrentRow, nCurrentColumn,         
        Vector:new(3, nMaxRoomDimension),
        Vector:new(3, nMaxRoomDimension),
        Vector:new(0, 0), 
        tConnectionInfo, 1
    )

    if #tDeepRooms > 0 then
        local tBestDeepRooms = {}
        for i, deepRoom in ipairs(tDeepRooms) do
            if deepRoom.nNumChildren == 0 then
                tBestDeepRooms[#tBestDeepRooms + 1] = deepRoom
            end
        end

        if #tBestDeepRooms == 0 then
            tBestDeepRooms = tDeepRooms
        end

        tBestDeepRooms[love.math.random(#tBestDeepRooms)]:SetAsGoal(tImageBank, "prisoner")
    else
        print("Failed to find deep room to hide objective!")
        return false
    end

    return tRooms
end

function MapGenerator.GenerateRoom(
    tImageBank, cPhysicsManager, 
    tRoomGrid, tRoomList, nRoomsLeft, 
    nCurrentRow, nCurrentColumn,
    vWidthRange, vHeightRange, vPos,
    tConnectionInfos, nGenerationDepth
)
    --print("row " .. tostring(nCurrentRow) .. " col ".. tostring(nCurrentColumn))

    local tGridEntry = tRoomGrid[nCurrentRow][nCurrentColumn]
    if tGridEntry.cRoom == nil then
        tGridEntry.cRoom = Room:new()
    end

    if nGenerationDepth >= nDepthCriteria then
        tDeepRooms[#tDeepRooms + 1] = tGridEntry.cRoom
    end

    tGridEntry.cRoom:Init(vWidthRange, vHeightRange, vPos, tConnectionInfo)
    tRoomList[#tRoomList + 1] = tGridEntry.cRoom

    --print("Room: w " .. tostring(tGridEntry.cRoom.nWidth) .. " h " .. tostring(tGridEntry.cRoom.nHeight) ..
    --    " pos " .. tostring(vPos))

    if nRoomsLeft > 0 then
        
        local tValidExpansions = {}
        for rowCheckOffset = -1, 1, 1 do
            for columnCheckOffset = -1, 1, 1 do
                -- Only check direct adjacents
                if rowCheckOffset * columnCheckOffset == 0 and
                    rowCheckOffset ~= columnCheckOffset
                then
                    local nCheckRow = nCurrentRow + rowCheckOffset
                    local nCheckColumn = nCurrentColumn + columnCheckOffset
                    if nCheckRow > 0 and nCheckRow <= nGridWidth and
                        nCheckColumn > 0 and nCheckColumn <= nGridHeight and
                        tRoomGrid[nCheckRow][nCheckColumn].cRoom == nil
                    then
                        tValidExpansions[#tValidExpansions + 1] = { ["Row"] = nCheckRow, ["Col"] = nCheckColumn }
                    end
                end
            end
        end

        if #tValidExpansions > 0 then 
            local nNumExpansions = love.math.random(1, math.min(#tValidExpansions, nRoomsLeft))

            local tChosenExpansions = {}
            for i = 1, nNumExpansions, 1 do
                local nExpansion = love.math.random(1, #tValidExpansions)
                tChosenExpansions[i] = tValidExpansions[nExpansion]
                tValidExpansions[nExpansion] = tValidExpansions[#tValidExpansions]
                tValidExpansions[#tValidExpansions] = nil
            end

            nRoomsLeft = nRoomsLeft - #tChosenExpansions

            tGridEntry.cRoom.nNumChildren = #tChosenExpansions

            for i, expansion in ipairs(tChosenExpansions) do
                -- Reserve spot in room grid!
                tRoomGrid[expansion.Row][expansion.Col].cRoom = Room:new()
            end

            for i, expansion in ipairs(tChosenExpansions) do
                print("expansion - row " .. tostring(expansion.Row) .. " col " .. tostring(expansion.Col))

                local bExpandsX = expansion.Row == nCurrentRow
                local nEdgeSize = (bExpandsX and tGridEntry.cRoom.nHeight) or tGridEntry.cRoom.nWidth
                local nConnectionSize = love.math.random(1, nEdgeSize - 2)
                local nConnectionStartOffset = love.math.random(1, nEdgeSize - 1 - nConnectionSize)
                local nConnectionEndRoomSize = love.math.random(nConnectionSize + 2, nMaxRoomDimension)

                local nCellStart = (((bExpandsX and nCurrentRow) or nCurrentColumn) - 1) * nMaxRoomDimension
                local nRoomStart = (bExpandsX and tGridEntry.cRoom.vTilePos.y) or tGridEntry.cRoom.vTilePos.x
                local nRoomStartInCell = nRoomStart - nCellStart
                local nConnectionStartInCell = nRoomStartInCell + nConnectionStartOffset
                local nConnectionStartInEndOffset =
                 love.math.random(math.max(1, nConnectionStartInCell + nConnectionEndRoomSize - nMaxRoomDimension), 
                    math.min(nConnectionStartInCell, nConnectionEndRoomSize - 1 - nConnectionSize))

                --print("bExpandsX " .. tostring(bExpandsX))
                --print("nEdgeSize " .. tostring(nEdgeSize))
                --print("nConnectionSize " .. tostring(nConnectionSize))
                --print("nConnectionStartOffset " .. tostring(nConnectionStartOffset))
                --print("nConnectionEndRoomSize " .. tostring(nConnectionEndRoomSize))
                --print("nCellStart " .. tostring(nCellStart))
                --print("nRoomStart " .. tostring(nRoomStart))
                --print("nRoomStartInCell " .. tostring(nRoomStartInCell))
                --print("nConnectionStartInCell " .. tostring(nConnectionStartInCell))
                --print("nConnectionStartInEndOffset " .. tostring(nConnectionStartInEndOffset))
                
                local sStartSide = nil
                local sEndSide = nil
                if bExpandsX then
                    if expansion.Col > nCurrentColumn then
                        sStartSide = "right"
                        sEndSide = "left"
                    else
                        sStartSide = "left"
                        sEndSide = "right"
                    end
                else
                    if expansion.Row > nCurrentRow then
                        sStartSide = "bottom"
                        sEndSide = "top"
                    else
                        sStartSide = "top"
                        sEndSide = "bottom"
                    end
                end

                --print(sStartSide)

                local vCorridorWidthRange = Vector:new()
                local vCorridorHeightRange = Vector:new()

                local nMinCorridorLength = 1
                if sStartSide == "right" then
                    local nCellSide = nCurrentColumn * nMaxRoomDimension
                    local nRoomToCell = nCellSide - (tGridEntry.cRoom.vTilePos.x + tGridEntry.cRoom.nWidth)
                    nMinCorridorLength = math.max(nRoomToCell, 1)
                elseif sStartSide == "left" then
                    local nCellSide = (nCurrentColumn - 1) * nMaxRoomDimension
                    local nRoomToCell = tGridEntry.cRoom.vTilePos.x - nCellSide
                    nMinCorridorLength = math.max(nRoomToCell, 1)
                elseif sStartSide == "bottom" then
                    local nCellSide = nCurrentRow * nMaxRoomDimension
                    local nRoomToCell = nCellSide - (tGridEntry.cRoom.vTilePos.y + tGridEntry.cRoom.nHeight)
                    nMinCorridorLength = math.max(nRoomToCell, 1)
                elseif sStartSide == "top" then
                    local nCellSide = (nCurrentRow - 1) * nMaxRoomDimension
                    local nRoomToCell = tGridEntry.cRoom.vTilePos.y - nCellSide
                    nMinCorridorLength = math.max(nRoomToCell, 1)
                end

                local nCorridorLength = love.math.random(nMinCorridorLength, nMaxCorridorLength)

                if bExpandsX then
                    vCorridorHeightRange.x = nConnectionSize
                    vCorridorHeightRange.y = nConnectionSize
                    vCorridorWidthRange.x = nCorridorLength
                    vCorridorWidthRange.y = nCorridorLength
                else
                    vCorridorWidthRange.x = nConnectionSize
                    vCorridorWidthRange.y = nConnectionSize
                    vCorridorHeightRange.x = nCorridorLength
                    vCorridorHeightRange.y = nCorridorLength
                end

                local vCorridorPos = Vector:new(tGridEntry.cRoom.vTilePos.x, tGridEntry.cRoom.vTilePos.y)
                if sStartSide == "right" then
                    vCorridorPos.x = vCorridorPos.x + tGridEntry.cRoom.nWidth
                elseif sStartSide == "left" then
                    vCorridorPos.x = vCorridorPos.x - nCorridorLength
                elseif sStartSide == "bottom" then
                    vCorridorPos.y = vCorridorPos.y + tGridEntry.cRoom.nHeight
                elseif sStartSide == "top" then
                    vCorridorPos.y = vCorridorPos.y - nCorridorLength
                end

                if bExpandsX then
                    vCorridorPos.y = vCorridorPos.y + nConnectionStartOffset
                else
                    vCorridorPos.x = vCorridorPos.x + nConnectionStartOffset
                end

                local tCorridorConnections =
                {
                    [sStartSide] = { ["Offset"] = 0, ["Width"] = nConnectionSize },
                    [sEndSide] = { ["Offset"] = 0, ["Width"] = nConnectionSize },
                }

                local tNewRoomConnections =
                {
                    [sEndSide] = { ["Offset"] = nConnectionStartInEndOffset, ["Width"] = nConnectionSize },
                }

                -- Add connection to parent room
                tConnectionInfos[sStartSide] = { ["Offset"] = nConnectionStartOffset, ["Width"] = nConnectionSize }

                -- Create corridor/connection
                tRoomList[#tRoomList + 1] = Room:new()
                local cCorridor = tRoomList[#tRoomList]
                cCorridor:Init(vCorridorWidthRange, vCorridorHeightRange, vCorridorPos)
                cCorridor:Create(tImageBank, cPhysicsManager, tCorridorConnections, true)

                tGridEntry.cRoom:SetConnection(tRoomGrid[expansion.Row][expansion.Col].cRoom, cCorridor)

                --print("Corridor: w " .. tostring(cCorridor.nWidth) .. " h " .. tostring(cCorridor.nHeight) ..
                --" pos " .. tostring(vCorridorPos))

                local vNewRoomPos = Vector:new(vCorridorPos.x, vCorridorPos.y)
                local vNewRoomWidth = Vector:new()
                local vNewRoomHeight = Vector:new()
                if sStartSide == "right" then
                    local nExpansionCellEnd = expansion.Col * nMaxRoomDimension
                    local nSpaceForRoom = nExpansionCellEnd - (vCorridorPos.x + nCorridorLength)
                    local nRoomDepth = love.math.random(3, nSpaceForRoom)

                    vNewRoomHeight.x = nConnectionEndRoomSize
                    vNewRoomHeight.y = nConnectionEndRoomSize
                    vNewRoomWidth.x = nRoomDepth
                    vNewRoomWidth.y = nRoomDepth

                    vNewRoomPos.x = vNewRoomPos.x + nCorridorLength
                    vNewRoomPos.y = vNewRoomPos.y - nConnectionStartInEndOffset
                elseif sStartSide == "left" then
                    local nExpansionCellEnd = (expansion.Col - 1) * nMaxRoomDimension
                    local nSpaceForRoom = vCorridorPos.x - nExpansionCellEnd
                    local nRoomDepth = love.math.random(3, nSpaceForRoom)

                    vNewRoomHeight.x = nConnectionEndRoomSize
                    vNewRoomHeight.y = nConnectionEndRoomSize
                    vNewRoomWidth.x = nRoomDepth
                    vNewRoomWidth.y = nRoomDepth

                    vNewRoomPos.x = vNewRoomPos.x - nRoomDepth
                    vNewRoomPos.y = vNewRoomPos.y - nConnectionStartInEndOffset
                elseif sStartSide == "bottom" then
                    local nExpansionCellEnd = expansion.Row * nMaxRoomDimension
                    local nSpaceForRoom = nExpansionCellEnd - (vCorridorPos.y + nCorridorLength)
                    local nRoomDepth = love.math.random(3, nSpaceForRoom)

                    vNewRoomWidth.x = nConnectionEndRoomSize
                    vNewRoomWidth.y = nConnectionEndRoomSize
                    vNewRoomHeight.x = nRoomDepth
                    vNewRoomHeight.y = nRoomDepth

                    vNewRoomPos.y = vNewRoomPos.y + nCorridorLength
                    vNewRoomPos.x = vNewRoomPos.x - nConnectionStartInEndOffset
                elseif sStartSide == "top" then
                    local nExpansionCellEnd = (expansion.Row - 1) * nMaxRoomDimension
                    local nSpaceForRoom = vCorridorPos.y - nExpansionCellEnd
                    local nRoomDepth = love.math.random(3, nSpaceForRoom)

                    vNewRoomWidth.x = nConnectionEndRoomSize
                    vNewRoomWidth.y = nConnectionEndRoomSize
                    vNewRoomHeight.x = nRoomDepth
                    vNewRoomHeight.y = nRoomDepth

                    vNewRoomPos.y = vNewRoomPos.y - nRoomDepth
                    vNewRoomPos.x = vNewRoomPos.x - nConnectionStartInEndOffset
                end

                MapGenerator.GenerateRoom(
                    tImageBank, cPhysicsManager, 
                    tRoomGrid, tRoomList, nRoomsLeft, 
                    expansion.Row, expansion.Col,
                    vNewRoomWidth, vNewRoomHeight, vNewRoomPos,
                    tNewRoomConnections, nGenerationDepth + 1
                )
            end
        end
    end

    tGridEntry.cRoom:Create(tImageBank, cPhysicsManager, tConnectionInfos)
end
