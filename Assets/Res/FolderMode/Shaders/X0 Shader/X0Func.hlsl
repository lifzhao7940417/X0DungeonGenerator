#ifndef X0FUNC_INCLUDED
#define X0FUNC_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
#include "UnityCG.cginc"

UNITY_DECLARE_TEX2D(_MainTex); half4 _MainTex_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap); half4 _BumpMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormalMap); half4 _DetailNormalMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMask); half4 _DetailMask_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecularMap); half4 _SpecularMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicGlossMap); half4 _MetallicGlossMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_ReflectivityMask); half4 _ReflectivityMask_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_ThicknessMap); half4 _ThicknessMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap); half4 _EmissionMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_RampSelectionMask);
UNITY_DECLARE_TEX2D_NOSAMPLER(_CutoutMask); half4 _CutoutMask_ST;
sampler2D _OcclusionMap; half4 _OcclusionMap_ST;
sampler2D _OutlineMask;
sampler2D _Matcap;
sampler2D _Ramp;
samplerCUBE _BakedCubemap;

half4 _Color, _ShadowRim,
_OutlineColor, _SSColor, _OcclusionColor,
_EmissionColor, _MatcapTint, _RimColor;

half _MatcapTintToDiffuse;
half _Cutoff;
half _FadeDitherDistance;
half _EmissionToDiffuse, _ScaleWithLightSensitivity;
half _Saturation;
half _Metallic, _Glossiness, _Reflectivity, _ClearcoatStrength, _ClearcoatSmoothness;
half _BumpScale, _DetailNormalMapScale;
half _SpecularIntensity, _SpecularArea, _AnisotropicAX, _AnisotropicAY, _SpecularAlbedoTint;

half _RimRange, _RimThreshold, _RimIntensity, _RimSharpness, _RimAlbedoTint, _RimCubemapTint, _RimAttenEffect;
half _ShadowRimRange, _ShadowRimThreshold, _ShadowRimSharpness, _ShadowSharpness, _ShadowRimAlbedoTint;

half _SSDistortion, _SSPower, _SSScale;
half _OutlineWidth;

int _HalftoneType;
int _FadeDither;
int _SpecMode, _SpecularStyle, _ReflectionMode, _ReflectionBlendMode, _ClearCoat;
int _TilingMode, _VertexColorAlbedo, _ScaleWithLight;
int _OutlineAlbedoTint, _OutlineLighting;
int _UVSetAlbedo, _UVSetNormal, _UVSetDetNormal,
_UVSetDetMask, _UVSetMetallic, _UVSetSpecular,
_UVSetThickness, _UVSetOcclusion, _UVSetReflectivity,
_UVSetEmission;

half _HalftoneDotSize, _HalftoneDotAmount, _HalftoneLineAmount, _HalftoneLineIntensity;



float _ToonEffect;
float _Step;




struct ToonSSSVertexInput
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
};

struct ToonSSSVertexOutput
{
#if defined(Geometry)
	float4 pos : CLIP_POS;
	float4 vertex : SV_POSITION; // We need both of these in order to shadow Outlines correctly
#else
	float4 pos : SV_POSITION;
#endif

	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float3 ntb[3] : TEXCOORD2; //texcoord 3, 4 || Holds World Normal, Tangent, and Bitangent
	float4 worldPos : TEXCOORD5;
	float4 color : TEXCOORD6;
	float3 normal : TEXCOORD8;
	float4 screenPos : TEXCOORD9;
	float3 objPos : TEXCOORD11;

	//float distanceToOrigin : TEXCOORD10;
	SHADOW_COORDS(7)
	UNITY_FOG_COORDS(10)
};


struct TextureUV
{
	half2 uv0;
	half2 uv1;
	half2 albedoUV;
	half2 specularMapUV;
	half2 metallicGlossMapUV;
	half2 detailMaskUV;
	half2 normalMapUV;
	half2 detailNormalUV;
	half2 thicknessMapUV;
	half2 occlusionUV;
	half2 reflectivityMaskUV;
	half2 emissionMapUV;
	half2 outlineMaskUV;
};

struct XSLighting
{
	half4 albedo;
	half4 normalMap;
	half4 detailNormal;
	half4 detailMask;
	half4 metallicGlossMap;
	half4 reflectivityMask;
	half4 specularMap;
	half4 thickness;
	half4 occlusion;
	half4 emissionMap;
	half4 rampMask;
#if defined(AlphaToMask) && defined(Masked) || defined(Dithered)
	half4 cutoutMask;
#endif

	half3 diffuseColor;
	half attenuation;
	half3 normal;
	half3 tangent;
	half3 bitangent;
	half4 worldPos;
	half3 color;
	half alpha;
	float isOutline;
	float2 screenUV;
	float3 objPos;
};

struct DotProducts
{
	half ndl;
	half vdn;
	half vdh;
	half tdh;
	half bdh;
	half ndh;
	half rdv;
	half ldh;
	half svdn;
};







// From HDRenderPipeline
half D_GGXAnisotropic(half TdotH, half BdotH, half NdotH, half roughnessT, half roughnessB)
{
	half f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
	half aniso = 1.0 / (roughnessT * roughnessB * f * f);
	return aniso;
}

