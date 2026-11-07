#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 uBaseColor;
    vec4 uAccentColor;
    vec2 uSize;
    float uRadius;
    float uHover;
    float uPressed;
};

float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - r;
}

void main() {
    vec2 p = qt_TexCoord0 * uSize;
    vec2 halfSize = uSize * 0.5;
    vec2 pos = p - halfSize;
    float r = min(uRadius, min(halfSize.x, halfSize.y));
    
    float d = sdRoundedBox(pos, halfSize, r);
    float antialias = 1.0 - smoothstep(-0.6, 0.6, d);
    if (antialias <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    
    float distToEdge = max(0.0, -d);
    
    // Normalized depth across the 3D bulge (0 at rim, 1 at center ridge)
    float depthNorm = clamp(distToEdge / r, 0.0, 1.0);
    
    // Direction vector from center outward (top is pos.y < 0, bottom is pos.y > 0)
    vec2 q = abs(pos) - (halfSize - vec2(r));
    vec2 edgeDir;
    if (q.x > 0.0 && q.y > 0.0) {
        edgeDir = normalize(q) * sign(pos);
    } else if (q.x > q.y) {
        edgeDir = vec2(sign(pos.x), 0.0);
    } else {
        edgeDir = vec2(0.0, sign(pos.y));
    }
    
    // 3D convex dome normal:
    // Outward gradient follows edgeDir:
    // At top (pos.y < 0): edgeDir.y < 0, so domeNxy.y < 0
    // At bottom (pos.y > 0): edgeDir.y > 0, so domeNxy.y > 0
    float domeZ = sqrt(max(0.001, 1.0 - pow(1.0 - depthNorm, 2.0)));
    vec2 domeNxy = edgeDir * pow(1.0 - depthNorm, 1.1) * 0.85;
    vec3 N = normalize(vec3(domeNxy, domeZ * 0.95));
    
    vec3 V = vec3(0.0, 0.0, 1.0);
    
    // ── 1. Fresnel Rim Glare ─────────────────────────────────────────
    float fresnel = pow(clamp(1.0 - N.z, 0.0, 1.0), 3.5) * 0.22;
    
    // ── 2. Overhead Light from the Top of the Screen ─────────────────
    // Top of screen is -y in qt_TexCoord0
    vec3 L1 = normalize(vec3(-0.15, -0.85, 0.55));
    vec3 H1 = normalize(L1 + V);
    float NdotH1 = max(0.0, dot(N, H1));
    
    // Silky gloss highlight curving along the UPPER convex shoulder
    float specDome = pow(NdotH1, 24.0) * (0.32 + uHover * 0.14);
    // Crisp glint on the upper ridge
    float specGlint = pow(NdotH1, 72.0) * (0.35 + uHover * 0.18);
    
    // ── 3. Subtle Bounce Light from Floor (+y) ───────────────────────
    vec3 L2 = normalize(vec3(0.10, 0.80, 0.60));
    vec3 H2 = normalize(L2 + V);
    float NdotH2 = max(0.0, dot(N, H2));
    float specBounce = pow(NdotH2, 32.0) * 0.14;
    
    // ── 4. Luminous Translucency & 3D Bulge Depth ────────────────────
    // Rich, tangible frosted glass translucency
    float centerAlpha = mix(0.13, 0.19, uHover);
    // Convex thickness: center is thickest, curving gracefully to the perimeter
    float convexBulge = pow(depthNorm, 0.65) * 0.09;
    float edgeRefractAlpha = fresnel * 0.30 + (1.0 - depthNorm) * 0.08;
    
    // Ultra-delicate 0.8px outer boundary
    float outerRim = smoothstep(0.9, 0.2, distToEdge) * 0.16;
    
    float totalAlpha = clamp(centerAlpha + convexBulge + edgeRefractAlpha + specDome * 0.4 + specGlint * 0.4 + outerRim, 0.0, 1.0);
    
    // ── 5. Jewel-Tone Color Composition ──────────────────────────────
    vec3 glassTint = uAccentColor.rgb;
    // Translucent crystal glass body with subtle theme warmth
    vec3 bodyColor = mix(vec3(0.94), glassTint, 0.40);
    
    vec3 color = bodyColor * (centerAlpha + convexBulge);
    // Theme accent gently concentrated at the rim
    color += glassTint * ((1.0 - depthNorm) * 0.20 + fresnel * 0.22);
    // Floor bounce
    color += glassTint * specBounce;
    // Pure dielectric white specular sheen along the TOP shoulder
    color += vec3(1.0) * (specDome + specGlint + outerRim * 0.40);
    
    fragColor = vec4(color * totalAlpha, totalAlpha * antialias) * qt_Opacity;
}
