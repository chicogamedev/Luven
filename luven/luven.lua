local luven = {
    _VERSION     = 'Luven v1.023 exp.',
    _URL         = 'https://github.com/lionelleeser/Luven',
    _DESCRIPTION = 'A minimalist lighting system for Löve2D',
    _CONTRIBUTORS = 'Lionel Leeser, Pedro Gimeno (Help with shader and camera)',
    _LICENSE     = [[
        MIT License

        Copyright (c) 2019 Lionel Leeser

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

-- ///////////////////////////////////////////////
-- /// Luven error management local functions
-- ///////////////////////////////////////////////

local function assertPositiveNumber(functionName, parameterName, parameterValue, level)
    level = level or 3
    if ((type(parameterValue) ~= "number") or (parameterValue < 0)) then
        error(functionName .. "\n        parameter : " .. parameterName .. ", expected positive number.", 3)
    end -- if
end -- function

local function assertRangeNumber(functionName, parameterName, parameterValue, min, max, level)
    min = min or 0
    max = max or 1
    level = level or 3
    if ((type(parameterValue) ~= "number") or (parameterValue < min) or (parameterValue > max)) then
        error(functionName .. "\n        parameter : " .. parameterName .. ", expected range number between " .. min .. " and " .. max .. ".", 3)
    end -- if
end -- function

local function assertType(functionName, parameterName, parameterValue, parameterType, level)
    level = level or 3
    if (type(parameterValue) ~= parameterType) then
        error(functionName .. "\n        parameter : " .. parameterName .. ", expected type ".. parameterType .. ".", 3)
    end -- if
end -- function

-- ///////////////////////////////////////////////
-- /// Luven camera
-- ///////////////////////////////////////////////

luven.camera = {}

luven.camera.x = 0
luven.camera.y = 0
luven.camera.scaleX = 1
luven.camera.scaleY = 1
luven.camera.rotation = 0
luven.camera.transform = nil
luven.camera.shakeDuration = 0
luven.camera.shakeMagnitude = 0

-- //////////////////////////////
-- /// Camera local functions
-- //////////////////////////////

local function cameraUpdate(dt)
    if (luven.camera.shakeDuration > 0) then
        luven.camera.shakeDuration = luven.camera.shakeDuration - dt
    end -- if
end -- function

local function cameraDraw()
    if (luven.camera.shakeDuration > 0) then
        local dx = love.math.random(-luven.camera.shakeMagnitude, luven.camera.shakeMagnitude)
        local dy = love.math.random(-luven.camera.shakeMagnitude, luven.camera.shakeMagnitude)
        love.graphics.translate(dx, dy)
    end -- if
end -- function

local function cameraGetViewMatrix()
    return luven.camera.transform:getMatrix()
end -- function

-- //////////////////////////////
-- /// Camera accessible functions
-- //////////////////////////////

function luven.camera:init(x, y)
    local functionName = "luven.camera:init(x, y)"
    assertType(functionName, "x", x, "number")
    assertType(functionName, "y", y, "number")
    self.transform = love.math.newTransform(x, y)
    self.x = x
    self.y = y
end -- function

function luven.camera:set()
    love.graphics.push()
    self.transform:setTransformation(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, self.rotation, self.scaleX, self.scaleY, self.x, self.y)
    love.graphics.applyTransform(self.transform)
end -- function

function luven.camera:unset()
    love.graphics.pop()
end -- function

function luven.camera:setPosition(x, y)
    self.x = x
    self.y = y
end -- function

function luven.camera:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end -- function

function luven.camera:setRotation(dr)
    self.rotation = dr
end -- function

function luven.camera:setScale(sx, sy)
    self.scaleX = sx or 1
    self.scaleY = sy or sx or 1
end -- function

function luven.camera:setShake(duration, magnitude)
    self.shakeDuration = duration
    self.shakeMagnitude = magnitude
end -- function

-- ///////////////////////////////////////////////
-- /// Luven variables declarations
-- ///////////////////////////////////////////////

local NUM_LIGHTS = 500

local luvenPath = debug.getinfo(1,'S').source -- get Luven path
luvenPath = string.sub(luvenPath, 2, string.len(luvenPath) - 9) -- 9 = luven.lua

local lightTypes = {
    normal = 0,
    flickering = 1,
    flashing = 2
}

local currentLights = {}
local useIntegratedCamera = true

local ambientLightColor = { 0, 0, 0, 1 }

local lastActiveLightIndex = 0

local lightMap = nil

-- ///////////////////////////////////////////////
-- /// Luven helper enums
-- ///////////////////////////////////////////////

luven.lightShapes = {
    round = nil,
    rectangle = nil,
    cone = nil
}

-- ///////////////////////////////////////////////
-- /// Luven utils local functions
-- ///////////////////////////////////////////////

local function getLastEnabledLightIndex()
    for i = NUM_LIGHTS, 1, -1 do
        if (currentLights[i].enabled) then
            return i
        end -- if
    end -- for
end -- function

local function drawLights()
    love.graphics.setCanvas(lightMap)
    love.graphics.setBlendMode("add")

    love.graphics.clear(ambientLightColor) -- ambientLightColor

    local oldR, oldG, oldB, oldA = love.graphics.getColor()

    -- lastActiveLightIndex updated in luven.update()
    for i = 1, lastActiveLightIndex do
        if (currentLights[i].enabled) then
            love.graphics.setColor(currentLights[i].color)
            love.graphics.draw(currentLights[i].sprite, currentLights[i].x, currentLights[i].y, 0, currentLights[i].scaleX * currentLights[i].power, currentLights[i].scaleY * currentLights[i].power, currentLights[i].sprite:getWidth() / 2, currentLights[i].sprite:getHeight() / 2)
        end -- if
    end -- for

    love.graphics.setColor(oldR, oldG, oldB, oldA)

    love.graphics.setBlendMode("alpha")

    love.graphics.setCanvas()
end -- function

local function getNextId()
    for i = 1, NUM_LIGHTS do
        if (currentLights[i].enabled == false) then
            return i
        end -- if
    end -- for

    return 1 -- first index
end -- function

local function randomFloat(min, max)
        return min + love.math.random() * (max - min)
end -- function

local function clearTable(table)
    for k, _ in pairs(table) do table[k]=nil end
end -- function

local function generateFlicker(lightId)
    local light = currentLights[lightId]

    light.color[1] = randomFloat(light.colorRange.min[1], light.colorRange.max[1])
    light.color[2] = randomFloat(light.colorRange.min[2], light.colorRange.max[2])
    light.color[3] = randomFloat(light.colorRange.min[3], light.colorRange.max[3])

    light.power = randomFloat(light.powerRange.min, light.powerRange.max)

    light.flickTimer = randomFloat(light.speedRange.min, light.speedRange.max)
end -- if

-- ///////////////////////////////////////////////
-- /// Luven general functions
-- ///////////////////////////////////////////////

function luven.init(screenWidth, screenHeight, useCamera)
    screenWidth = screenWidth or love.graphics.getWidth()
    screenHeight = screenHeight or love.graphics.getWidth()
    if (useCamera ~= nil) then
        useIntegratedCamera = useCamera
    else
        useIntegratedCamera = true
    end -- if

    local functionName = "luven.init( [ screenWidth ], [ screenHeight ], [ useCamera ] )"
    assertPositiveNumber(functionName, "screenWidth", screenWidth)
    assertPositiveNumber(functionName, "screenHeight", screenHeight)
    assertType(functionName, "useCamera", useIntegratedCamera, "boolean")

    luven.lightShapes.round = love.graphics.newImage(luvenPath .. "lights/round.png")
    luven.lightShapes.rectangle = love.graphics.newImage(luvenPath .. "lights/rectangle.png")

    lightMap = love.graphics.newCanvas(screenWidth, screenHeight)

    for i = 1, NUM_LIGHTS do
        currentLights[i] = { enabled = false }
    end -- for
end -- function

-- param : color = { r, g, b, a (1) } (Values between 0 - 1)
function luven.setAmbientLightColor(color)
    color[4] = color[4] or 1
    ambientLightColor = color
end -- function

function luven.sendCustomViewMatrix(viewMatrix)
    error("luven.sendCustomViewMatrix : Not implemented anymore. Stop use it.")
end -- function

function luven.update(dt)
    if (useIntegratedCamera) then
        cameraUpdate(dt)
    end -- if

    lastActiveLightIndex = getLastEnabledLightIndex()

    for i = 1, lastActiveLightIndex do
        local light = currentLights[i]
        if (light.enabled) then
            if (light.type == lightTypes.flickering) then
                if (light.flickTimer > 0) then
                    light.flickTimer = light.flickTimer - dt
                else
                    generateFlicker(light.id)
                end -- if
            elseif (light.type == lightTypes.flashing) then
                light.timer = light.timer + dt
                if (light.power < light.maxPower) then
                    light.power = (light.maxPower * light.timer) / light.speed
                else
                    luven.removeLight(light.id)
                end -- if
            end -- if
        end -- if
    end -- for
end -- function

function luven.drawBegin()
    if (useIntegratedCamera) then
        cameraDraw()
        luven.camera:set()
    end -- if

    drawLights()
end -- function

function luven.drawEnd()
    if (useIntegratedCamera) then
        luven.camera:unset()
    end -- if

    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.draw(lightMap)
    love.graphics.setBlendMode("alpha")
end -- function

function luven.dispose()
    for _, v in pairs(currentLights) do
        if (v.enabled) then
            luven.removeLight(v.id)
        end -- if
    end -- for

    clearTable(currentLights)
end -- if

function luven.getLightCount()
    local count = 0

    for i = 1, lastActiveLightIndex do
        if (currentLights[i].enabled) then
            count = count + 1
        end -- if
    end -- for

    return count
end -- function

-- ///////////////////////////////////////////////
-- /// Luven lights functions
-- ///////////////////////////////////////////////

-- param : color = { r, g, b } (values between 0 - 1)
-- return : lightId
function luven.addNormalLight(x, y, color, power, lightShape, scaleX, scaleY)
    local functionName = "luven.addNormalLight(x, y, color, power)"
    assertType(functionName, "x", x, "number")
    assertType(functionName, "y", y, "number")
    assertRangeNumber(functionName, "color[1]", color[1])
    assertRangeNumber(functionName, "color[2]", color[2])
    assertRangeNumber(functionName, "color[3]", color[3])
    assertPositiveNumber(functionName, "power", power)

    lightShape = lightShape or luven.lightShapes.round
    scaleX = scaleX or 1
    scaleY = scaleY or scaleX

    local id = getNextId()
    local light = currentLights[id]
    
    clearTable(light)

    light.id = id
    light.x = x
    light.y = y
    light.scaleX = scaleX
    light.scaleY = scaleY
    light.color = color
    light.power = power
    light.type = lightTypes.normal
    light.sprite = lightShape

    light.enabled = true

    return light.id
end -- function

-- params : colorRange = { min = { r, g, b }, max = { r, g, b }}
--          powerRange = { min = n, max = n }
--          speedRange = { min = n, max = n }
-- return : lightId
function luven.addFlickeringLight(x, y, colorRange, powerRange, speedRange, lightShape, scaleX, scaleY)
    local functionName = "luven.addFlickeringLight(x, y, colorRange, powerRange, speedRange)"
    assertType(functionName, "x", x, "number")
    assertType(functionName, "y", y, "number")
    assertRangeNumber(functionName, "colorRange.min[1]", colorRange.min[1])
    assertRangeNumber(functionName, "colorRange.min[2]", colorRange.min[2])
    assertRangeNumber(functionName, "colorRange.min[3]", colorRange.min[3])
    assertRangeNumber(functionName, "colorRange.max[1]", colorRange.max[1])
    assertRangeNumber(functionName, "colorRange.max[2]", colorRange.max[2])
    assertRangeNumber(functionName, "colorRange.max[3]", colorRange.max[3])
    assertPositiveNumber(functionName, "powerRange.min", powerRange.min)
    assertPositiveNumber(functionName, "powerRange.max", powerRange.max)
    assertPositiveNumber(functionName, "speedRange.min", speedRange.min)
    assertPositiveNumber(functionName, "speedRange.max", speedRange.max)

    lightShape = lightShape or luven.lightShapes.round
    scaleX = scaleX or 1
    scaleY = scaleY or scaleX
    
    local id = getNextId()
    local light = currentLights[id]
    
    clearTable(light)

    light.id = id
    light.x = x
    light.y = y
    light.scaleX = scaleX
    light.scaleY = scaleY
    light.color = { 0, 0, 0 }
    light.power = 0
    light.type = lightTypes.flickering
    light.sprite = lightShape

    light.flickTimer = 0
    light.colorRange = colorRange
    light.powerRange = powerRange
    light.speedRange = speedRange

    light.enabled = true

    generateFlicker(light.id)

    return light.id
end -- function

function luven.addFlashingLight(x, y, color, maxPower, speed, lightShape, scaleX, scaleY)
    local functionName = "luven.addFlashingLight(x, y, color, maxPower, speed)"
    assertType(functionName, "x", x, "number")
    assertType(functionName, "y", y, "number")
    assertRangeNumber(functionName, "color[1]", color[1])
    assertRangeNumber(functionName, "color[2]", color[2])
    assertRangeNumber(functionName, "color[3]", color[3])
    assertPositiveNumber(functionName, "maxPower", maxPower)
    assertPositiveNumber(functionName, "speed", speed)

    lightShape = lightShape or luven.lightShapes.round
    scaleX = scaleX or 1
    scaleY = scaleY or scaleX

    local id = getNextId()
    local light = currentLights[id]
    clearTable(light)

    light.id = id
    light.x = x
    light.y = y
    light.scaleX = scaleX
    light.scaleY = scaleY
    light.color = color
    light.power = 0
    light.type = lightTypes.flashing
    light.sprite = lightShape
    
    light.maxPower = maxPower
    light.speed = speed
    light.timer = 0

    light.enabled = true
end -- function

function luven.removeLight(lightId)
    currentLights[lightId].enabled = false
end -- function

function luven.setLightPower(lightId, power)
    currentLights[lightId].power = power
end -- function

-- param : color = { r, g, b } (values between 0 - 1)
function luven.setLightColor(lightId, color)
    currentLights[lightId].color = color
end -- function

function luven.setLightPosition(lightId, x, y)
    currentLights[lightId].x = x
    currentLights[lightId].y = y
end -- function

function luven.moveLight(lightId, dx, dy)
    currentLights[lightId].x = currentLights[index].x + dx
    currentLights[lightId].y = currentLights[index].y + dy
end -- function

function luven.getLightPosition(lightId)
    return currentLights[lightId].x, currentLights[lightId].y
end -- function

function luven.getLightPower(lightId)
    return currentLights[lightId].power
end -- function

function luven.getLightColor(lightId)
    return currentLights[lightId].color
end -- function

return luven