half3 XSFresnelTerm(half3 F0, half cosA)
{
	half t = Pow5(1 - cosA);   // ala Schlick interpoliation
	return F0 + (1 - F0) * t;
}

half3 XSFresnelLerp(half3 F0, half3 F90, half cosA)
{
	half t = Pow5(1 - cosA);   // ala Schlick interpoliation
	return lerp(F0, F90, t);
}

half XSGGXTerm(half NdotH, half roughness)
{
	half a2 = roughness * roughness;
	half d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
	return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
											// therefore epsilon is smaller than what can be represented by half
}

half3 F_Schlick(half3 SpecularColor, half VoH)
{
	return SpecularColor + (1.0 - SpecularColor) * exp2((-5.55473 * VoH) - (6.98316 * VoH));
}








void calcNormal(inout XSLighting i)
{
	half3 nMap = UnpackScaleNormal(i.normalMap, _BumpScale);
	half3 detNMap = UnpackScaleNormal(i.detailNormal, _DetailNormalMapScale);

	half3 blendedNormal = lerp(nMap, BlendNormals(nMap, detNMap), i.detailMask.r);

	half3 tspace0 = half3(i.tangent.x, i.bitangent.x, i.normal.x);
	half3 tspace1 = half3(i.tangent.y, i.bitangent.y, i.normal.y);
	half3 tspace2 = half3(i.tangent.z, i.bitangent.z, i.normal.z);

	half3 calcedNormal;
	calcedNormal.x = dot(tspace0, blendedNormal);
	calcedNormal.y = dot(tspace1, blendedNormal);
	calcedNormal.z = dot(tspace2, blendedNormal);

	calcedNormal = normalize(calcedNormal);
	half3 bumpedTangent = (cross(i.bitangent, calcedNormal));
	half3 bumpedBitangent = (cross(calcedNormal, bumpedTangent));

	i.normal = calcedNormal;
	i.tangent = bumpedTangent;
	i.bitangent = bumpedBitangent;
}

void calcLightCol(bool lightEnv, inout half3 indirectDiffuse, inout half4 lightColor)
{
	//If we're in an environment with a realtime light, then we should use the light color, and indirect color raw.
	//...
	if (lightEnv)
	{
		lightColor = _LightColor0;
		indirectDiffuse = indirectDiffuse;
	}
	else
	{
		lightColor = indirectDiffuse.xyzz * 0.6;    // ...Otherwise
		indirectDiffuse = indirectDiffuse * 0.4;    // Keep overall light to 100% - these should never go over 100%
													// ex. If we have indirect 100% as the light color and Indirect 50% as the indirect color, 
													// we end up with 150% of the light from the scene.
	}
}

void InitializeTextureUVs
(
#if defined(Geometry)
	in g2f i,
#else
	in ToonSSSVertexOutput i,
#endif
	inout TextureUV t
)
{

#if defined(PatreonEyeTracking)
	float2 eyeUvOffset = eyeOffsets(i.uv, i.objPos, i.worldPos, i.ntb[0]);
	i.uv = eyeUvOffset;
	i.uv1 = eyeUvOffset;
#endif

	half2 uvSetNormalMap = (_UVSetNormal == 0) ? i.uv : i.uv1;
	t.normalMapUV = TRANSFORM_TEX(uvSetNormalMap, _BumpMap);

	half2 uvSetEmissionMap = (_UVSetEmission == 0) ? i.uv : i.uv1;
	t.emissionMapUV = TRANSFORM_TEX(uvSetEmissionMap, _EmissionMap);

	half2 uvSetMetallicGlossMap = (_UVSetMetallic == 0) ? i.uv : i.uv1;
	t.metallicGlossMapUV = TRANSFORM_TEX(uvSetMetallicGlossMap, _MetallicGlossMap);

	half2 uvSetOcclusion = (_UVSetOcclusion == 0) ? i.uv : i.uv1;
	t.occlusionUV = TRANSFORM_TEX(uvSetOcclusion, _OcclusionMap);

	half2 uvSetDetailNormal = (_UVSetDetNormal == 0) ? i.uv : i.uv1;
	t.detailNormalUV = TRANSFORM_TEX(uvSetDetailNormal, _DetailNormalMap);

	half2 uvSetDetailMask = (_UVSetDetMask == 0) ? i.uv : i.uv1;
	t.detailMaskUV = TRANSFORM_TEX(uvSetDetailMask, _DetailMask);

	half2 uvSetAlbedo = (_UVSetAlbedo == 0) ? i.uv : i.uv1;
	t.albedoUV = TRANSFORM_TEX(uvSetAlbedo, _MainTex);

	half2 uvSetSpecularMap = (_UVSetSpecular == 0) ? i.uv : i.uv1;
	t.specularMapUV = TRANSFORM_TEX(uvSetSpecularMap, _SpecularMap);

	half2 uvSetThickness = (_UVSetThickness == 0) ? i.uv : i.uv1;
	t.thicknessMapUV = TRANSFORM_TEX(uvSetThickness, _ThicknessMap);

	half2 uvSetReflectivityMask = (_UVSetReflectivity == 0) ? i.uv : i.uv1;
	t.reflectivityMaskUV = TRANSFORM_TEX(uvSetReflectivityMask, _ReflectivityMask);
}

