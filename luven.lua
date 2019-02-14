local luven = {
    _VERSION     = 'luven v0.5',
    _URL         = 'https://github.com/lionelleeser/Luven',
    _DESCRIPTION = 'A minimalitic lighting system for Löve2D',
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
-- /// Luven variables declarations
-- ///////////////////////////////////////////////

local NUM_LIGHTS = 32
local shader_code = [[
    #define NUM_LIGHTS 32

    struct Light {
        vec2 position;
        vec3 diffuse;
        float power;
        bool enabled;
    };

    extern Light lights[NUM_LIGHTS];

    extern vec2 screen;
    extern vec3 ambientLightColor = vec3(0);

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
                vec2 norm_pos = light.position / screen;
                
                float distance = length(norm_pos - norm_screen) / (light.power / 1000);
                float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));
                diffuse += light.diffuse * attenuation;
            }
        }

        diffuse = clamp(diffuse, 0.0, 1.0);

        return pixel * vec4(diffuse, 1.0);
    }
]]

local light_types = {
    normal = 0,
    flickering = 1
}

local currentLights = {}
local luven_shader = nil

-- ///////////////////////////////////////////////
-- /// Luven utils local functions
-- ///////////////////////////////////////////////

local function registerLight(light)
    light.name = "lights[" .. light.id .."]"

    table.insert(currentLights, light)

    luven_shader:send(light.name .. ".position", { light.x , light.y })
    luven_shader:send(light.name .. ".diffuse", light.color)
    luven_shader:send(light.name .. ".power", light.power)
    luven_shader:send(light.name .. ".enabled", light.enabled)
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

    return 0
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

-- ///////////////////////////////////////////////
-- /// Luven general functions
-- ///////////////////////////////////////////////

function luven.init(screen_width, screen_height)
    luven_shader = love.graphics.newShader(shader_code)
    luven_shader:send("screen", {
        screen_width,
        screen_height
    })

    for i = 1, NUM_LIGHTS do
        currentLights[i] = nil
        luven_shader:send("lights[" .. i - 1 .. "]" ..  ".enabled", false)
    end -- for
end -- function

-- param : color = { r, g, b } (Values between 0 - 1)
function luven.setAmbientLightColor(color)
    luven_shader:send("ambientLightColor", color)
end -- function

function luven.drawBegin()
    love.graphics.setShader(luven_shader)
end -- function

function luven.drawEnd()
    love.graphics.setShader()
end -- function

-- ///////////////////////////////////////////////
-- /// Luven lights functions
-- ///////////////////////////////////////////////

-- param : color = { r, g, b } (values between 0 - 1)
-- return : lightId
function luven.addNormalLight(x, y, color, power)
    local light = {}

    light.x = x
    light.y = y
    light.color = color
    light.power = power
    light.type = light_types.normal
    
    light.id = getNextId()

    light.enabled = true

    registerLight(light)

    return light.id
end -- function

function luven.removeLight(lightId)
    local index = lightId + 1
    currentLights[index].enabled = false
    luven_shader:send(currentLights[index].name .. ".enabled", currentLights[index].enabled)
end -- function

function luven.setLightPower(lightId, power)
    local index = lightId + 1
    currentLights[index].power = power
    luven_shader:send(currentLights[index].name .. ".power", currentLights[index].power)
end -- function

-- param : color = { r, g, b } (values between 0 - 1)
function luven.setLightColor(lightId, color)
    local index = lightId + 1
    currentLights[index].color = color
    luven_shader:send(currentLights[index].name .. ".diffuse", currentLights[index].color)
end -- function

function luven.setLightPosition(lightId, x, y)
    local index = lightId + 1
    currentLights[index].x = x
    currentLights[index].y = y
    luven_shader:send(currentLights[index].name .. ".position", { currentLights[index].x, currentLights[index].y })
end -- function

function luven.moveLight(lightId, vx, vy)
    local index = lightId + 1
    currentLights[index].x = currentLights[index].x + vx
    currentLights[index].y = currentLights[index].y + vy
    luven_shader:send(currentLights[index].name .. ".position", { currentLights[index].x, currentLights[index].y })
end -- function

return luven