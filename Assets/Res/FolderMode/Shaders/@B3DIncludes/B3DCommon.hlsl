#ifndef B3DCOMMON_INCLUDED
#define B3DCOMMON_INCLUDED

#define mat3 float3x3
#define mat2 float2x2
#define vec3 float3
#define vec4 float4
#define vec2 float2
#define mix lerp
#define M_PI_2 1.57079632679489661923 /* pi/2 */
#define PI 3.1415926535

/* clang-format off */
#define FLOORFRAC(x, x_int, x_fract) { float x_floor = floor(x); x_int = int(x_floor); x_fract = x - x_floor; }
/* clang-format on */
#define rot(x, k) (((x) << (k)) | ((x) >> (32 - (k))))

#define final(a, b, c) \
              { \
                c ^= b; \
                c -= rot(b, 14); \
                a ^= c; \
                a -= rot(c, 11); \
                b ^= a; \
                b -= rot(a, 25); \
                c ^= b; \
                c -= rot(b, 16); \
                a ^= c; \
                a -= rot(c, 4); \
                b ^= a; \
                b -= rot(a, 14); \
                c ^= b; \
                c -= rot(b, 24); \
              }

float tri_mix(float v0,
    float v1,
    float v2,
    float v3,
    float v4,
    float v5,
    float v6,
    float v7,
    float x,
    float y,
    float z)
{
    float x1 = 1.0 - x;
    float y1 = 1.0 - y;
    float z1 = 1.0 - z;
    return z1 * (y1 * (v0 * x1 + v1 * x) + y * (v2 * x1 + v3 * x)) +
        z * (y1 * (v4 * x1 + v5 * x) + y * (v6 * x1 + v7 * x));
}

uint hash_uint3(uint kx, uint ky, uint kz)
{
    uint a, b, c;
    a = b = c = 0xdeadbeefu + (3u << 2u) + 13u;

    c += kz;
    b += ky;
    a += kx;
    final(a, b, c);

    return c;
}

float negate_if(float value, uint condition)
{
    return (condition != 0u) ? -value : value;
}


uint hash_int3(int kx, int ky, int kz)
{
    return hash_uint3(uint(kx), uint(ky), uint(kz));
}

float fade(float t)
{
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

uint floatBitsToUint(float value)
{
    return (uint)(value);
}

uint hash_uint2(uint kx, uint ky)
{
    uint a, b, c;
    a = b = c = 0xdeadbeefu + (2u << 2u) + 13u;

    b += ky;
    a += kx;
    final(a, b, c);

    return c;
}


float hash_uint2_to_float(uint kx, uint ky)
{
    return float(hash_uint2(kx, ky)) / float(0xFFFFFFFFu);
}

float hash_vec2_to_float(vec2 k)
{
    return hash_uint2_to_float(floatBitsToUint(k.x), floatBitsToUint(k.y));
}

vec3 random_vec3_offset(float seed)
{
    return vec3(100.0 + hash_vec2_to_float(vec2(seed, 0.0)) * 100.0,
        100.0 + hash_vec2_to_float(vec2(seed, 1.0)) * 100.0,
        100.0 + hash_vec2_to_float(vec2(seed, 2.0)) * 100.0);
}



///////////////////////////////////////////////////////////////////////////////////////
/* Matirx Math */

/* Return a 2D rotation matrix with the angle that the input 2D vector makes with the x axis. */
mat2 vector_to_rotation_matrix(vec2 dir)
{
    vec2 normalized_vector = normalize(dir);
    float cos_angle = normalized_vector.x;
    float sin_angle = normalized_vector.y;
    return mat2(cos_angle, sin_angle, -sin_angle, cos_angle);
}

mat3 euler_to_mat3(vec3 euler)
{
    float cx = cos(euler.x);
    float cy = cos(euler.y);
    float cz = cos(euler.z);
    float sx = sin(euler.x);
    float sy = sin(euler.y);
    float sz = sin(euler.z);

    mat3 mat;
    mat[0][0] = cy * cz;
    mat[0][1] = cy * sz;
    mat[0][2] = -sy;

    mat[1][0] = sy * sx * cz - cx * sz;
    mat[1][1] = sy * sx * sz + cx * cz;
    mat[1][2] = cy * sx;

    mat[2][0] = sy * cx * cz + sx * sz;
    mat[2][1] = sy * cx * sz - sx * cz;
    mat[2][2] = cy * cx;
    return mat;
}

void mapping_point(vec3 dir, vec3 location, vec3 rotation, vec3 scale ,out vec3 result)
{
    result =  mul(euler_to_mat3(rotation), (dir * scale)) + location;
}


///////////////////////////////////////////////////////////////////////////////////////

void valtorgb_opti_linear(
    float fac, vec2 mulbias, vec4 color1, vec4 color2, out vec4 outcol, out float outalpha)
{
    fac = clamp(fac * mulbias.x + mulbias.y, 0.0, 1.0);
    outcol = mix(color1, color2, fac);
    outalpha = outcol.a;
}

#endif