void InitializeTextureUVsMerged
(
#if defined(Geometry)
	in g2f i,
#else
	in ToonSSSVertexOutput i,
#endif
	inout TextureUV t
)
{
	half2 uvSetAlbedo = (_UVSetAlbedo == 0) ? i.uv : i.uv1;
	t.albedoUV = TRANSFORM_TEX(uvSetAlbedo, _MainTex);
	t.normalMapUV = t.albedoUV;
	t.emissionMapUV = t.albedoUV;
	t.metallicGlossMapUV = t.albedoUV;
	t.occlusionUV = t.albedoUV;
	t.detailNormalUV = t.albedoUV;
	t.detailMaskUV = t.albedoUV;
	t.specularMapUV = t.albedoUV;
	t.thicknessMapUV = t.albedoUV;
	t.reflectivityMaskUV = t.albedoUV;
}

bool IsInMirror()
{
	return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

half2 matcapSample(half3 worldUp, half3 viewDirection, half3 normalDirection)
{
	half3 worldViewUp = normalize(worldUp - viewDirection * dot(viewDirection, worldUp));
	half3 worldViewRight = normalize(cross(viewDirection, worldViewUp));
	half2 matcapUV = half2(dot(worldViewRight, normalDirection), dot(worldViewUp, normalDirection)) * 0.5 + 0.5;
	return matcapUV;
}

float2 SphereUV(float3 coords /*viewDir?*/)
{
	float3 nc = normalize(coords);
	float lat = acos(nc.y);
	float lon = atan2(nc.z, nc.x);
	float2 coord = 1.0 - (float2(lon, lat) * float2(1.0 / UNITY_PI, 1.0 / UNITY_PI));
	return (coord + float4(0, 1 - unity_StereoEyeIndex, 1, 1.0).xy) * float4(0, 1 - unity_StereoEyeIndex, 1, 1.0).zw;
}

half2 rotateUV(half2 uv, half rotation)
{
	half mid = 0.5;
	return half2(
		cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
		cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
		);
}

half2 calcScreenUVs(half4 screenPos)
{
	half2 uv = screenPos / (screenPos.w + 0.0000000001); //0.0x1 Stops division by 0 warning in console.
#if UNITY_SINGLE_PASS_STEREO
	uv.xy *= half2(_ScreenParams.x * 2, _ScreenParams.y);
#else
	uv.xy *= _ScreenParams.xy;
#endif

	return uv;
}

half3 calcIndirectDiffuse(XSLighting i)
{// We don't care about anything other than the color from probes for toon lighting.
	half3 indirectDiffuse = ShadeSH9(float4(0, 0.5, 0, 1));//half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
	return indirectDiffuse;
}

half3 calcLightDir(XSLighting i, half4 vertexLightAtten)
{
	half3 lightDir = UnityWorldSpaceLightDir(i.worldPos);

	half3 probeLightDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
	lightDir = (lightDir + probeLightDir); //Make light dir the average of the probe direction and the light source direction.

//#if defined(VERTEXLIGHT_ON)
//	half3 vertexDir = getVertexLightsDir(i, vertexLightAtten);
//	lightDir = (lightDir + probeLightDir + vertexDir);
//#endif

#if !defined(POINT) && !defined(SPOT) && !defined(VERTEXLIGHT_ON) // if the average length of the light probes is null, and we don't have a directional light in the scene, fall back to our fallback lightDir
	if (length(unity_SHAr.xyz*unity_SHAr.w + unity_SHAg.xyz*unity_SHAg.w + unity_SHAb.xyz*unity_SHAb.w) == 0 && length(lightDir) < 0.1)
	{
		lightDir = half4(1, 1, 1, 0);
	}
#endif

	return normalize(lightDir);
}

half3 calcViewDir(half3 worldPos)
{
	half3 viewDir = _WorldSpaceCameraPos - worldPos;
	return normalize(viewDir);
}

half3 calcStereoViewDir(half3 worldPos)
{
#if UNITY_SINGLE_PASS_STEREO
	half3 cameraPos = half3((unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1])*.5);
#else
	half3 cameraPos = _WorldSpaceCameraPos;
#endif
	half3 viewDir = cameraPos - worldPos;
	return normalize(viewDir);
}

half3 calcReflView(half3 viewDir, half3 normal)
{
	return reflect(-viewDir, normal);
}

half3 calcReflLight(half3 lightDir, half3 normal)
{
	return reflect(lightDir, normal);
}

half4 calcMetallicSmoothness(XSLighting i)
{
	half roughness = 1 - (_Glossiness * i.metallicGlossMap.a);
	roughness *= 1.7 - 0.7 * roughness;
	half metallic = lerp(0, i.metallicGlossMap.r * _Metallic, i.reflectivityMask.r);
	return half4(metallic, 0, 0, roughness);
}

