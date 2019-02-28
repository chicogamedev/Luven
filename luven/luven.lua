local luven = {
    _VERSION     = 'Luven v1.02',
    _URL         = 'https://github.com/chicogamedev/Luven',
    _DESCRIPTION = 'A minimalist light engine for Löve2D',
    _CONTRIBUTORS = 'Lionel Leeser, Pedro Gimeno (Help with camera)',
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
        error(functionName .. "\n        parameter : " .. parameterName .. ", expected positive number.", level)
    end -- if
end -- function

local function assertRangeNumber(functionName, parameterName, parameterValue, min, max, level)
    min = min or 0
    max = max or 1
    level = level or 3
    if ((type(parameterValue) ~= "number") or (parameterValue < min) or (parameterValue > max)) then
        error(functionName .. "\n        parameter : " .. parameterName .. ", expected range number between " .. min .. " and " .. max .. ".", level)
    end -- if
end -- function

local function assertType(functionName, parameterName, parameterValue, parameterType, level)
    level = level or 3
    if (type(parameterValue) ~= parameterType) then
        error(functionName .. "\n        parameter : " .. parameterName .. ", expected type ".. parameterType .. ".", level)
    end -- if
end -- function

local function assertLightShape(newShapeName, level)
    level = level or 3
    if (luven.lightShapes[newShapeName] ~= nil) then
        error("The light shapes : " .. newShapeName .. " already exists, please set another name.")
    end -- if
end -- function

-- ///////////////////////////////////////////////
-- /// Aliases
-- ///////////////////////////////////////////////

local lg = love.graphics
local lgDraw = lg.draw
local lgSetColor = lg.setColor

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
    local dx, dy = 0, 0
    if (luven.camera.shakeDuration > 0) then
        dx = love.math.random(-luven.camera.shakeMagnitude, luven.camera.shakeMagnitude)
        dy = love.math.random(-luven.camera.shakeMagnitude, luven.camera.shakeMagnitude)
    end -- if
    lg.push()
    self.transform:setTransformation(lg.getWidth() / 2, lg.getHeight() / 2, self.rotation, self.scaleX, self.scaleY, self.x + dx, self.y + dy)
    lg.applyTransform(self.transform)
end -- function

function luven.camera:unset()
    lg.pop()
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
local lightsSize = 256

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
-- /// Luven light shapes
-- ///////////////////////////////////////////////

luven.lightShapes = {}

-- ///////////////////////////////////////////////
-- /// Luven utils local functions
-- ///////////////////////////////////////////////

local function calculateLightOrigin(lightId)
    local light = currentLights[lightId]

    local origin = { x = 0, y = 0 }

    if (light.shape.originX == "center") then
        origin.x = light.shape.sprite:getWidth() / 2
    elseif (light.shape.originX == "min") then
        origin.x = 0
    elseif (light.shape.originX == "max") then
        origin.x = light.shape.sprite:getWidth()
    end -- if

    if (light.shape.originY == "center") then
        origin.y = light.shape.sprite:getHeight() / 2
    elseif (light.shape.originY == "min") then
        origin.y = 0
    elseif (light.shape.originY == "max") then
        origin.y = light.shape.sprite:getHeight()
    end -- if

    return origin
end -- function

local function getLastEnabledLightIndex()
    for i = NUM_LIGHTS, 1, -1 do
        if (currentLights[i].enabled) then
            return i
        end -- if
    end -- for
end -- function

local function drawLights()
    lg.setCanvas(lightMap)
    lg.setBlendMode("add")

    lg.clear(ambientLightColor) -- ambientLightColor

    local oldR, oldG, oldB, oldA = lg.getColor()

    -- lastActiveLightIndex updated in luven.update()
    for i = 1, lastActiveLightIndex do
        if (currentLights[i].enabled) then
            local light = currentLights[i]
            lgSetColor(light.color)
            lgDraw(light.shape.sprite, light.x, light.y, light.angle, light.scaleX * light.power, light.scaleY * light.power, light.origin.x, light.origin.y)
        end -- if
    end -- for

    lgSetColor(oldR, oldG, oldB, oldA)
    lg.setBlendMode("alpha")

    lg.setCanvas()
end -- function

local function getNextId()
    for i = 1, NUM_LIGHTS do
        local light = currentLights[i]
        if (light.enabled == false) then
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
end -- function

-- ///////////////////////////////////////////////
-- /// Luven general functions
-- ///////////////////////////////////////////////

function luven.init(screenWidth, screenHeight, useCamera)
    screenWidth = screenWidth or lg.getWidth()
    screenHeight = screenHeight or lg.getHeight()
    if (useCamera ~= nil) then
        useIntegratedCamera = useCamera
    else
        useIntegratedCamera = true
    end -- if

    local functionName = "luven.init( [ screenWidth ], [ screenHeight ], [ useCamera ] )"
    assertPositiveNumber(functionName, "screenWidth", screenWidth)
    assertPositiveNumber(functionName, "screenHeight", screenHeight)
    assertType(functionName, "useCamera", useIntegratedCamera, "boolean")

    luven.registerLightShape("round", luvenPath .. "lights/round.png")
    luven.registerLightShape("rectangle", luvenPath .. "lights/rectangle.png")
    luven.registerLightShape("cone", luvenPath .. "lights/cone.png", "min", "center")

    lightMap = lg.newCanvas(screenWidth, screenHeight)

    luvenShader:send("lightsCount", lightsCount)

    for i = 1, NUM_LIGHTS do
        currentLights[i] = { enabled = false }
    end -- for
end -- function

-- param : color = { r, g, b, a (1) } (Values between 0 - 1)
function luven.setAmbientLightColor(color)
    color[4] = color[4] or 1
    ambientLightColor = color
end -- function

-- param : originX, originY : TEXT : "center", "min", "max"
function luven.registerLightShape(name, spritePath, originX, originY)
    originX = originX or "center"
    originY = originY or originX

    assertLightShape(name)

    luven.lightShapes[name] = {
        sprite = lg.newImage(spritePath),
        originX = originX,
        originY = originY
    }
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
        luven.camera:set()
    end -- if

    drawLights()
end -- function

function luven.drawEnd()
    if (useIntegratedCamera) then
        luven.camera:unset()
    end -- if
    
    lg.setBlendMode("multiply", "premultiplied")
    lgDraw(lightMap)
    lg.setBlendMode("alpha")
end -- function

function luven.dispose()
    for _, v in pairs(currentLights) do
        if (v.enabled) then
            luven.removeLight(v.id)
        end -- if
    end -- for

    clearTable(currentLights)

    lightMap:release()
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
function luven.addNormalLight(x, y, color, power, lightShape, angle, sx, sy)
    lightShape = lightShape or luven.lightShapes.round
    angle = angle or 0
    sx = sx or 1
    sy = sy or sx

    local functionName = "luven.addNormalLight(x, y, color, power, angle, sx, sy)"
    assertType(functionName, "x", x, "number")
    assertType(functionName, "y", y, "number")
    assertRangeNumber(functionName, "color[1]", color[1])
    assertRangeNumber(functionName, "color[2]", color[2])
    assertRangeNumber(functionName, "color[3]", color[3])
    assertPositiveNumber(functionName, "power", power)
    assertType(functionName, "angle", angle, "number")
    assertPositiveNumber(functionName, "sx", sx)
    assertPositiveNumber(functionName, "sy", sy)

    local id = getNextId()
    local light = currentLights[id]
    
    clearTable(light)

    light.id = id
    light.x = x
    light.y = y
    light.angle = angle
    light.scaleX = sx
    light.scaleY = sy
    light.color = color
    light.power = power
    light.type = lightTypes.normal
    light.shape = lightShape
    light.origin = calculateLightOrigin(light.id)

    light.enabled = true

    return light.id
end -- function

-- params : colorRange = { min = { r, g, b }, max = { r, g, b }}
--          powerRange = { min = n, max = n }
--          speedRange = { min = n, max = n }
-- return : lightId
function luven.addFlickeringLight(x, y, colorRange, powerRange, speedRange, lightShape, angle, sx, sy)
    lightShape = lightShape or luven.lightShapes.round
    angle = angle or 0
    sx = sx or 1
    sy = sy or sx

    local functionName = "luven.addFlickeringLight(x, y, colorRange, powerRange, speedRange, angle, sx, sy)"
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
    assertType(functionName, "angle", angle, "number")
    assertPositiveNumber(functionName, "sx", sx)
    assertPositiveNumber(functionName, "sy", sy)
    
    local id = getNextId()
    local light = currentLights[id]
    
    clearTable(light)

    light.id = id
    light.x = x
    light.y = y
    light.angle = angle
    light.scaleX = sx
    light.scaleY = sy
    light.color = { 0, 0, 0 }
    light.power = 0
    light.type = lightTypes.flickering
    light.shape = lightShape
    light.origin = calculateLightOrigin(light.id)

    light.flickTimer = 0
    light.colorRange = colorRange
    light.powerRange = powerRange
    light.speedRange = speedRange

    light.enabled = true

    generateFlicker(light.id)

    return light.id
end -- function

function luven.addFlashingLight(x, y, color, maxPower, speed, lightShape, angle, sx, sy)
    lightShape = lightShape or luven.lightShapes.round
    angle = angle or 0
    sx = sx or 1
    sy = sy or sx

    local functionName = "luven.addFlashingLight(x, y, color, maxPower, speed, angle, sx, sy)"
    assertType(functionName, "x", x, "number")
    assertType(functionName, "y", y, "number")
    assertRangeNumber(functionName, "color[1]", color[1])
    assertRangeNumber(functionName, "color[2]", color[2])
    assertRangeNumber(functionName, "color[3]", color[3])
    assertPositiveNumber(functionName, "maxPower", maxPower)
    assertPositiveNumber(functionName, "speed", speed)
    assertType(functionName, "angle", angle, "number")
    assertPositiveNumber(functionName, "sx", sx)
    assertPositiveNumber(functionName, "sy", sy)

    local id = getNextId()
    local light = currentLights[id]
    clearTable(light)

    light.id = id
    light.x = x
    light.y = y
    light.angle = angle
    light.scaleX = sx
    light.scaleY = sy
    light.color = color
    light.power = 0
    light.type = lightTypes.flashing
    light.shape = lightShape
    light.origin = calculateLightOrigin(light.id)
    
    light.maxPower = maxPower
    light.speed = speed
    light.timer = 0

    light.enabled = true
end -- function

function luven.removeLight(lightId)
    currentLights[lightId].enabled = false
end -- function

function luven.moveLight(lightId, dx, dy)
    currentLights[lightId].x = currentLights[index].x + dx
    currentLights[lightId].y = currentLights[index].y + dy
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

function luven.setLightRotation(lightId, dr)
    currentLights[lightId].angle = dr
end -- function

function luven.setLightScale(lightId, sx, sy)
    sx = sx or 1
    sy = sy or sx

    currentLights[lightId].scaleX = sx
    currentLights[lightId].scaleY = sy
end -- function

function luven.getLightPower(lightId)
    return currentLights[lightId].power
end -- function

function luven.getLightColor(lightId)
    return currentLights[lightId].color
end -- function

function luven.getLightPosition(lightId)
    return currentLights[lightId].x, currentLights[lightId].y
end -- function

function luven.getLightRotation(lightId)
    return currentLights[lightId].angle
end -- function

function luven.getLightScale(lightId)
    return currentLights[lightId].scaleX, currentLights[lightId].scaleY
end -- function

return luven