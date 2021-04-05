require "class"
require "Vector"

Input = class:new()

function Input:Init()
    self.tKeyIsDown = {}

    self.vMousePos = Vector:new()
end

function Input:Run()
    self.tKeyIsDown["W"] = love.keyboard.isDown("w")
    self.tKeyIsDown["A"] = love.keyboard.isDown("a")
    self.tKeyIsDown["S"] = love.keyboard.isDown("s")
    self.tKeyIsDown["D"] = love.keyboard.isDown("d")

    self.tKeyIsDown["R"] = love.keyboard.isDown("r")

    self.vMousePos.x = love.mouse.getX()
    self.vMousePos.y = love.mouse.getY()
end

function Input:Up()
    return self.tKeyIsDown["W"]
end

function Input:Left()
    return self.tKeyIsDown["A"]
end

function Input:Down()
    return self.tKeyIsDown["S"]
end

function Input:Right()
    return self.tKeyIsDown["D"]
end

function Input:Restart()
    return self.tKeyIsDown["R"]
end

function Input:MousePos()
    return self.vMousePos
end