half3 getReflectionUV(half3 direction, half3 position, half4 cubemapPosition, half3 boxMin, half3 boxMax)
{
#if UNITY_SPECCUBE_BOX_PROJECTION
	if (cubemapPosition.w > 0) {
		half3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
		half scalar = min(min(factors.x, factors.y), factors.z);
		direction = direction * scalar + (position - cubemapPosition);
	}
#endif
	return direction;
}

half3 getEnvMap(XSLighting i, DotProducts d, float blur, half3 reflDir, half3 indirectLight, half3 wnormal)
{//This function handls Unity style reflections, Matcaps, and a baked in fallback cubemap.
	half3 envMap = half3(0, 0, 0);

#if defined(UNITY_PASS_FORWARDBASE) //Indirect PBR specular should only happen in the forward base pass. Otherwise each extra light adds another indirect sample, which could mean you're getting too much light. 
	half3 reflectionUV1 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
	half4 probe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionUV1, blur);
	half3 probe0sample = DecodeHDR(probe0, unity_SpecCube0_HDR);

	half3 indirectSpecular;
	half interpolator = unity_SpecCube0_BoxMin.w;

	UNITY_BRANCH
		if (interpolator < 0.99999)
		{
			half3 reflectionUV2 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
			half4 probe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, reflectionUV2, blur);
			half3 probe1sample = DecodeHDR(probe1, unity_SpecCube1_HDR);
			indirectSpecular = lerp(probe1sample, probe0sample, interpolator);
		}
		else
		{
			indirectSpecular = probe0sample;
		}

	envMap = indirectSpecular;
#endif

	return envMap;
}

half4 calcRamp(XSLighting i, DotProducts d)
{
	half remapRamp;
	remapRamp = (d.ndl * 0.5 + 0.5);

#if defined(UNITY_PASS_FORWARDBASE)
	remapRamp *= i.attenuation;
#endif

	half4 ramp = tex2D(_Ramp, half2(remapRamp, i.rampMask.r));

	return ramp;
}

half4 calcDiffuse(XSLighting i, DotProducts d, half3 indirectDiffuse, half4 lightCol, half4 ramp)
{
	half4 diffuse;
	half4 indirect = indirectDiffuse.xyzz;
	diffuse = ramp * i.attenuation * lightCol + indirect;
	diffuse = i.albedo * diffuse;
	return diffuse;
}

half4 calcRimLight(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse, half3 envMap)
{
	half rimIntensity = saturate((1 - d.svdn)) * pow(d.ndl, _RimThreshold);
	rimIntensity = smoothstep(_RimRange - _RimSharpness, _RimRange + _RimSharpness, rimIntensity);
	half4 rim = rimIntensity * _RimIntensity * (lightCol + indirectDiffuse.xyzz);
	rim *= lerp(1, i.attenuation + indirectDiffuse.xyzz, _RimAttenEffect);
	return rim * _RimColor * lerp(1, i.diffuseColor.rgbb, _RimAlbedoTint) * lerp(1, envMap.rgbb, _RimCubemapTint);
}

half4 calcShadowRim(XSLighting i, DotProducts d, half3 indirectDiffuse)
{
	half rimIntensity = saturate((1 - d.svdn)) * pow(1 - d.ndl, _ShadowRimThreshold * 2);
	rimIntensity = smoothstep(_ShadowRimRange - _ShadowRimSharpness, _ShadowRimRange + _ShadowRimSharpness, rimIntensity);
	half4 shadowRim = lerp(1, (_ShadowRim * lerp(1, i.diffuseColor.rgbb, _ShadowRimAlbedoTint)) + (indirectDiffuse.xyzz * 0.1), rimIntensity);

	return shadowRim;
}

half3 calcDirectSpecular(XSLighting i, DotProducts d, half4 lightCol, half3 indirectDiffuse, half4 metallicSmoothness, half ax, half ay)
{
	half specularIntensity = _SpecularIntensity * i.specularMap.r;
	half3 specular = half3(0, 0, 0);
	half smoothness = max(0.01, (_SpecularArea * i.specularMap.b));
	smoothness *= 1.7 - 0.7 * smoothness;

	if (_SpecMode == 0)
	{
		half reflectionUntouched = saturate(pow(d.rdv, smoothness * 128));
		specular = lerp(reflectionUntouched, round(reflectionUntouched), _SpecularStyle) * specularIntensity * (_SpecularArea + 0.5);
	}
	else if (_SpecMode == 1)
	{
		half smooth = saturate(D_GGXAnisotropic(d.tdh, d.bdh, d.ndh, ax, ay));
		half sharp = round(smooth) * 2 * 0.5;
		specular = lerp(smooth, sharp, _SpecularStyle) * specularIntensity;
	}
	else if (_SpecMode == 2)
	{
		half sndl = saturate(d.ndl);
		half roughness = 1 - smoothness;
		half V = SmithJointGGXVisibilityTerm(sndl, d.vdn, roughness);
		half F = F_Schlick(half3(0.0, 0.0, 0.0), d.ldh);
		half D = XSGGXTerm(d.ndh, roughness*roughness);

		half reflection = V * D * UNITY_PI;
		half smooth = (max(0, reflection * sndl) * F * i.attenuation) * specularIntensity;
		half sharp = round(smooth);
		specular = lerp(smooth, sharp, _SpecularStyle);
	}
	specular *= i.attenuation * lightCol;
	half3 tintedAlbedoSpecular = specular * i.diffuseColor;
	specular = lerp(specular, tintedAlbedoSpecular, _SpecularAlbedoTint * i.specularMap.g); // Should specular highlight be tinted based on the albedo of the object?
	return specular;
}

