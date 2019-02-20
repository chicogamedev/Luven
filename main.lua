-- main.lua
-- Example for using luven.lua

Luven = require "luven"
Inspect = require "dev/inspect"

local zoom = 2
local image = nil
local moveSpeed = 150

local lightId = 0

function love.load()
    image = love.graphics.newImage("Background.png")

    Luven.init()
    Luven.setAmbientLightColor({ 0.1, 0.1, 0.1 })
    Luven.camera:init(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    Luven.camera:setScale(zoom)

    lightId = Luven.addFlickeringLight(600, 400, { min = { 0.8, 0.0, 0.8 }, max = { 1.0, 0.0, 1.0 } }, { min = 2, max = 3 }, { min = 0.2, max = 0.3 })
    lightId = Luven.addNormalLight(700, 400, { 1.0, 0.0 , 1.0 }, 10)

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

    if (key == "l") then
        lightId = Luven.addNormalLight(Luven.camera.x, Luven.camera.y, { 1.0, 1.0 , 1.0 }, 10)
    end -- if

    if (key == "f") then
        Luven.addFlashingLight(Luven.camera.x, Luven.camera.y, { 1.0, 0.0, 0.0 }, 15, 0.05)
    end -- if
end -- function

function love.draw()
    Luven.drawBegin()
    
    love.graphics.draw(image, 0, 0, 0, 0.5, 0.5)

    Luven.drawEnd()

    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    --love.graphics.print("Number of lights: " .. tostring(Luven.getLightCount()), 10, 30)
end -- function

function love.quit()
    Luven.dispose()
end -- function