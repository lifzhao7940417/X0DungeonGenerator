//#	BearCodingHelper
//1.	后期集成的辅助性功能函数接口
//#	大熊

#ifndef BEARCODINGHELPER_INCLUDE
#define BEARCODINGHELPER_INCLUDE


#include "UnityStandardInput.cginc"

#include "Lighting.cginc"
#include "AutoLight.cginc"

//	[MaterialToggle(_ZRIM_ON)] _Toggle("ZWrite Rim", Float) = 0 
//#pragma multi_compile _ZRIM_OFF _ZRIM_ON

//float3 _WorldSpaceCameraPos.xyz;

//float4 mul(unity_ObjectToWorld, v.vertex);

//float3 UnityWorldSpaceViewDir(worldPos);
//float3 UnityWorldSpaceLightDir(worldPos
//float3 UnityObjectToWorldNormal(v.normal);

//float3 UnityObjectToWorldDir(tangent.xyz)


//struct appdata_base {
//    float4 vertex : POSITION;//顶点位置
//    float3 normal : NORMAL;//发现
//    float4 texcoord : TEXCOORD0;//纹理坐标
//    UNITY_VERTEX_INPUT_INSTANCE_ID
//};

//struct appdata_tan {
//    float4 vertex : POSITION;
//    float4 tangent : TANGENT;//切线
//    float3 normal : NORMAL;
//    float4 texcoord : TEXCOORD0;
//    UNITY_VERTEX_INPUT_INSTANCE_ID
//};

//struct appdata_full {
//    float4 vertex : POSITION;
//    float4 tangent : TANGENT;
//    float3 normal : NORMAL;
//    float4 texcoord : TEXCOORD0;
//    float4 texcoord1 : TEXCOORD1;//第二纹理坐标
//    float4 texcoord2 : TEXCOORD2;//第三纹理坐标
//    float4 texcoord3 : TEXCOORD3;//第四纹理坐标
//    fixed4 color : COLOR;//顶点颜色
//    UNITY_VERTEX_INPUT_INSTANCE_ID
//};


 struct a2v_full {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    fixed4 color : COLOR;//顶点颜色
};

struct v2f_full
{
	float4 pos  : SV_POSITION;
	float4 tex  : TEXCOORD0;
	half3 eyeVec	: TEXCOORD1;
	float4 tangentToWorldAndPackedData[3]    : TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
	half4 ambientOrLightmapUV   : TEXCOORD5;    // SH or Lightmap UV
	float3 posWorld : TEXCOORD6;
};

struct a2v_base
{
	float2 uv:TEXCOORD0;
	float4 vertex:POSITION;
	float3 normal:NORMAL;
};

struct a2v_normal
{
	float4 texcoord : TEXCOORD0;
	float4 vertex:POSITION;
	float3 normal:NORMAL;
	float4 tangent:TANGENT;
};


struct v2f_base
{
	float4 pos:SV_POSITION;
	float4 color:TEXCOORD0;
	float2 uv:TEXCOORD1;
};

struct v2f_shadow
{
	float4 pos:SV_POSITION;
	float4 uv:TEXCOORD0;
	float4 t2wSpaceData[3]	: TEXCOORD2; //2-4
	SHADOW_COORDS(5)
	float4 color:TEXCOORD6;
	float4 uvmask:TEXCOORD7;
};

v2f_shadow UnityShadowVert(v2f_shadow o)
{
	TRANSFER_SHADOW(o);
	return o;
}

float UnityShadowFrag_atten(v2f_shadow i,float3 worldPos)
{
	UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
	return atten*SHADOW_ATTENUATION(i)+0.5;
}

float UnityShadowFrag_base(v2f_shadow i)
{
	return SHADOW_ATTENUATION(i);
}

float2 TransformViewToProjectionToOffset(float3 normal)
{
	float3 norm = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, normal));
	return TransformViewToProjection(norm.xy);
}


float4 OutLineViewPosV3(float4 pos, float3 normal, float3 width)
{
	float2 offset	= TransformViewToProjectionToOffset(normal);
	pos.xy+=offset*width.xy*pos.z;
	pos.z	+=width.z;
	return pos;
}

float4 OutLineViewPos(float4 pos, float3 normal, float xy_width,float z_push)
{
	float2 offset	= TransformViewToProjectionToOffset(normal);
	pos.xy+=offset*xy_width*pos.z;
	pos.z	+=z_push;
	return pos;
}

half3 NLToToonRampAtten(float nl,float RampThreshold,float RampSmooth,float4 SColor,float4 HColor)
{
	fixed3 ToonRampAtten = smoothstep(RampThreshold - RampSmooth*0.5, RampThreshold + RampSmooth*0.5, nl);
	SColor = lerp(HColor, SColor, SColor.a);	
	ToonRampAtten = lerp(SColor.rgb, HColor.rgb, ToonRampAtten);
	return ToonRampAtten;
}

half2 GetUvFormIndex(float2 inUV, int inIndex, float inRow, float inColumn)
{
	half index = min(max(inIndex, 1), inRow* inColumn) * 1.0f;
	half xeach = (1 / inColumn);
	half xaddStep = min(index % inColumn, 1);
	half uvx = lerp((inColumn - 1) * xeach, (index % inColumn - 1) * xeach, xaddStep);

	half yeach = (1 / inRow);
	half finallStep = floor(index /(inRow * inColumn));
	half uvy = lerp(floor(index / inColumn) * yeach,(floor((index-1) / inColumn) * yeach), finallStep);
	return inUV * half2(xeach, yeach) + half2(uvx, uvy);
}

half3 WorldCameraPos()
{
	return _WorldSpaceCameraPos.xyz;
}

half3 WorldLightDir(float3 worldPos)
{
	//_WorldSpaceLightPos0光源位置
	//_WorldSpaceLightPos0.w = 0 代表平行光的方向，_WorldSpaceLightPos0.w = 1代表其他光源的位置
	return normalize(UnityWorldSpaceLightDir(worldPos));
}

half3 WorldViewDir(float3 worldPos)
{
	return normalize(UnityWorldSpaceViewDir(worldPos));
}

half3 ObjViewDir(float4 vertex)
{
	return normalize(ObjSpaceViewDir(vertex));
}


float3x3 T2WMatrix(float4 tangent,float3 worldnormal)
{
	float4 tangentWorld = float4(UnityObjectToWorldDir(tangent.xyz), tangent.w);
	float3x3 tangentToWorld = CreateTangentToWorldPerVertex(worldnormal, tangentWorld.xyz, tangentWorld.w);
	return tangentToWorld;
}

half3 CustomPerPixelWorldNormal(float4 uv, float4 tangentToWorld[3])
{
#ifdef _NORMALMAP
	half3 tangent = tangentToWorld[0].xyz;
	half3 binormal = tangentToWorld[1].xyz;
	half3 normal = tangentToWorld[2].xyz;

	#if UNITY_TANGENT_ORTHONORMALIZE
		normal = NormalizePerPixelNormal(normal);

		// ortho-normalize Tangent
		tangent = normalize (tangent - normal * dot(tangent, normal));

		// recalculate Binormal
		half3 newB = cross(normal, tangent);
		binormal = newB * sign (dot (newB, binormal));
	#endif

	half3 normalTangent = NormalInTangentSpace(uv);
	half3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
#else
	half3 normalWorld = normalize(tangentToWorld[2].xyz);
#endif
	return normalWorld;
}

#endif // BEARCODINGHELPER_INCLUDE