Shader "X0/Environment/Grass/Mesh"
{
	Properties
	{
		_Cutoff("Mask Clip Value", Float) = 0.29
		[Space(10)]_Color01("Color 01", Color) = (1,0.3215686,0,1)
		_Color02("Color 02", Color) = (1,0.3215686,0,1)
		[Space(10)]_MainTex("Texture", 2D) = "white" {}
		_ColorVariationPower("Color Variation Power", Range(0 , 1)) = 1
		[Space(10)]_Noise("Noise", 2D) = "white" {}
		_NoiseTiling("Noise Tiling", Float) = 1.09
		_Dither("Dither",Range(0,1)) = 0
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
				float2 pack0 : TEXCOORD0; // _texcoord
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float4 custompack0 : TEXCOORD3; // screenPosition
				float custompack1 : TEXCOORD4; // eyeDepth
				float3 vertexColor:TEXCOORD5;
				SHADOW_COORDS(6)

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform float4 _Color01;
			uniform float4 _Color02;
			uniform float _ColorVariationPower;
			uniform sampler2D _Noise;
			uniform float _NoiseTiling;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float GrassRenderDist;
			uniform float _Cutoff = 0.29;
			uniform float _Dither;


			v2f vert(a2v v) 
			{
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


				float3 posWS = mul(unity_ObjectToWorld, v.vertex);

				v.vertex.xyz += AddWind(posWS, v.texcoord, v.color);
				v.vertex.w = 1;

				float4 screenPosition = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
				float eyeDepth = -UnityObjectToViewPos(v.vertex.xyz).z;

				o.vertexColor = v.color;
				o.custompack0.xyzw = screenPosition;
				o.custompack1.x = eyeDepth;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.pack0.xy = v.texcoord;
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos.xyz = worldPos;
				o.worldNormal = worldNormal;


				TRANSFER_SHADOW(o);

				return o;
			}

			void ClipDither(float eyeDepth,float4 screenPosition,float2 uv_texcoord,float texAlpha)
			{
				float4 screenPosNorm = screenPosition / screenPosition.w;
				screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
				float2 clipScreenUV = screenPosNorm.xy * _ScreenParams.xy;
				float cameraDepthFade = ((eyeDepth - _ProjectionParams.y - GrassRenderDist) / GrassRenderDist);
				float dither = Dither8x8BayerCopy(fmod(clipScreenUV.x, 8), fmod(clipScreenUV.y, 8));
				float GrassDownDither = step(dither, (1.0 - cameraDepthFade));
				GrassDownDither = lerp(1, GrassDownDither, _Dither);
				float LinearUVX = GammaToLinearSpace(((1.5 + (uv_texcoord.y - 0.11) * (8.0 - 1.5) / (0.52 - 0.11))).xxx);
				dither = step(dither, clamp(LinearUVX, 0, 1));
				clip(((texAlpha * GrassDownDither) * dither) - _Cutoff);
			}

			fixed4 frag(v2f IN) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				float2 uv_texcoord = IN.pack0.xy;
				float4 screenPosition = IN.custompack0.xyzw;
				float eyeDepth = IN.custompack1.x;
				float3 worldPos = IN.worldPos.xyz;
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float3 normalWS = IN.worldNormal;


				#ifndef USING_DIRECTIONAL_LIGHT
						fixed3 lightWS = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
						fixed3 lightWS = _WorldSpaceLightPos0.xyz;
				#endif

				float4 ColorWithNoise = lerp(_Color01, _Color02, (_ColorVariationPower * tex2D(_Noise, (float2(worldPos.x, worldPos.z) * _NoiseTiling)).r));
				float4 AlbedoTex = tex2D(_MainTex, uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw);
				float3 Albedo = (ColorWithNoise * AlbedoTex.r);
				float Alpha = AlbedoTex.a;

				ClipDither(eyeDepth,screenPosition, uv_texcoord, Alpha);

				float shadow = SHADOW_ATTENUATION(IN) * 0.5 + 0.5;

				return half4(_MainLightColor * Albedo * shadow, Alpha);
			}
			ENDCG
		}
	}
	Fallback "Transparent/Cutout/VertexLit"
}