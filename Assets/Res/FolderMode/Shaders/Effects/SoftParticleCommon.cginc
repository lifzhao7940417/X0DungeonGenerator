#ifndef __SOFT_PARTICLE_COMMON_H__
#define __SOFT_PARTICLE_COMMON_H__

// jave.lin 2021/02/28

#include "UnityCG.cginc"

#if defined(_SOFT_PARTICLE_ON)

#if defined(_SOFT_PARTICLE_DEPTH_MAP_DEF_ON)
sampler2D _CameraDepthTexture;
#endif

// https://github.com/TwoTailsGames/Unity-Built-in-Shaders/blob/master/DefaultResourcesExtra/Particle%20AddMultiply.shader
half _InvFade; // _InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0

#define SOFT_PARTICLE_V2F(idx) float4 projPos : TEXCOORD##idx;

#define SOFT_PARTICLE_VERT(o) \
o.projPos = ComputeScreenPos(o.vertex); \
COMPUTE_EYEDEPTH(o.projPos.z);

#define COMPUTE_EYEDEPTH1(o, objVertex) o = -UnityObjectToViewPos( objVertex ).z

#define SOFT_PARTICLE_VERT1(o, vertex) \
o.projPos = ComputeScreenPos(vertex); \
COMPUTE_EYEDEPTH(o.projPos.z);

#define SOFT_PARTICLE_VERT2(o, vertex, objVertex) \
o.projPos = ComputeScreenPos(vertex); \
COMPUTE_EYEDEPTH1(o.projPos.z, objVertex);

#define SOFT_PARTICLE_FRAG_FADE(i, out_v) \
fixed offSP = step(10.0, _InvFade); \
out_v = saturate(_InvFade * (LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))) - i.projPos.z)); \
out_v = lerp(out_v, 1.0, offSP);

#else

#define SOFT_PARTICLE_V2F(idx) 
#define SOFT_PARTICLE_VERT(o)
#define SOFT_PARTICLE_VERT1(o, vertex)
#define SOFT_PARTICLE_FRAG_FADE(i, out_v)  out_v = 1.0;

#endif

#endif

