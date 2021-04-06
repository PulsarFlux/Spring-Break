require "class"
require "Vector"

Wall = class:new()

Wall.vPos = Vector:new(0, 0)

Wall.vSize = Vector:new(100, 100)

function Wall:Init(vPos, vSize)
    self.vPos = vPos
    self.vSize = vSize

    self.nMaxExtents = math.sqrt(self.vSize.x * self.vSize.x + self.vSize.y * self.vSize.y)
end

function Wall:Collides(vPos, vSize)
    if (vPos.x + vSize.x > self.vPos.x and vPos.x < self.vPos.x + self.vSize.x) and
        (vPos.y + vSize.y > self.vPos.y and vPos.y < self.vPos.y + self.vSize.y)
    then
        return true
    end
    return false
end

-- vLineDir does *not* need to be normalised
function Wall:Intersects(vLineStart, vLineDir, nWithinRadius, nWithinRadiusSq)
    -- Avoid allocating vector for performance
    local nPosDiffX = vLineStart.x - self.vPos.x
    local nPosDiffY = vLineStart.y - self.vPos.y
    local nPosDist = math.sqrt(nPosDiffX * nPosDiffX + nPosDiffY * nPosDiffY)
    if nWithinRadius and nWithinRadius + self.nMaxExtents < nPosDist then
        -- Do an early reject based on whether any
        -- of our corners can possibly be close enough
        return false
    end

    local nMinCornerDistSq = 0
    local tCorners =
    {
        -- Order is important
        self.vPos,
        Vector:new(self.vPos.x + self.vSize.x, self.vPos.y),
        self.vPos + self.vSize,
        Vector:new(self.vPos.x, self.vPos.y + self.vSize.y),
    }

    local nMinDistCorner = 0
    local nMinCornerDistSq = nil
    for i, vCorner in ipairs(tCorners) do
        -- Avoid allocating vector for performance
        local nCornerDiffX = vLineStart.x - vCorner.x
        local nCornerDiffY = vLineStart.y - vCorner.y
        local nCornerDistSq = nCornerDiffX * nCornerDiffX + nCornerDiffY * nCornerDiffY
        if nMinCornerDistSq == nil or nCornerDistSq < nMinCornerDistSq then
            nMinCornerDistSq = nCornerDistSq
            nMinDistCorner = i
        end
    end

    if nWithinRadiusSq and nMinCornerDistSq > nWithinRadiusSq then
        -- Check actual min dist this time
        return false
    end

    local tEndCorners =
    {
        -- This should get the two corners adjacent to the min dist corner
        tCorners[1 + (nMinDistCorner % 4)],
        tCorners[1 + ((nMinDistCorner + 2) % 4)]
    }

    local bEdgeIntercepts = false
    local vStartCorner = tCorners[nMinDistCorner]
    for i, vEndCorner in ipairs(tEndCorners) do
        -- Get ready for some maths!
        local nNumerator = vLineDir.y * (vStartCorner.x - vLineStart.x) - vLineDir.x * (vStartCorner.y - vLineStart.y)
        local nDenominator = vLineDir.x * (vEndCorner.y - vStartCorner.y) - vLineDir.y * (vEndCorner.x - vStartCorner.x)

        if nDenominator ~= 0 then
            local nEdgeProp = nNumerator / nDenominator
            if nEdgeProp >= 0 and nEdgeProp <= 1 then
                local nLineProp = 0
                -- 0 vLineDir should not enter this function
                if vLineDir.x ~= 0 then
                    nLineProp = (1 / vLineDir.x) * (nEdgeProp * (vEndCorner.x - vStartCorner.x) + vStartCorner.x - vLineStart.x)
                else
                    nLineProp = (1 / vLineDir.y) * (nEdgeProp * (vEndCorner.y - vStartCorner.y) + vStartCorner.y - vLineStart.y)
                end
                local nInterceptDistSq = nLineProp * nLineProp * (vLineDir.x * vLineDir.x + vLineDir.y * vLineDir.y)
                if nLineProp > 0 and ((not nWithinRadiusSq) or nInterceptDistSq <= nWithinRadiusSq) then
                    bEdgeIntercepts = true
                    break
                end
            end
        end
    end

    return bEdgeIntercepts
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