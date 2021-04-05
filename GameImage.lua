require "class"
require "Vector"

GameImage = class:new()

GameImage.vPos = Vector:new(0, 0)

GameImage.vSize = Vector:new(100, 100)

GameImage.sImage = ""

GameImage.tColour = { 1, 1, 1, 1}

GameImage.tImageBank = {}

function GameImage:Init( i_imageBank, i_pos, i_size, i_image, i_colour )
    self.tImageBank = i_imageBank
    self.vPos = i_pos or GameImage.vPos
    self.vSize = i_size or GameImage.vSize
    self.sImage = i_image or GameImage.sImage
    self.tColour = i_colour or GameImage.tColour
end

function GameImage:Draw(bNoOrigin)
    local loveImage = self.tImageBank[self.sImage]
    local loveImageWidth = loveImage:getWidth()
    local loveImageHeight = loveImage:getHeight()

    local widthScale = self.vSize.x / loveImageWidth
    local heightScale = self.vSize.y / loveImageHeight

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(self.tColour)
    love.graphics.draw(loveImage, self.vPos.x, self.vPos.y, self.nAngle, 
        widthScale, heightScale, (bNoOrigin and 0) or loveImageWidth / 2, (bNoOrigin and 0) or loveImageHeight / 2)
    love.graphics.setColor(r, g, b, a)
end

return GameImage