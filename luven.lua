local luven = {
    _VERSION     = 'luven v0.8',
    _URL         = 'https://github.com/lionelleeser/Luven',
    _DESCRIPTION = 'A minimalitic lighting system for Löve2D',
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

local NUM_LIGHTS = 64
local shader_code = [[
    #define NUM_LIGHTS 64

    struct Light {
        vec2 position;
        vec3 diffuse;
        float power;
        bool enabled;
    };

    extern Light lights[NUM_LIGHTS];

    extern vec2 screen;
    extern vec3 ambientLightColor = vec3(0);

    extern mat4 viewMatrix;

    const float constant = 1.0;
    const float linear = 0.09;
    const float quadratic = 0.032;

    vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
        vec4 pixel = Texel(image, uvs);
        pixel *= color;

        vec2 norm_screen = screen_coords / screen;
        vec3 diffuse = ambientLightColor;

        for (int i = 0; i < NUM_LIGHTS; i++) {
            if (lights[i].enabled) {
                Light light = lights[i];
                vec2 norm_pos = (viewMatrix * vec4(light.position, 0.0, 1.0)).xy / screen;
                
                float distance = length(norm_pos - norm_screen) / (light.power / 1000);
                float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));
                diffuse += light.diffuse * attenuation;
            }
        }

        diffuse = clamp(diffuse, 0.0, 1.0);

        return pixel * vec4(diffuse, 1.0);
    }
]]

local lightTypes = {
    normal = 0,
    flickering = 1,
    flashing = 2
}

local currentLights = {}
local luvenShader = nil
local useIntegratedCamera = true

-- ///////////////////////////////////////////////
-- /// Luven utils local functions
-- ///////////////////////////////////////////////

local function updateLight(lightId)
    local light = currentLights[lightId + 1]

    luvenShader:send(light.name .. ".position", { light.x , light.y })
    luvenShader:send(light.name .. ".diffuse", light.color)
    luvenShader:send(light.name .. ".power", light.power)
    luvenShader:send(light.name .. ".enabled", light.enabled)
end -- function

local function registerLight(light)
    light.name = "lights[" .. light.id .."]"

    currentLights[light.id + 1] = light

    updateLight(light.id)
end -- function

local function getNumberLights()
    local count = 0

    for i = 1, NUM_LIGHTS do
        local currentLight = currentLights[i]
        if (currentLight ~= nil) then
            if (currentLight.enabled) then
                count = count + 1
            end -- if
        end -- if
    end -- for

    return count
end -- function

local function getNextId()
    for i = 1, NUM_LIGHTS do
        local currentLight = currentLights[i]
        if (currentLight ~= nil) then
            if (currentLight.enabled == false) then
                return i - 1 
            end -- if
        else
            return i - 1
        end -- if
    end -- for

    if (getNumberLights() == NUM_LIGHTS) then
        -- All lights are in use
        error("Light cannot be created, no more light available!")
    else
        return 0 -- first index
    end -- if
end -- function

local function randomFloat(min, max)
        return min + love.math.random() * (max - min);
end -- function

local function generateFlicker(lightId)
    local light = currentLights[lightId + 1]

    light.color[1] = randomFloat(light.colorRange.min[1], light.colorRange.max[1])
    light.color[2] = randomFloat(light.colorRange.min[2], light.colorRange.max[2])
    light.color[3] = randomFloat(light.colorRange.min[3], light.colorRange.max[3])

    light.power = randomFloat(light.powerRange.min, light.powerRange.max)

    light.flickTimer = randomFloat(light.speedRange.min, light.speedRange.max)

    updateLight(light.id)
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

    luvenShader = love.graphics.newShader(shader_code)
    luvenShader:send("screen", {
        screenWidth,
        screenHeight
    })

    for i = 1, NUM_LIGHTS do
        currentLights[i] = { enabled = false }
        luvenShader:send("lights[" .. i - 1 .. "]" ..  ".enabled", false)
    end -- for
end -- function

-- param : color = { r, g, b } (Values between 0 - 1)
function luven.setAmbientLightColor(color)
    luvenShader:send("ambientLightColor", color)
end -- function

