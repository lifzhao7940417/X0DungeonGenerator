Shader "X0/Item/ToonLit" {
	Properties {
		_GrayValue("Gray Value",Range(0,1))=0
		_GrayStep("GrayStep",Range(1,10))=1
		_Color ("Main Color", Color) = (0.5,0.5,0.5,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}

	SubShader 
	{
		Tags{"Queue"="Geometry" "RenderType"="Opaque"}
	
		pass
		{
		
			Tags{"LightMode" = "ForwardBase"}

			Cull off

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase 
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
            #include "AutoLight.cginc"
			#include "BearCodingHelper.hlsl"
			#include "X0SceneParameter.hlsl"

			sampler2D _Ramp;
			float _GrayValue, _GrayStep;

			struct a2v
			{
				float4 texcoord : TEXCOORD0;
				float4 vertex:POSITION;
				float3 normal:NORMAL;
				float4 tangent:TANGENT;
			};


			struct v2f
			{
				float4 pos:SV_POSITION;
				float4 uv:TEXCOORD0;
				float4 t2wSpaceData[3]	: TEXCOORD2; //2-4
				SHADOW_COORDS(5)
				float4 screenPos : TEXCOORD6;
				float4 vertexOS : TEXCOORD7;
			};

			v2f vert(a2v v)
			{
				v2f o;

				o.vertexOS = v.vertex;
				o.pos=UnityObjectToClipPos(v.vertex);
				
				float3 worldNormal=UnityObjectToWorldNormal(v.normal);
				float3 worldPos= mul(unity_ObjectToWorld, v.vertex);

				float3x3	t2wMatrix=T2WMatrix(v.tangent,worldNormal);

				o.t2wSpaceData[0].xyz=t2wMatrix[0].xyz;
				o.t2wSpaceData[1].xyz=t2wMatrix[1].xyz;
				o.t2wSpaceData[2].xyz=t2wMatrix[2].xyz;

				o.t2wSpaceData[0].w=worldPos.x;
				o.t2wSpaceData[1].w=worldPos.y;
				o.t2wSpaceData[2].w=worldPos.z;

				o.uv = v.texcoord;
				o.screenPos = ComputeScreenPos(o.pos);
				
				TRANSFER_SHADOW(o);
				return o;
			}

			half3 GrayValue(float3 inOrignalColor, float inStep,float inValue)
			{
				fixed3 gray = dot(inOrignalColor, fixed3(0.299, 0.587, 0.114)).xxx;
				gray *= inStep;
				return lerp(inOrignalColor, gray, inValue);
			}

			half4 frag(v2f i) :COLOR
			{
				DitheredCutOff(i.vertexOS.y,i.screenPos);

				float3 worldPos = float3(i.t2wSpaceData[0].w, i.t2wSpaceData[1].w, i.t2wSpaceData[2].w);
				half3 worldnormal=CustomPerPixelWorldNormal(i.uv,i.t2wSpaceData);
				half3 worldlightdir=WorldLightDir(worldPos);
	
				half d = dot (worldnormal, worldlightdir)*0.5 + 0.5;

				UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

				float3 cloud = 1;
				float3 EnvDark = min(atten, cloud) * 0.5 + 0.5;
	
				half4 Albedo = tex2D(_MainTex, i.uv) ;
				Albedo.rgb = GrayValue(Albedo.rgb, _GrayStep,_GrayValue) * _Color.rgb;

				half4 color;
				color.rgb = EnvDark * Albedo.rgb* _MainLightColor.rgb * 2;
				color.a = 1;

				return color;
			}

			ENDHLSL
		}
	}

	Fallback "Specular"
}