half3 calcIndirectSpecular(XSLighting i, DotProducts d, half4 metallicSmoothness, half3 reflDir, half3 indirectLight, half3 viewDir, half4 ramp)
{//This function handls Unity style reflections, Matcaps, and a baked in fallback cubemap.
	half3 spec = half3(0, 0, 0);

	UNITY_BRANCH
		if (_ReflectionMode == 0) // PBR
		{
#if defined(UNITY_PASS_FORWARDBASE) //Indirect PBR specular should only happen in the forward base pass. Otherwise each extra light adds another indirect sample, which could mean you're getting too much light. 
			half3 reflectionUV1 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
			half4 probe0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionUV1, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS);
			half3 probe0sample = DecodeHDR(probe0, unity_SpecCube0_HDR);

			half3 indirectSpecular;
			half interpolator = unity_SpecCube0_BoxMin.w;

			UNITY_BRANCH
				if (interpolator < 0.99999)
				{
					half3 reflectionUV2 = getReflectionUV(reflDir, i.worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
					half4 probe1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, reflectionUV2, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS);
					half3 probe1sample = DecodeHDR(probe1, unity_SpecCube1_HDR);
					indirectSpecular = lerp(probe1sample, probe0sample, interpolator);
				}
				else
				{
					indirectSpecular = probe0sample;
				}

			if (!any(indirectSpecular))
			{
				indirectSpecular = texCUBElod(_BakedCubemap, half4(reflDir, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS));
				indirectSpecular *= indirectLight;
			}

			half3 metallicColor = indirectSpecular * lerp(0.05, i.diffuseColor.rgb, metallicSmoothness.x);
			spec = lerp(indirectSpecular, metallicColor, pow(d.vdn, 0.05));
#endif
		}
		else if (_ReflectionMode == 1) //Baked Cubemap
		{
			half3 indirectSpecular = texCUBElod(_BakedCubemap, half4(reflDir, metallicSmoothness.w * UNITY_SPECCUBE_LOD_STEPS));;
			half3 metallicColor = indirectSpecular * lerp(0.1, i.diffuseColor.rgb, metallicSmoothness.x);
			spec = lerp(indirectSpecular, metallicColor, pow(d.vdn, 0.05));

			if (_ReflectionBlendMode != 1)
			{
				spec *= (indirectLight + (_LightColor0 * i.attenuation) * 0.5);
			}
		}
		else if (_ReflectionMode == 2) //Matcap
		{
			half3 upVector = half3(0, 1, 0);
			half2 remapUV = matcapSample(upVector, viewDir, i.normal);
			spec = tex2Dlod(_Matcap, half4(remapUV, 0, ((1 - metallicSmoothness.w) * UNITY_SPECCUBE_LOD_STEPS))) * _MatcapTint;

			if (_ReflectionBlendMode != 1)
			{
				spec *= (indirectLight + (_LightColor0 * i.attenuation) * 0.5);
			}

			spec *= lerp(1, i.diffuseColor, _MatcapTintToDiffuse);
		}
	spec = lerp(spec, spec * ramp, metallicSmoothness.w); // should only not see shadows on a perfect mirror.
	return spec;
}

half4 calcSubsurfaceScattering(XSLighting i, DotProducts d, half3 lightDir, half3 viewDir, half3 normal, half4 lightCol, half3 indirectDiffuse)
{
	UNITY_BRANCH
		if (any(_SSColor.rgb)) // Skip all the SSS stuff if the color is 0.
		{
			//d.ndl = smoothstep(_SSSRange - _SSSSharpness, _SSSRange + _SSSSharpness, d.ndl);
			half attenuation = saturate(i.attenuation * (d.ndl * 0.5 + 0.5));
			half3 H = normalize(lightDir + normal * _SSDistortion);
			half VdotH = pow(saturate(dot(viewDir, -H)), _SSPower);
			half3 I = _SSColor * (VdotH + indirectDiffuse) * attenuation * i.thickness * _SSScale;
			half4 SSS = half4(lightCol.rgb * I * i.albedo.rgb, 1);
			SSS = max(0, SSS); // Make sure it doesn't go NaN

			return SSS;
		}
		else
		{
			return 0;
		}
}

half4 calcOutlineColor(XSLighting i, DotProducts d, half3 indirectDiffuse, half4 lightCol)
{
	half3 outlineColor = half3(0, 0, 0);
#if defined(Geometry)
	half3 ol = lerp(_OutlineColor, _OutlineColor * i.diffuseColor, _OutlineAlbedoTint);
	outlineColor = ol * saturate(i.attenuation * d.ndl) * lightCol.rgb;
	outlineColor += indirectDiffuse * ol;
	outlineColor = lerp(outlineColor, ol, _OutlineLighting);
#endif
	return half4(outlineColor, 1);
}

