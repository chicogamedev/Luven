#define NUM_LIGHTS 32

struct Light {
    vec2 position;
    vec3 diffuse;
    float power;
};

extern Light lights[NUM_LIGHTS];

varying vec2 lightsPositions[NUM_LIGHTS];

extern vec2 screen;

extern mat4 viewMatrix;

extern int lightsCount;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    for (int i = 0; i < lightsCount; i++) {
        lightsPositions[i] = (viewMatrix * vec4(lights[i].position, 0.0, 1.0)).xy / screen;
    }

    return transform_projection * vertex_position;
}