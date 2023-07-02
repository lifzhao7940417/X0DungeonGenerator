Shader "X0/Environment/Tree/Leaves"
{
	Properties
	{ 
		[Toggle(_HIDESIDES_ON)] _HideSides("Hide Sides", Float) = 0
		_HidePower("Hide Power", Float) = 2.5
		_Cutoff("Mask Clip Value", Float) = 0.29
		[Header(Main Maps)][Space(10)]_MainColor("Main Color", Color) = (1,1,1,0)
		_Diffuse("Diffuse", 2D) = "white" {}
		[Space(10)][Header(Gradient Parameters)][Space(10)]_GradientColor("Gradient Color", Color) = (1,1,1,0)
		_GradientFalloff("Gradient Falloff", Range(0 , 2)) = 2
		_GradientPosition("Gradient Position", Range(0 , 1)) = 0.5
		[Toggle(_INVERTGRADIENT_ON)] _InvertGradient("Invert Gradient", Float) = 0
		[Space(10)][Header(Color Variation)][Space(10)]_ColorVariation("Color Variation", Color) = (1,0,0,0)
		_ColorVariationPower("Color Variation Power", Range(0 , 1)) = 1
		_ColorVariationNoise("Color Variation Noise", 2D) = "white" {}
		_NoiseScale("Noise Scale", Float) = 0.5
	}

	SubShader
	{

		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "AlphaTest+0" }
		Cull Off
		//AlphaToMask On

		Pass
		{						
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.0
			#pragma multi_compile_instancing
			#pragma multi_compile_fwdbase

			#pragma shader_feature_local _HIDESIDES_ON
			#pragma shader_feature_local _INVERTGRADIENT_ON

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "X0SceneParameter.hlsl"

			/*#define UNITY_INSTANCED_LOD_FADE
			#define INTERNAL_DATA*/

			struct a2v
			{
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				fixed4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};


			struct v2f 
			{
				float4 pos : SV_POSITION;
				float4 worldNormal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float4 custompack0 : TEXCOORD3; // screenPosition
				float4 custompack1 : TEXCOORD4; // UV
				float3 vertexColor:TEXCOORD5;
				SHADOW_COORDS(6)

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _Diffuse;
			uniform float4 _Diffuse_ST;
			uniform float4 _MainColor;

			 float _Cutoff = 0.29;
			uniform float _HidePower;

			uniform float4 _GradientColor;
			uniform float _GradientPosition;
			uniform float _GradientFalloff;
			uniform float4 _ColorVariation;
			uniform float _ColorVariationPower;
			uniform sampler2D _ColorVariationNoise;
			uniform float _NoiseScale;


			v2f vert(a2v v) 
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.worldNormal.w = v.vertex.y;
				float3 posWS = mul(unity_ObjectToWorld, v.vertex);
				v.vertex.xyz += AddWindTree(posWS, v.normal.xyz, v.color.r, v.color.r).xyz;
				v.vertex.w = 1;

				float4 screenPos = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldNormal.xyz = worldNormal;
				o.custompack1.xy = v.texcoord;
				o.custompack0.xyzw = screenPos;
				o.worldPos = worldPos;

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				TRANSFER_SHADOW(o);

				return o;
			}

			float3 GetAlbeod(float3 posWS,float3 normalWS,float3 diffuseColor,float3 vertexColor)
			{
				float3 Albedo = float3(0, 0, 0);
				#ifdef _INVERTGRADIENT_ON
					float grayvalue = (1.0 - normalWS.y);
				#else
					float grayvalue = normalWS.y;
				#endif

				float grayResult = clamp(((grayvalue + (-2.0 + (_GradientPosition - 0.0) * (1.0 - -2.0) / (1.0 - 0.0))) / _GradientFalloff), 0.0, 1.0);
				float4 baseColor = lerp(_MainColor, _GradientColor, grayResult);
				float2 appenedPosWS = (float2(posWS.x, posWS.z));
				float4 lerpColor = lerp(_ColorVariation, (_ColorVariation / max(1.0 - baseColor, 0.00001)), _ColorVariationPower);
				float4 ColorResult = lerp(baseColor, (saturate(lerpColor)), (_ColorVariationPower * pow(tex2D(_ColorVariationNoise, (appenedPosWS * (_NoiseScale / 100.0))), (3.0).xxxx)));
				float3 AlbedoColor = (ColorResult.rgb * diffuseColor);

				#ifdef _SEEVERTEXCOLOR_ON
					Albedo = vertexColor;
				#else
					Albedo = AlbedoColor;
				#endif

				return Albedo;
			}

			fixed4 frag(v2f IN) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				float2 uv_texcoord = IN.custompack1.xy;
				float4 screenPosition = IN.custompack0.xyzw;
				float3 worldPos = IN.worldPos.xyz;
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 normalWS = IN.worldNormal.xyz;
				float localPosy = IN.worldNormal.w;

				DitheredCutOff(localPosy, screenPosition);

				#ifndef USING_DIRECTIONAL_LIGHT
						fixed3 lightWS = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
						fixed3 lightWS = _WorldSpaceLightPos0.xyz;
				#endif

				float4 DiffuseTex = tex2D(_Diffuse, uv_texcoord * _Diffuse_ST.xy + _Diffuse_ST.zw);
				float3 Albedo = GetAlbeod(worldPos, normalWS,DiffuseTex.rgb,IN.vertexColor.rgb);
				float Alpha = DiffuseTex.a;

				ClipDither(worldPos,screenPosition, worldViewDir, Alpha,_HidePower, _Cutoff);

				float shadow = SHADOW_ATTENUATION(IN);
				float3 cloud = GetCloud(normalWS, worldPos,1).rgb;
				float3 envDark = min(shadow, cloud) * 0.5 + 0.5;
				float3 FinallColor = _MainLightColor*  Albedo * envDark;
				
				return half4(FinallColor, Alpha);
			}
			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 5.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER

			#pragma shader_feature_local _HIDESIDES_ON
			#pragma shader_feature_local _INVERTGRADIENT_ON

			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "X0SceneParameter.hlsl"

			uniform float4 _GradientColor;
			uniform float _GradientPosition;
			uniform float _GradientFalloff;
			uniform float4 _MainColor;

			uniform float4 _ColorVariation;
			uniform float _ColorVariationPower;
			uniform sampler2D _ColorVariationNoise;
			uniform float _NoiseScale;
			uniform sampler2D _Diffuse;
			uniform float4 _Diffuse_ST;

			 float _Cutoff = 0.29;
			uniform float _HidePower;

			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 customPack2 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float3 worldNormal : TEXCOORD4;
				half4 color : COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 posWS = mul(unity_ObjectToWorld, v.vertex);
				v.vertex.xyz += AddWindTree(posWS, v.normal.xyz, v.color.r, v.color.r).xyz;
				v.vertex.w = 1;

				float4 screenPos = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldNormal = worldNormal;
				o.customPack1.xy = v.texcoord;
				o.customPack2.xyzw = screenPos;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				//TRANSFER_SHADOW(o);
				o.color = v.color;

				return o;
			}
			half4 frag(v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				
				float2 uv_texcoord = IN.customPack1.xy;
				float4 DiffuseTex = tex2D(_Diffuse, uv_texcoord * _Diffuse_ST.xy + _Diffuse_ST.zw);
				float4 screenPosition = IN.customPack2.xyzw;
				float3 posWS = IN.worldPos;
				half3 viewWS = normalize(UnityWorldSpaceViewDir(posWS));

				//DitheredCutOff(i.vertexOS.y, i.screenPos);

				ClipDither(posWS, screenPosition, viewWS, DiffuseTex.a, _HidePower, _Cutoff);

				#if defined( CAN_SKIP_VPOS )
					float2 vpos = IN.pos;
				#endif

				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		}
	}

	FallBack "Specular"
}