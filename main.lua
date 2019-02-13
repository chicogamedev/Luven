-- main.lua
-- Example for using luven.lua

Luven = require "luven"
Inspect = require "dev/inspect"

local image = nil

function love.load()
    image = love.graphics.newImage("Background.png")

    Luven.init(love.graphics.getWidth(), love.graphics.getWidth())
    Luven.setAmbientLightColor({ 0.1, 0.1, 0.1 })

    local lightId = Luven.addNormalLight(400, 400, { 1.0, 1.0, 1.0 }, 7)
    Luven.setLightPower(lightId, 25)
    Luven.setLightColor(lightId, { 1.0, 0.0, 1.0 })
    --Luven.removeLight(light)
end -- function

function love.update(dt)
    
end -- function

function love.draw()
    Luven.drawBegin()
    
    love.graphics.draw(image, 0, 0, 0, 0.5, 0.5)

    Luven.drawEnd()
end -- function
