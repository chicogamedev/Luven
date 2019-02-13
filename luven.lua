local luven = {
    _VERSION     = 'luven v0.1',
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

local NUM_LIGHTS = 32

local shader_code_SAVE = [[
    #define NUM_LIGHTS 32

    struct Light {
        vec2 position;
        vec3 diffuse;
        float power;
    };

    extern Light lights[NUM_LIGHTS];
    extern int num_lights;

    extern vec2 screen;

    const float constant = 1.0;
    const float linear = 0.09;
    const float quadratic = 0.032;

    vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
        vec4 pixel = Texel(image, uvs);

        vec2 norm_screen = screen_coords / screen;
        vec3 diffuse = vec3(0); // Ambiant light (Should be configurable)

        for (int i = 0; i < num_lights; i++) {
            Light light = lights[i];
            vec2 norm_pos = light.position / screen;
            
            float distance = length(norm_pos - norm_screen) / (light.power / 1000);
            float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));
            diffuse += light.diffuse * attenuation;
        }

        diffuse = clamp(diffuse, 0.0, 1.0);

        return pixel * vec4(diffuse, 1.0);
    }
]]

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
    extern vec3 ambiantLight;

    const float constant = 1.0;
    const float linear = 0.09;
    const float quadratic = 0.032;

    vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
        vec4 pixel = Texel(image, uvs);

        vec2 norm_screen = screen_coords / screen;
        vec3 diffuse = vec3(0); // Ambiant light

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

function luven.init(screen_width, screen_height)
    -- If there is already registred lights, remove them before reinitializing currentLights table.
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

-- params : color = { r, g, b } (values between 0 - 1)
-- return : light ID
function luven.addNormalLight(x, y, color, power)
    local light = {}

    light.x = x
    light.y = y
    light.color = color
    light.power = power
    
    light.id = getNextId()

    light.enabled = true

    registerLight(light)

    return light.id
end -- function

function luven.removeLight(lightId)
    local index = findLightIndex(lightId)
    luven_shader:send(currentLights[index].name .. ".enabled", false)
    currentLights[index].enabled = false
end -- function

function luven.drawBegin()
    love.graphics.setShader(luven_shader)
end -- function

function luven.drawEnd()
    love.graphics.setShader()
end -- function

-- UTILS FUNCTIONS 

function registerLight(light)
    light.name = "lights[" .. light.id .."]"

    table.insert(currentLights, light)

    luven_shader:send(light.name .. ".position", { light.x , light.y })
    luven_shader:send(light.name .. ".diffuse", light.color)
    luven_shader:send(light.name .. ".power", light.power)
    luven_shader:send(light.name .. ".enabled", light.enabled)
end -- function

function getNextId()
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

function getNumberLights()
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

function findLightIndex(lightId)
    for i = 1, NUM_LIGHTS do
        local currentLight = currentLights[i]
        if (currentLight ~= nil) then
            if (currentLight.id == lightId) then
                return i
            end -- if
        end -- if
    end -- for
end -- if

return luven