half calHalftone(XSLighting i, half scalar) //Scalar can be anything from attenuation to a dot product
{
	bool inMirror = IsInMirror();
	half2 uv = SphereUV(calcViewDir(i.worldPos));
	uv.xy *= _HalftoneDotAmount;
	half2 nearest = 2 * frac(100 * uv) - 1;
	half dist = length(nearest);
	half dotSize = 100 * _HalftoneDotSize * scalar;
	half dotMask = step(dotSize, dist);

	return lerp(1, 1 - dotMask, smoothstep(0, 0.4, 1 / distance(i.worldPos, _WorldSpaceCameraPos)));;
}

void calcAlpha(inout XSLighting i)
{
	//Default to 1 alpha || Opaque
	i.alpha = 1;

#if defined(AlphaBlend)
	i.alpha = i.albedo.a;
#endif

#if defined(Transparent)
	i.alpha = i.albedo.a;
#endif

#if defined(AlphaToMask) && !defined(Masked)// mix of dithering and alpha blend to provide best results.
	half dither = calcDither(i.screenUV.xy);
	i.alpha = i.albedo.a - (dither * (1 - i.albedo.a) * 0.15);
#endif

#if defined(AlphaToMask) && defined(Masked)
	i.alpha = saturate(i.cutoutMask.r + _Cutoff);
	i.alpha = lerp(1 - i.alpha, i.alpha, i.albedo.a);
#endif

#if defined(Dithered)
	half dither = calcDither(i.screenUV.xy);
	if (_FadeDither)
	{
		float d = distance(_WorldSpaceCameraPos, i.worldPos);
		d = smoothstep(_FadeDitherDistance, _FadeDitherDistance + 0.02, d);
		clip(((1 - i.cutoutMask.r) + d) - dither);
		clip(i.albedo.a - dither);
	}
	else
	{
		clip(i.albedo.a - dither);
	}
#endif

#if defined(Cutout)
	clip(i.albedo.a - _Cutoff);
#endif


}

void calcReflectionBlending(XSLighting i, inout half4 col, half3 indirectSpecular)
{
	if (_ReflectionBlendMode == 0) // Additive
		col += indirectSpecular.xyzz * i.reflectivityMask.r;
	else if (_ReflectionBlendMode == 1) //Multiplicitive
		col = lerp(col, col * indirectSpecular.xyzz, i.reflectivityMask.r);
	else if (_ReflectionBlendMode == 2) //Subtractive
		col -= indirectSpecular.xyzz * i.reflectivityMask.r;
}

void calcClearcoat(inout half4 col, XSLighting i, DotProducts d, half3 untouchedNormal, half3 indirectDiffuse, half3 lightCol, half3 viewDir, half3 lightDir, half4 ramp)
{
	UNITY_BRANCH
		if (_ClearCoat != 0)
		{
			untouchedNormal = normalize(untouchedNormal);
			half clearcoatSmoothness = _ClearcoatSmoothness * i.metallicGlossMap.g;
			half clearcoatStrength = _ClearcoatStrength * i.metallicGlossMap.b;

			half3 reflView = calcReflView(viewDir, untouchedNormal);
			half3 reflLight = calcReflLight(lightDir, untouchedNormal);
			half rdv = saturate(dot(reflLight, half4(-viewDir, 0)));
			half3 clearcoatIndirect = calcIndirectSpecular(i, d, half4(0, 0, 0, 1 - clearcoatSmoothness), reflView, indirectDiffuse, viewDir, ramp);
			half3 clearcoatDirect = saturate(pow(rdv, clearcoatSmoothness * 256)) * i.attenuation * lightCol;

			half3 clearcoat = (clearcoatIndirect + clearcoatDirect) * clearcoatStrength;
			clearcoat = lerp(clearcoat * 0.5, clearcoat, saturate(pow(1 - dot(viewDir, untouchedNormal), 0.8)));
			col += clearcoat.xyzz;
		}
}

half4 calcEmission(XSLighting i, half lightAvg)
{
#if defined(UNITY_PASS_FORWARDBASE) // Emission only in Base Pass, and vertex lights
	half4 emission = lerp(i.emissionMap, i.emissionMap * i.diffuseColor.xyzz, _EmissionToDiffuse);
	half4 scaledEmission = emission * saturate(smoothstep(1 - _ScaleWithLightSensitivity, 1 + _ScaleWithLightSensitivity, 1 - lightAvg));

	return lerp(scaledEmission, emission, _ScaleWithLight);
#else 
	return 0;
#endif
}

half LineHalftone(XSLighting i, half scalar)
{
	// #if defined(DIRECTIONAL)
	// 	scalar = saturate(scalar + ((1-i.attenuation) * 0.2));
	// #endif
	bool inMirror = IsInMirror();
	half2 uv = SphereUV(calcViewDir(i.worldPos));
	uv = rotateUV(uv, -0.785398);
	uv.x = sin(uv.x * _HalftoneLineAmount * scalar);

	half2 steppedUV = smoothstep(0, 0.2, uv.x);
	half lineMask = lerp(1, steppedUV, smoothstep(0, 0.4, 1 / distance(i.worldPos, _WorldSpaceCameraPos)));

	return saturate(lineMask);
}

