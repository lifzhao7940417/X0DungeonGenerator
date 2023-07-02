#ifndef X0SCENEPARAMETER_INCLUDED
#define X0SCENEPARAMETER_INCLUDED

#include "Assets/Res/FolderMode/Shaders/@B3DIncludes/B3DCommon.hlsl"
#include "Assets/Res/FolderMode/Shaders/@B3DIncludes/B3DNoise.hlsl"

#define _WindFrequency 1 //风频率
#define _WindSpeed 1 //风速度
#define _WindPower 1 //风强度

#define  _WindBurstsSpeed 1 //树干抖动 速度
#define  _WindBurstsScale 1 //树干抖动 范围
#define  _WindBurstsPower 1 //树干抖动 幅度
#define _WindMultiplier 0.5f //树干抖动 强度

#define _WindTrunkContrast 2
#define _WindTrunkPosition 1

#define _MicroSpeed 1
#define _MicroPower 1
#define _MicroFrequency 1
#define  _MicroWindMultiplier 0.2f

#define _CloudMappingLoaction 0
#define _CloudMappingRotation 0.65f
#define _CloudNoiseParam float4(5,16,0.5f,0)
#define _CloudMappingScale 0.005f
#define _MainLightDir float4(60,-45,-90,0)

#define _OcclusionPosSlider 0
#define _OcclusionDither 0.45f
#define _OcclusionACutoff 0.25f
float _OcclusionFade;

float4 Unity_Dither_float4(float4 In, float4 ScreenPosition)
{
	float2 coords = ScreenPosition.xy / ScreenPosition.w;
	float2 uv = coords * _ScreenParams.xy;
	float DITHER_THRESHOLDS[16] =
	{
		1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
		13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
		4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
		16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
	};
	uint index = (uint(uv.x) % 4) * 4 + uint(uv.y) % 4;
	return In - DITHER_THRESHOLDS[index];
}

void DitheredCutOff(float localPosy, float4 screenPos)
{
	//  the object position and a slider that moves over the object
	float objectPosSliding = localPosy + _OcclusionPosSlider;
	// the dither effect, adding in the cutoff
	float ditheredCutoff = Unity_Dither_float4(_OcclusionDither, screenPos).r + (1 - (saturate(objectPosSliding)) * _OcclusionFade);
	// discard pixels based on dither
	clip(ditheredCutoff - _OcclusionACutoff);
}

void DitheredCutOffSelf(float localPosy, float4 screenPos,float OcclusionFade,float OcclusionACutoff,float OcclusionDither,float OcclusionPosSlider)
{
	//  the object position and a slider that moves over the object
	float objectPosSliding = localPosy + OcclusionPosSlider;
	// the dither effect, adding in the cutoff
	float ditheredCutoff = Unity_Dither_float4(OcclusionDither, screenPos).r + (1 - (saturate(objectPosSliding)) * OcclusionFade);
	// discard pixels based on dither
	clip(ditheredCutoff - OcclusionACutoff);
}

float3 _MainLightColor;
float4 _SceneColor;

float _WindAllCtrl;

sampler2D _CloudNoiseTex;
sampler2D _ReflectionTex;

float GetNOL(float3 normalWS)
{
	return  dot(normalWS, normalize(_MainLightDir.xyz)) *0.5 + 0.5;
}

float4 GetSceneColor()
{
	return _SceneColor;
}

float GetCloudMask(float3 worldNormal,float3 worldPos)
{
	float3 projNormal = abs(worldNormal);
	projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
	float3 nsign = sign(worldNormal);

	return nsign.y * projNormal.y;
}

float4 mulCloudByMathfNoise(float3 normalWS, float3 posWS)
{
	float3 uvDir = float3(posWS.xz, 1);
	float3 uvMapping;
	float uvSpeed = _Time.y * _WindAllCtrl;
	float4 uvMove = float4(0, uvSpeed * 0.01f, uvSpeed * 0.005f, 0);
	mapping_point(uvDir, _CloudMappingLoaction.rrr + uvMove, float4(0, 0, _CloudMappingRotation, 0), _CloudMappingScale, uvMapping);

	float4 noiseColor; float noiseFac;
	node_noise_texture_3d(uvMapping, _CloudNoiseParam.x, _CloudNoiseParam.y, _CloudNoiseParam.z, _CloudNoiseParam.w, noiseFac, noiseColor);


	float4 colorRamp;  float colorAlpha;
	valtorgb_opti_linear(noiseFac, float2(1 / (0.59f - 0.568f), -0.568f / ((0.59f - 0.568f))), 1, 0, colorRamp, colorAlpha);
	return colorRamp * GetCloudMask(normalWS, posWS);
}

