-- main.lua
-- Example for using luven.lua

Luven = require "luven"
Inspect = require "dev/inspect"

local image = nil

function love.load()
    image = love.graphics.newImage("Background.png")

    Luven.init()

    local lightId = Luven.addNormalLight(100, 100, { 1.0, 0.0, 1.0 }, 64)
end -- function

function love.update(dt)
    
end -- function

function love.draw()
    Luven.drawBegin()
    
    love.graphics.draw(image, 0, 0, 0, 0.5, 0.5)

    Luven.drawEnd()
end -- function
