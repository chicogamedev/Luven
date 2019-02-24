#define NUM_LIGHTS 32

struct Light {
    vec2 position;
    vec3 diffuse;
    float power;
};

extern Light lights[NUM_LIGHTS];

varying vec2 lightsPositions[NUM_LIGHTS];

extern vec2 screen;
extern vec3 ambientLightColor = vec3(0);

extern int lightsCount;

const float constant = 1.0;
const float linear = 0.09;
const float quadratic = 0.032;

vec3 diffuse;

vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords){
    vec4 pixel = Texel(image, uvs) * color;

    vec2 norm_screen = screen_coords / screen;

    diffuse = ambientLightColor;

    for (int i = 0; i < lightsCount; i++) {
        float distance = length(lightsPositions[i] - norm_screen) / (lights[i].power / 1000);
        float attenuation = 1.0 / (constant + linear * distance + quadratic * (distance * distance));
        diffuse += lights[i].diffuse * attenuation;
    }

    diffuse = clamp(diffuse, 0.0, 1.0);

    return pixel * vec4(diffuse, 1.0);
}