inline float4 mulCloudByNoiseTex(float3 worldNormal, float3 worldPos,float cloudRange)
{
	float3 projNormal = pow(abs(worldNormal),1);
	projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
	float3 nsign = sign(worldNormal);

	float uvSpeed = _Time.y * _WindAllCtrl;
	float2 uvMove = float2(-uvSpeed * 0.01f, uvSpeed * 0.005f);
	half4 yNorm = tex2D(_CloudNoiseTex, (float2(0, 0) + uvMove) + 0.01f * worldPos.xz * float2(nsign.y, 1.0));
	float fac = yNorm * lerp(projNormal.y, 1,cloudRange);
	float4 colorRamp;  float colorAlpha;
	valtorgb_opti_linear(fac, float2(5.23f, -2.40f), 1, 0, colorRamp, colorAlpha);

	return  colorRamp;
}


float4 GetCloud(float3 normalWS, float3 posWS, float cloudRange)
{
	//float4 colorRamp = mulCloudByMathfNoise(normalWS,posWS);
	float4 colorRamp = mulCloudByNoiseTex(normalWS, posWS, cloudRange);
	return colorRamp;
}

float3 mod2D289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

float2 mod2D289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

float3 permute(float3 x) { return mod2D289(((x * 34.0) + 1.0) * x); }

float snoise(float2 v)
{
	const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
	float2 i = floor(v + dot(v, C.yy));
	float2 x0 = v - i + dot(i, C.xx);
	float2 i1;
	i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
	float4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod2D289(i);
	float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
	float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
	m = m * m;
	m = m * m;
	float3 x = 2.0 * frac(p * C.www) - 1.0;
	float3 h = abs(x) - 0.5;
	float3 ox = floor(x + 0.5);
	float3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
	float3 g;
	g.x = a0.x * x0.x + h.x * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}

inline float Dither8x8BayerCopy(int x, int y)
{
	const float dither[64] = {
			1, 49, 13, 61,  4, 52, 16, 64,
		33, 17, 45, 29, 36, 20, 48, 32,
			9, 57,  5, 53, 12, 60,  8, 56,
		41, 25, 37, 21, 44, 28, 40, 24,
			3, 51, 15, 63,  2, 50, 14, 62,
		35, 19, 47, 31, 34, 18, 46, 30,
		11, 59,  7, 55, 10, 58,  6, 54,
		43, 27, 39, 23, 42, 26, 38, 22 };
	int r = y * 8 + x;
	return dither[r] / 64; // same # of instructions as pre-dividing due to compiler magic
}

float4 CalculateContrast(float contrastValue, float4 colorTarget)
{
	float t = 0.5 * (1.0 - contrastValue);
	return mul(float4x4(contrastValue, 0, 0, t, 0, contrastValue, 0, t, 0, 0, contrastValue, t, 0, 0, 0, 1), colorTarget);
}

void ClipDither(float3 posWS, float4 screenPosition, float3 viewWS, float texAlpha,float HidePower,float Cutoff)
{
	float4 screenPosNorm = screenPosition / screenPosition.w;
	screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
	float2 clipScreenUV = screenPosNorm.xy * _ScreenParams.xy;
	float dither = Dither8x8BayerCopy(fmod(clipScreenUV.x, 8), fmod(clipScreenUV.y, 8));

	float3 ddsPosWS = normalize(cross(ddy(posWS), ddx(posWS)));
	float vnp = dot(viewWS, ddsPosWS);
	float ditherClip = clamp(((texAlpha * (1.0 - ((1.0 - abs(vnp)) * 2.0))) * HidePower), 0.0, 1.0);

	dither = step(dither, ditherClip);

#ifdef _HIDESIDES_ON
	float finallDither = dither;
#else
	float finallDither = texAlpha;
#endif

	clip(finallDither - Cutoff);
}


