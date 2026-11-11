#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float PI = 3.14159265359;
const float DISTORTION = 0.06;
const float SCANLINE_FREQ = 600.0;
const float CHROMATIC = 0.0022;
const float VIGNETTE_RADIUS = 0.85;

vec2 barrelDistortion(vec2 coord, float amt) {
    vec2 v = coord * 2.0 - 1.0;
    float r = dot(v, v);
    float k = 1.0 + r * (amt * amt);
    vec2 res = v * k;
    return (res + 1.0) * 0.5;
}

void main() {
    vec2 tc = barrelDistortion(v_texcoord, DISTORTION);

    // Bezel crop
    if (tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0 || tc.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // Chromatic Aberration
    vec2 shift = vec2(CHROMATIC, 0.0);
    float r = texture(tex, tc + shift).r;
    float g = texture(tex, tc).g;
    float b = texture(tex, tc - shift).b;
    float a = texture(tex, tc).a;
    vec4 color = vec4(r, g, b, a);

    // Scanlines
    float scanline = sin(tc.y * SCANLINE_FREQ * PI * 2.0) * 0.5 + 0.5;
    scanline = pow(scanline, 1.4);
    color.rgb *= mix(1.0, 0.82, scanline);

    // Vignette
    vec2 offset = v_texcoord - vec2(0.5);
    float dist = length(offset);
    float vig = smoothstep(VIGNETTE_RADIUS, VIGNETTE_RADIUS - 0.45, dist);
    color.rgb = mix(color.rgb * 0.65, color.rgb, vig);

    // Screen edge bezel darkening
    float edge = min(min(tc.x, 1.0 - tc.x), min(tc.y, 1.0 - tc.y));
    float bezel = smoothstep(0.0, 0.015, edge);
    color.rgb *= bezel;

    // Slight CRT phosphor warm boost
    color.rgb = pow(color.rgb, vec3(0.96, 0.98, 0.96));

    fragColor = color;
}
