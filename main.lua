-- main.lua
-- Example for using luven.lua

Luven = require "luven/luven"
Inspect = require "dev/inspect"
Profi = require "dev/profi"

local zoom = 2
local image = nil
local moveSpeed = 150

local lightId = 0
local lightId2 = 0

local power = 0.25

function love.load()
    Profi:start()
    image = love.graphics.newImage("Background.png")

    Luven.init()
    Luven.setAmbientLightColor({ 0.1, 0.1, 0.1 })
    Luven.camera:init(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    Luven.camera:setScale(zoom)

    lightId = Luven.addFlickeringLight(600, 400, { min = { 0.8, 0.0, 0.8, 0.8 }, max = { 1.0, 0.0, 1.0, 1.0 } }, { min = 0.25, max = 0.27 }, { min = 0.12, max = 0.2 })
    lightId2 = Luven.addNormalLight(700, 400, { 1.0, 0.0 , 1.0, 1.0 }, power, Luven.lightShapes.cone, 0.5, 5)
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

    Luven.setLightRotation(lightId2, Luven.getLightRotation(lightId2) + 1 * dt)
end -- function

function love.keypressed(key)
    if (key == "space") then
        Luven.camera:setShake(0.7, 5.5)
    end -- if

    if (key == "m") then
        power = power + 0.05
        Luven.setLightPower(lightId, power)
    end -- if

    if (key == "n") then
        power = power - 0.05
        Luven.setLightPower(lightId, power)
    end -- if

    if (key == "l") then
        lightId = Luven.addNormalLight(Luven.camera.x, Luven.camera.y, { 1.0, 1.0 , 1.0 }, 0.05)
    end -- if

    if (key == "f") then
        Luven.addFlashingLight(Luven.camera.x, Luven.camera.y, { 1.0, 0.0, 0.0 }, 1, 3)
    end -- if
end -- function

function love.draw()
    Luven.drawBegin()
    
    love.graphics.draw(image, 0, 0, 0, 0.5, 0.5)

    Luven.drawEnd()

    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.print("Number of lights: " .. tostring(Luven.getLightCount()), 10, 30)
end -- function

function love.quit()
    Luven.dispose()
    Profi:stop()
	Profi:writeReport("LuvenProfile.txt")
end -- function