function luven.update(dt)
    if (useIntegratedCamera) then
        cameraUpdate(dt)
    end -- if

    for _, light in pairs(currentLights) do
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
                    luvenShader:send(light.name .. ".power", light.power)
                else
                    luven.removeLight(light.id)
                end -- if
            end -- if
        end -- if
    end -- for
end -- function

function luven.sendCustomViewMatrix(viewMatrix)
    luvenShader:send("viewMatrix", viewMatrix)
end -- function

function luven.drawBegin()
    if (useIntegratedCamera) then
        cameraDraw()
        luven.camera:set()
        luven.sendCustomViewMatrix({ cameraGetViewMatrix() })
    end -- if
    
    love.graphics.setShader(luvenShader)
end -- function

function luven.drawEnd()
    love.graphics.setShader()

    if (useIntegratedCamera) then
        luven.camera:unset()
    end -- if
end -- function

function luven.dispose()
    for _, v in pairs(currentLights) do
        if (v.enabled) then
            luven.removeLight(v.id)
        end -- if
    end -- for

    for k, _ in pairs(currentLights) do
        table.remove(currentLights, k)
    end -- for
end -- if

-- ///////////////////////////////////////////////
-- /// Luven lights functions
-- ///////////////////////////////////////////////

-- param : color = { r, g, b } (values between 0 - 1)
-- return : lightId
function luven.addNormalLight(x, y, color, power)
    local light = {}

    light.id = getNextId()
    light.x = x
    light.y = y
    light.color = color
    light.power = power
    light.type = lightTypes.normal

    light.enabled = true

    registerLight(light)

    return light.id
end -- function

-- params : colorRange = { min = { r, g, b }, max = { r, g, b }}
--          powerRange = { min = n, max = n }
--          speedRange = { min = n, max = n }
-- return : lightId
function luven.addFlickeringLight(x, y, colorRange, powerRange, speedRange)
    local light = {}

    light.id = getNextId()
    light.x = x
    light.y = y
    light.color = { 0, 0, 0 }
    light.power = 0
    light.type = lightTypes.flickering

    light.flickTimer = 0
    light.colorRange = colorRange
    light.powerRange = powerRange
    light.speedRange = speedRange

    light.enabled = true

    registerLight(light)

    generateFlicker(light.id)

    return light.id
end -- function

function luven.addFlashingLight(x, y, color, maxPower, speed)
    local light = {}

    light.id = getNextId()
    light.x = x
    light.y = y
    light.color = color
    light.power = 0
    light.type = lightTypes.flashing
    
    light.maxPower = maxPower
    light.speed = speed
    light.timer = 0

    light.enabled = true

    print(light.id)

    registerLight(light)
end -- function

function luven.removeLight(lightId)
    local index = lightId + 1
    currentLights[index].enabled = false
    luvenShader:send(currentLights[index].name .. ".enabled", currentLights[index].enabled)
end -- function

function luven.setLightPower(lightId, power)
    local index = lightId + 1
    currentLights[index].power = power
    luvenShader:send(currentLights[index].name .. ".power", currentLights[index].power)
end -- function

-- param : color = { r, g, b } (values between 0 - 1)
function luven.setLightColor(lightId, color)
    local index = lightId + 1
    currentLights[index].color = color
    luvenShader:send(currentLights[index].name .. ".diffuse", currentLights[index].color)
end -- function

function luven.setLightPosition(lightId, x, y)
    local index = lightId + 1
    currentLights[index].x = x
    currentLights[index].y = y
    luvenShader:send(currentLights[index].name .. ".position", { currentLights[index].x, currentLights[index].y })
end -- function

function luven.moveLight(lightId, vx, vy)
    local index = lightId + 1
    currentLights[index].x = currentLights[index].x + vx
    currentLights[index].y = currentLights[index].y + vy
    luvenShader:send(currentLights[index].name .. ".position", { currentLights[index].x, currentLights[index].y })
end -- function

function luven.getLightPosition(lightId)
    local index = lightId + 1
    return currentLights[index].x, currentLights[index].y
end -- function

function luven.getLightPower(lightId)
    local index = lightId + 1
    return currentLights[index].power
end -- function

function luven.getLightColor(lightId)
    local index = lightId + 1
    return currentLights[index].color
end -- function

return luven