float3 AddWind(float3 posWS, float2 texcoord, float4 color)
{
	float3 posWSZYX = float3(posWS.z, posWS.y, posWS.x);
	float2 SpeedZY = 1.0 * _Time.y * _WindAllCtrl /*_WindSpeed*/ + float2(posWS.z, posWS.y);
	float SpeedZYPerlinNoise = snoise(SpeedZY) * 0.5 + 0.5;
	float3 MicroWind = float3(sin(_WindAllCtrl/*_WindFrequency*/ * (posWSZYX + SpeedZYPerlinNoise.xxx)) * texcoord.y * _WindAllCtrl/*_WindPower*/ * color.r) * float3(12, 3.6, 1) * 0.01;

	return MicroWind;
}

float4 GetBaseWind(float3 posWS, float vertexColorweightChannelR)
{
	float windTime = (_Time.y * _WindAllCtrl/*_WindSpeed*/);
	float2 windBurst = (float2(_WindBurstsSpeed, _WindBurstsSpeed));
	float2 uv = (float2(posWS.x, posWS.z));
	float2 winduvWithTime = (1.0 * _Time.y * windBurst + uv);
	float noiseWind = snoise(winduvWithTime * (_WindBurstsScale / 10.0));
	noiseWind = noiseWind * 0.5 + 0.5;
	float noiseWindFinall = (_WindAllCtrl/*_WindPower*/ * (noiseWind * _WindBurstsPower));
	float4 weight = (pow((1.0 - vertexColorweightChannelR), _WindTrunkPosition)).xxxx;
	float4 windTrunkContrast = saturate(CalculateContrast(_WindTrunkContrast, weight));
	float3 windCircle = (float3(((sin(windTime) * noiseWindFinall) * windTrunkContrast).r, 0.0, ((cos(windTime) * (noiseWindFinall * 0.5)) * windTrunkContrast).r));
	float4 BaseWind = mul(unity_WorldToObject, float4(windCircle, 0.0)) * _WindMultiplier;
	return BaseWind;
}

float4 AddWindTree(float3 posWS, float3 vertexnormal, float vertexColorweightChannelR, float vertexColorweightChannel)
{
	float4 BaseWind = GetBaseWind(posWS,vertexColorweightChannelR);

	float3 appendPosWS = (float3(posWS.x, posWS.z, posWS.y));
	float2 pannerWeight = (1.0 * _Time.y * float2(_WindAllCtrl, _WindAllCtrl) + appendPosWS.xy);
	float noiseWeight = snoise((pannerWeight * 1.0));
	noiseWeight = noiseWeight * 0.5 + 0.5;

	float3 posNoise = clamp(sin((max(_MicroFrequency, _WindAllCtrl/*_WindFrequency*/) * (posWS + noiseWeight))), float3(-1, -1, -1), float3(1, 1, 1));
	float3 normalVS = vertexnormal.xyz;

	float3 MicroWind = ((((posNoise * normalVS) * _MicroPower) * vertexColorweightChannel) * _MicroWindMultiplier);
	float4 WindValue = (BaseWind + float4(MicroWind, 0.0));
	return WindValue;
}

//////Shake////////////////////////////////////////////////////////////////////////////////////////////////

float4 _ShakePosWS, _ShakeParams, _ShakeDirWS; float _ShakeDur;

float4 GetShakeVertex(float4 inVertexOS)
{
	float4 shakeCenterOS = mul(unity_WorldToObject, _ShakePosWS);
	float range = _ShakeParams.x;
	float intensity = _ShakeParams.y;
	float weight = 1 - clamp(length(inVertexOS - shakeCenterOS) / range, 0, 1);
	float3 shakeDirOS = mul(unity_WorldToObject, _ShakeDirWS);

	float4 shakePosOS = float4(lerp(inVertexOS.xyz, inVertexOS.xyz + intensity * shakeDirOS, weight * _ShakeDur).xyz, inVertexOS.w);

	return shakePosOS;
}

#endif // X0SCENEPARAMETER_INCLUDED