#define grayscaleVec float3(0.2125, 0.7154, 0.0721)


half4 BRDF_XSLighting(XSLighting i)
{
	float3 untouchedNormal = i.normal;
	calcNormal(i);

	half4 vertexLightAtten = half4(0, 0, 0, 0);
//#if defined(VERTEXLIGHT_ON)
//	half3 indirectDiffuse = calcIndirectDiffuse(i) + get4VertexLightsColFalloff(i.worldPos, i.normal, vertexLightAtten);
//#else
//	half3 indirectDiffuse = calcIndirectDiffuse(i);
//#endif

	half3 indirectDiffuse = calcIndirectDiffuse(i);

	bool lightEnv = any(_WorldSpaceLightPos0.xyz);
	half3 lightDir = calcLightDir(i, vertexLightAtten);
	half3 viewDir = calcViewDir(i.worldPos);
	half3 stereoViewDir = calcStereoViewDir(i.worldPos);
	half4 metallicSmoothness = calcMetallicSmoothness(i);
	half3 halfVector = normalize(lightDir + viewDir);
	half3 reflView = calcReflView(viewDir, i.normal);
	half3 reflLight = calcReflLight(lightDir, i.normal);

	DotProducts d = (DotProducts)0;
	d.ndl = dot(i.normal, lightDir);
	d.vdn = abs(dot(viewDir, i.normal));
	d.vdh = DotClamped(viewDir, halfVector);
	d.tdh = dot(i.tangent, halfVector);
	d.bdh = dot(i.bitangent, halfVector);
	d.ndh = DotClamped(i.normal, halfVector);
	d.rdv = saturate(dot(reflLight, float4(-viewDir, 0)));
	d.ldh = DotClamped(lightDir, halfVector);
	d.svdn = abs(dot(stereoViewDir, i.normal));

	i.albedo.rgb *= (1 - metallicSmoothness.x);
	i.albedo.rgb = lerp(dot(i.albedo.rgb, grayscaleVec), i.albedo.rgb, _Saturation);
	i.diffuseColor.rgb = lerp(dot(i.diffuseColor.rgb, grayscaleVec), i.diffuseColor.rgb, _Saturation);

	half4 lightCol = half4(0, 0, 0, 0);
	calcLightCol(lightEnv, indirectDiffuse, lightCol);

	half lightAvg = (indirectDiffuse.r + indirectDiffuse.g + indirectDiffuse.b + lightCol.r + lightCol.g + lightCol.b) / 6;
	half3 envMapBlurred = getEnvMap(i, d, 5, reflView, indirectDiffuse, i.normal);

	half4 ramp = calcRamp(i, d);
	half4 diffuse = calcDiffuse(i, d, indirectDiffuse, lightCol, ramp);
	half4 rimLight = calcRimLight(i, d, lightCol, indirectDiffuse, envMapBlurred);
	half4 shadowRim = calcShadowRim(i, d, indirectDiffuse);
	half3 indirectSpecular = calcIndirectSpecular(i, d, metallicSmoothness, reflView, indirectDiffuse, viewDir, ramp);
	half3 directSpecular = calcDirectSpecular(i, d, lightCol, indirectDiffuse, metallicSmoothness, _AnisotropicAX * 0.1, _AnisotropicAY * 0.1);
	half4 subsurface = calcSubsurfaceScattering(i, d, lightDir, viewDir, i.normal, lightCol, indirectDiffuse);
	half4 occlusion = lerp(_OcclusionColor, 1, i.occlusion.r);
	half4 outlineColor = calcOutlineColor(i, d, indirectDiffuse, lightCol);

	half lineHalftone = 0;
	half stipplingDirect = 0;
	half stipplingRim = 0;
	half stipplingIndirect = 0;
	bool usingLineHalftone = 0;
	if (_HalftoneType == 0 || _HalftoneType == 2)
	{
		lineHalftone = lerp(1, LineHalftone(i, 1), 1 - saturate(dot(shadowRim * ramp, grayscaleVec)));
		usingLineHalftone = 1;
	}

	if (_HalftoneType == 1 || _HalftoneType == 2)
	{
		stipplingDirect = calHalftone(i, saturate(dot(directSpecular, grayscaleVec))) * saturate(dot(shadowRim * ramp, grayscaleVec));
		stipplingRim = calHalftone(i, saturate(dot(rimLight, grayscaleVec))) * saturate(dot(shadowRim * ramp, grayscaleVec));
		stipplingIndirect = calHalftone(i, saturate(dot(indirectSpecular, grayscaleVec))) * saturate(dot(shadowRim * ramp, grayscaleVec));

		directSpecular *= stipplingDirect;
		rimLight *= stipplingRim;
		indirectSpecular *= lerp(0.5, 1, stipplingIndirect); // Don't want these to go completely black, looks weird
	}

	half4 col;
	col = diffuse * shadowRim;
	calcReflectionBlending(i, col, indirectSpecular.xyzz);
	col += max(directSpecular.xyzz, rimLight);
	col += subsurface;
	col *= occlusion;
	calcClearcoat(col, i, d, untouchedNormal, indirectDiffuse, lightCol, viewDir, lightDir, ramp);
	col += calcEmission(i, lightAvg);

	float4 finalColor = lerp(col, outlineColor, i.isOutline) * lerp(1, lineHalftone, _HalftoneLineIntensity * usingLineHalftone);
	//finalColor = lerp(finalColor, rimLight.xyzz, 0.9999);
	return finalColor;
}

