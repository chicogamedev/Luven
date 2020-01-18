local luven = {
    _VERSION     = 'Luven v1.3',
    _URL         = 'https://github.com/chicogamedev/Luven',
    _DESCRIPTION = 'A minimalist light engine for Löve2D',
    _CONTRIBUTORS = 'Lionel Leeser, Pedro Gimeno (Help with camera)',
    _LICENSE     = [[
        MIT License

        Copyright (c) 2020 Lionel Leeser

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
    end
end

local function assertRangeNumber(functionName, parameterName, parameterValue, min, max, level)
    min = min or 0
    max = max or 1
    level = level or 3
    if ((type(parameterValue) ~= "number") or (parameterValue < min) or (parameterValue > max)) then
        error(functionName .. "\n        parameter : " .. parameterName .. ", expected range number between " .. min .. " and " .. max .. ".", level)
    end
end

local function assertType(functionName, parameterName, parameterValue, parameterType, level)
    level = level or 3
    if (type(parameterValue) ~= parameterType) then
        error(functionName .. "\n        parameter : " .. parameterName .. ", expected type ".. parameterType .. ".", level)
    end
end

local function assertLightShape(newShapeName, level)
    level = level or 3
    if (luven.lightShapes[newShapeName] ~= nil) then
        error("The light shapes : " .. newShapeName .. " already exists, please set another name.")
    end
end

-- ///////////////////////////////////////////////
-- /// Math functions
-- ///////////////////////////////////////////////

local function lerp(a, b, x)
     return a + (b - a)*x
end

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

luven.camera.fading = false
luven.camera.fadeDuration = 0
luven.camera.fadeTimer = 0
luven.camera.fadeColor = { 0, 0, 0, 0 }
luven.camera.startFadeColor = nil
luven.camera.endFadeColor = nil
luven.camera.fadeAction = nil

luven.camera.useTarget = false
luven.camera.moveTarget = { x = 0, y = 0 }
luven.camera.moveSmooth = { x = 0, y = 0 }

-- //////////////////////////////
-- /// Camera local functions
-- //////////////////////////////

local function cameraUpdate(dt)
    local lc = luven.camera

    if (lc.shakeDuration > 0) then
        lc.shakeDuration = lc.shakeDuration - dt
    end

    if (lc.fading) then
        lc.fadeTimer = lc.fadeTimer + dt
        lc.fadeColor = {
            lerp(lc.startFadeColor[1], lc.endFadeColor[1], lc.fadeTimer / lc.fadeDuration),
            lerp(lc.startFadeColor[2], lc.endFadeColor[2], lc.fadeTimer / lc.fadeDuration),
            lerp(lc.startFadeColor[3], lc.endFadeColor[3], lc.fadeTimer / lc.fadeDuration),
            lerp(lc.startFadeColor[4], lc.endFadeColor[4], lc.fadeTimer / lc.fadeDuration)
        }

        if (lc.fadeTimer >= lc.fadeDuration) then
            lc.fadeTimer = 0
            lc.fading = false

            if (lc.fadeAction ~= nil) then
                lc.fadeAction()
            end
        end
    end

    if (lc.useTarget) then
        lc.x = lerp(lc.x, lc.moveTarget.x, lc.moveSmooth.x)
        lc.y = lerp(lc.y, lc.moveTarget.y, lc.moveSmooth.y)
    end
end

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
    self.moveTarget.x = x
    self.moveTarget.y = y
end

function luven.camera:set()
    local dx, dy = 0, 0
    if (luven.camera.shakeDuration > 0) then
        dx = love.math.random(-luven.camera.shakeMagnitude, luven.camera.shakeMagnitude)
        dy = love.math.random(-luven.camera.shakeMagnitude, luven.camera.shakeMagnitude)
    end
    lg.push()
    self.transform:setTransformation(lg.getWidth() / 2, lg.getHeight() / 2, self.rotation, self.scaleX, self.scaleY, self.x + dx, self.y + dy)
    lg.applyTransform(self.transform)
end

function luven.camera:unset()
    lg.pop()
end

function luven.camera:draw()
    local oldR, oldG, oldB, oldA = lg.getColor()

    -- Fade rectangle
    lg.setColor(self.fadeColor)
    lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())

    lg.setColor(oldR, oldG, oldB, oldA)
end

function luven.camera:setPosition(x, y)
    self.x = x
    self.y = y
    self.useTarget = false
end

function luven.camera:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    self.useTarget = false
end

function luven.camera:setMoveSmooth(x, y)
    y = y or x

    self.moveSmooth.x = x
    self.moveSmooth.y = y
end

function luven.camera:setMoveTarget(x, y)
    self.moveTarget.x = x
    self.moveTarget.y = y
    self.useTarget = true
end

function luven.camera:setRotation(dr)
    self.rotation = dr
end

function luven.camera:setScale(sx, sy)
    self.scaleX = sx or 1
    self.scaleY = sy or sx or 1
end

function luven.camera:setShake(duration, magnitude)
    self.shakeDuration = duration
    self.shakeMagnitude = magnitude
end

-- color : COLOR : { r, g, b, a }
-- action : FUNCTION
function luven.camera:setFade(duration, color, action)
    self.fadeDuration = duration
    self.fadeTimer = 0
    self.startFadeColor = self.fadeColor
    self.endFadeColor = color
    self.fadeAction = action
    self.fading = true
end

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

local function getLastEnabledLightIndex()
    for i = NUM_LIGHTS, 1, -1 do
        if (currentLights[i].enabled) then
            return i
        end
    end

    return 0
end

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
            lgDraw(light.shape.sprite, light.x, light.y, light.angle, light.scaleX * light.power, light.scaleY * light.power, light.shape.originX, light.shape.originY)
        end
    end

    lgSetColor(oldR, oldG, oldB, oldA)
    lg.setBlendMode("alpha")

    lg.setCanvas()
end

local function getNextId()
    for i = 1, NUM_LIGHTS do
        local light = currentLights[i]
        if (light.enabled == false) then
            return i
        end
    end

    return 1 -- first index
end

local function randomFloat(min, max)
        return min + love.math.random() * (max - min)
end

local function clearTable(table)
    for k, _ in pairs(table) do table[k]=nil end
end

local function generateFlicker(lightId)
    local light = currentLights[lightId]

    light.color[1] = randomFloat(light.colorRange.min[1], light.colorRange.max[1])
    light.color[2] = randomFloat(light.colorRange.min[2], light.colorRange.max[2])
    light.color[3] = randomFloat(light.colorRange.min[3], light.colorRange.max[3])

    light.power = randomFloat(light.powerRange.min, light.powerRange.max)

    light.flickTimer = randomFloat(light.speedRange.min, light.speedRange.max)
end

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
    end

    local functionName = "luven.init( [ screenWidth ], [ screenHeight ], [ useCamera ] )"
    assertPositiveNumber(functionName, "screenWidth", screenWidth)
    assertPositiveNumber(functionName, "screenHeight", screenHeight)
    assertType(functionName, "useCamera", useIntegratedCamera, "boolean")

    luven.registerLightShape("round", luvenPath .. "lights/round.png")
    luven.registerLightShape("rectangle", luvenPath .. "lights/rectangle.png")
    luven.registerLightShape("cone", luvenPath .. "lights/cone.png", 0)

    lightMap = lg.newCanvas(screenWidth, screenHeight)

    for i = 1, NUM_LIGHTS do
        currentLights[i] = { enabled = false }
    end
end

-- param : color = { r, g, b, a (1) } (Values between 0 - 1)
function luven.setAmbientLightColor(color)
    color[4] = color[4] or 1
    ambientLightColor = color
end

function luven.registerLightShape(name, spritePath, originX, originY)
    local functionName = "luven.registerLightShape( name, spritePath, [ originX ], [ originY ] )"
    assertLightShape(name)
    assertType(functionName, "spritePath", spritePath, "string")

    local lightSprite = lg.newImage(spritePath)
    originX = originX or (lightSprite:getWidth() / 2)
    originY = originY or (lightSprite:getHeight() / 2)

    assertPositiveNumber(functionName, "originX", originX)
    assertPositiveNumber(functionName, "originY", originY)

    luven.lightShapes[name] = {
        sprite = lightSprite,
        originX = originX,
        originY = originY
    }
end

function luven.update(dt)
    if (useIntegratedCamera) then
        cameraUpdate(dt)
    end

    lastActiveLightIndex = getLastEnabledLightIndex()

    for i = 1, lastActiveLightIndex do
        local light = currentLights[i]
        if (light.enabled) then
            if (light.type == lightTypes.flickering) then
                if (light.flickTimer > 0) then
                    light.flickTimer = light.flickTimer - dt
                else
                    generateFlicker(light.id)
                end
            elseif (light.type == lightTypes.flashing) then
                light.timer = light.timer + dt
                if (light.power < light.maxPower) then
                    light.power = (light.maxPower * light.timer) / light.speed
                else
                    luven.removeLight(light.id)
                end
            end
        end
    end
end

function luven.drawBegin()
    if (useIntegratedCamera) then
        luven.camera:set()
    end

    drawLights()
end

function luven.drawEnd()
    if (useIntegratedCamera) then
        luven.camera:unset()
    end

    lg.setBlendMode("multiply", "premultiplied")
    lgDraw(lightMap)
    lg.setBlendMode("alpha")
end

function luven.removeAllLights()
    for _, v in pairs(currentLights) do
        if (v.enabled) then
            luven.removeLight(v.id)
        end
    end
end

function luven.dispose()
    luven.removeAllLights()

    clearTable(currentLights)
    clearTable(luven.lightShapes)

    lightMap:release()
end

function luven.getLightCount()
    local count = 0

    for i = 1, lastActiveLightIndex do
        if (currentLights[i].enabled) then
            count = count + 1
        end
    end

    return count
end

-- ///////////////////////////////////////////////
-- /// Luven utils functions
-- ///////////////////////////////////////////////

function luven.newColor(r, g, b, a)
    a = a or 1
    return { r, g, b, a }
end

function luven.newColorRange(minR, minG, minB, maxR, maxG, maxB, minA, maxA)
    minR = minR or 0
    minG = minG or 0
    minB = minB or 0
    maxR = maxR or 0
    maxG = maxG or 0
    maxB = maxB or 0
    minA = minA or 1
    maxA = maxA or 1
    return { min = { minR, minG, minB, minA }, max = { maxR, maxG, maxB, maxA } }
end

function luven.newNumberRange(minN, maxN)
    return { min = minN, max = maxN }
end

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

    light.enabled = true

    return light.id
end

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

    light.flickTimer = 0
    light.colorRange = colorRange
    light.powerRange = powerRange
    light.speedRange = speedRange

    light.enabled = true

    generateFlicker(light.id)

    return light.id
end

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

    light.maxPower = maxPower
    light.speed = speed
    light.timer = 0

    light.enabled = true
end

function luven.removeLight(lightId)
    currentLights[lightId].enabled = false
end

function luven.moveLight(lightId, dx, dy)
    currentLights[lightId].x = currentLights[index].x + dx
    currentLights[lightId].y = currentLights[index].y + dy
end

function luven.setLightPower(lightId, p)
    currentLights[lightId].power = p
end

function luven.setLightPowerRange(lightId, r)
    currentLights[lightId].powerRange = r
end

-- param : color = { r, g, b } (values between 0 - 1)
function luven.setLightColor(lightId, c)
    currentLights[lightId].color = c
end

function luven.setLightColorRange(lightId, r)
    currentLights[lightId].colorRange = r
end

function luven.setLightPosition(lightId, x, y)
    currentLights[lightId].x = x
    currentLights[lightId].y = y
end

function luven.setLightRotation(lightId, dr)
    currentLights[lightId].angle = dr
end

function luven.setLightSpeedRange(lightId, r)
    currentLights[lightId].speedRange = r
end

function luven.setLightScale(lightId, sx, sy)
    sx = sx or 1
    sy = sy or sx

    currentLights[lightId].scaleX = sx
    currentLights[lightId].scaleY = sy
end

function luven.getLightPower(lightId)
    return currentLights[lightId].power
end

function luven.getLightPowerRange(lightId)
    return currentLights[lightId].powerRange
end

function luven.getLightColor(lightId)
    return currentLights[lightId].color
end

function luven.getLightColorRange(lightId)
    return currentLights[lightId].colorRange
end

function luven.getLightPosition(lightId)
    return currentLights[lightId].x, currentLights[lightId].y
end

function luven.getLightRotation(lightId)
    return currentLights[lightId].angle
end

function luven.getLightSpeedRange(lightId)
    return currentLights[lightId].speedRange
end

function luven.getLightScale(lightId)
    return currentLights[lightId].scaleX, currentLights[lightId].scaleY
end

return luven
