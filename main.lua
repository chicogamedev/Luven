-- main.lua
-- Example for using luven.lua

Luven = require "luven"
Inspect = require "dev/inspect"

local zoom = 2
local image = nil
local moveSpeed = 150

local lightId = 0
local lightId2 = 0

function love.load()
    image = love.graphics.newImage("Background.png")

    Luven.init()
    Luven.setAmbientLightColor({ 0.1, 0.1, 0.1 })
    Luven.camera:init(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    Luven.camera:setScale(zoom)

    lightId = Luven.addNormalLight(100, 400, { 1.0, 0.0, 1.0 }, 8)
    lightId2 = Luven.addNormalLight(700, 400, {1.0, 1.0, 0.0 }, 10)
    -- Luven.setLightPower(lightId, 5)
    -- Luven.setLightPower(lightId2, 19)
    -- Luven.setLightColor(lightId, { 1.0, 0.0, 1.0 })
    -- Luven.removeLight(light)
end -- function

function love.update(dt)
    Luven.update(dt)
    
    local vx, vy = 0, 0

    if (love.keyboard.isDown("w")) then
        vy = vy - moveSpeed * dt
    end -- if

    if (love.keyboard.isDown("s")) then
        vy = vy + moveSpeed * dt
    end -- if

    if (love.keyboard.isDown("a")) then
        vx = vx - moveSpeed * dt
    end -- if

    if (love.keyboard.isDown("d")) then
        vx = vx + moveSpeed * dt
    end -- if

    Luven.camera:move(vx, vy)
end -- function

function love.keypressed(key)
    if (key == "space") then
        Luven.camera:setShake(0.7, 5.5)
    end -- if
end -- function

function love.draw()
    Luven.drawBegin()
    
    love.graphics.draw(image, 0, 0, 0, 0.5, 0.5)

    Luven.drawEnd()
end -- function