ToonSSSVertexOutput vert_Toonsss(ToonSSSVertexInput v)
{
	ToonSSSVertexOutput o = (ToonSSSVertexOutput)0;
#if defined(Geometry)
	o.vertex = v.vertex;
#endif

	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	float3 wnormal = UnityObjectToWorldNormal(v.normal);
	float3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
	half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	float3 bitangent = cross(wnormal, tangent) * tangentSign;
	o.ntb[0] = wnormal;
	o.ntb[1] = tangent;
	o.ntb[2] = bitangent;
	o.uv = v.uv;
	o.uv1 = v.uv1;
	o.color = float4(v.color.rgb, 0); // store if outline in alpha channel of vertex colors | 0 = not an outline
	o.normal = v.normal;
	o.screenPos = ComputeScreenPos(o.pos);
	o.objPos = normalize(v.vertex);
	UNITY_TRANSFER_SHADOW(o, o.uv);
	UNITY_TRANSFER_FOG(o, o.pos);
	return o;
}

float4 frag_Toonsss(
#if defined(Geometry)
	g2f i
#else
	ToonSSSVertexOutput i
#endif
	, uint facing : SV_IsFrontFace
) : SV_Target
{
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);

// fix for rare bug where light atten is 0 when there is no directional light in the scene
#ifdef UNITY_PASS_FORWARDBASE
	if (all(_LightColor0.rgb == 0.0))
	{
		attenuation = 1.0;
	}
#endif

#if defined(DIRECTIONAL)
	attenuation = lerp(attenuation, round(attenuation), _ShadowSharpness);
#endif

bool face = facing > 0; // True if on front face, False if on back face

if (!face) // Invert Normals based on face
{
	if (i.color.a > 0.99) { discard; }//Discard outlines front face always. This way cull off and outlines can be enabled.

	i.ntb[0] = -i.ntb[0];
	i.ntb[1] = -i.ntb[1];
	i.ntb[2] = -i.ntb[2];
}

TextureUV t = (TextureUV)0; // Populate UVs
if (_TilingMode != 1)
{
	InitializeTextureUVs(i, t);
}
else
{
	InitializeTextureUVsMerged(i, t);
}

XSLighting o = (XSLighting)0; //Populate Lighting Struct
o.albedo = UNITY_SAMPLE_TEX2D(_MainTex, t.albedoUV) * _Color * lerp(1, float4(i.color.rgb, 1), _VertexColorAlbedo);
o.specularMap = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecularMap, _MainTex, t.specularMapUV);
o.metallicGlossMap = UNITY_SAMPLE_TEX2D_SAMPLER(_MetallicGlossMap, _MainTex, t.metallicGlossMapUV);
o.detailMask = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailMask, _MainTex, t.detailMaskUV);
o.normalMap = UNITY_SAMPLE_TEX2D_SAMPLER(_BumpMap, _MainTex, t.normalMapUV);
o.detailNormal = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _MainTex, t.detailNormalUV);
o.thickness = UNITY_SAMPLE_TEX2D_SAMPLER(_ThicknessMap, _MainTex, t.thicknessMapUV);
o.occlusion = tex2D(_OcclusionMap, t.occlusionUV);
o.reflectivityMask = UNITY_SAMPLE_TEX2D_SAMPLER(_ReflectivityMask, _MainTex, t.reflectivityMaskUV) * _Reflectivity;
o.emissionMap = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, t.emissionMapUV) * _EmissionColor;
o.rampMask = UNITY_SAMPLE_TEX2D_SAMPLER(_RampSelectionMask, _MainTex, i.uv); // This texture doesn't need to ever be on a second uv channel, and doesn't need tiling, convince me otherwise.
#if defined(AlphaToMask) && defined(Masked) || defined(Dithered)
	o.cutoutMask = UNITY_SAMPLE_TEX2D_SAMPLER(_CutoutMask, _MainTex, i.uv);
#endif

o.diffuseColor = o.albedo.rgb; //Store this to separate the texture color and diffuse color for later.
o.attenuation = attenuation;
o.normal = i.ntb[0];
o.tangent = i.ntb[1];
o.bitangent = i.ntb[2];
o.worldPos = i.worldPos;
o.color = i.color.rgb;
o.isOutline = i.color.a;
o.screenUV = calcScreenUVs(i.screenPos);
o.objPos = i.objPos;

float4 col = BRDF_XSLighting(o);
calcAlpha(o);
UNITY_APPLY_FOG(i.fogCoord, col);

return float4(col.rgb, o.alpha);
}



#endif // X0FUNC_INCLUDED