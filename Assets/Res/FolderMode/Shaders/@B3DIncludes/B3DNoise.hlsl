#ifndef B3DNOISE_INCLUDED
#define B3DNOISE_INCLUDED

#include "B3DCommon.hlsl"

float noise_grad(uint hash, float x, float y, float z)
{
    uint h = hash & 15u;
    float u = h < 8u ? x : y;
    float vt = ((h == 12u) || (h == 14u)) ? x : z;
    float v = h < 4u ? y : vt;
    return negate_if(u, h & 1u) + negate_if(v, h & 2u);
}

float noise_grad(uint hash, float x, float y, float z, float w)
{
    uint h = hash & 31u;
    float u = h < 24u ? x : y;
    float v = h < 16u ? y : z;
    float s = h < 8u ? z : w;
    return negate_if(u, h & 1u) + negate_if(v, h & 2u) + negate_if(s, h & 4u);
}

float noise_perlin(vec3 vec)
{
    int X, Y, Z;
    float fx, fy, fz;

    FLOORFRAC(vec.x, X, fx);
    FLOORFRAC(vec.y, Y, fy);
    FLOORFRAC(vec.z, Z, fz);

    float u = fade(fx);
    float v = fade(fy);
    float w = fade(fz);

    float r = tri_mix(
        noise_grad(hash_int3(X, Y, Z), fx, fy, fz),
        noise_grad(hash_int3(X + 1, Y, Z), fx - 1, fy, fz),
        noise_grad(hash_int3(X, Y + 1, Z), fx, fy - 1, fz),
        noise_grad(hash_int3(X + 1, Y + 1, Z), fx - 1, fy - 1, fz),
        noise_grad(hash_int3(X, Y, Z + 1), fx, fy, fz - 1),
        noise_grad(hash_int3(X + 1, Y, Z + 1), fx - 1, fy, fz - 1),
        noise_grad(hash_int3(X, Y + 1, Z + 1), fx, fy - 1, fz - 1),
        noise_grad(hash_int3(X + 1, Y + 1, Z + 1), fx - 1, fy - 1, fz - 1),
        u,
        v,
        w);

    return r;
}


float noise_scale3(float result)
{
    return 0.9820 * result;
}

float snoise(vec3 p)
{
    float r = noise_perlin(p);
    return (isinf(r)) ? 0.0 : noise_scale3(r);
}

float noise(vec3 p)
{
    return 0.5 * snoise(p) + 0.5;
}

/* The fractal_noise functions are all exactly the same except for the input type. */
float fractal_noise(vec3 p, float octaves, float roughness)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;
    octaves = clamp(octaves, 0.0, 15.0);
    int n = int(octaves);
    for (int i = 0; i <= n; i++) {
        float t = noise(fscale * p);
        sum += t * amp;
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= 2.0;
    }
    float rmd = octaves - floor(octaves);
    if (rmd != 0.0) {
        float t = noise(fscale * p);
        float sum2 = sum + t * amp;
        sum /= maxamp;
        sum2 /= maxamp + amp;
        return (1.0 - rmd) * sum + rmd * sum2;
    }
    else {
        return sum / maxamp;
    }
}

void node_noise_texture_3d(vec3 co,
    //float w,
    float scale,
    float detail,
    float roughness,
    float distortion,
    out float value,
    out vec4 color
)
{
    vec3 p = co * scale;
    if (distortion != 0.0) {
        p += vec3(snoise(p + random_vec3_offset(0.0)) * distortion,
            snoise(p + random_vec3_offset(1.0)) * distortion,
            snoise(p + random_vec3_offset(2.0)) * distortion);
    }

    value = fractal_noise(p, detail, roughness);
    color = vec4(value,
        fractal_noise(p + random_vec3_offset(3.0), detail, roughness),
        fractal_noise(p + random_vec3_offset(4.0), detail, roughness),
        1.0);
}


#endif