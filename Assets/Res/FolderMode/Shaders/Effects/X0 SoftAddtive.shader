Shader "X0/Fx/SoftAdd"
{
	Properties
	{
		[HDR]_TintColor("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		_MainTex("Particle Texture", 2D) = "white" {}
		[HideInInspector]_Center("Center",Vector) = (0,0,0,1)
		[HideInInspector]_Scale("Scale",Vector) = (1,1,1,1)
		[HideInInspector]_Normal("Normal",Vector) = (0,0,1,0)
		_InvFade("Soft Particles Factor", Range(0.01,10.0)) = 10.0 //1.0
	}

		Category
		{
			Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off Lighting Off ZWrite Off Fog { Mode Off}

			SubShader
			{
				Pass
				{
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag
					#pragma fragmentoption ARB_precision_hint_fastest

					#pragma multi_compile _ _SOFT_PARTICLE_ON
					#define _SOFT_PARTICLE_ON
					#define _SOFT_PARTICLE_DEPTH_MAP_DEF_ON

					#include "SoftParticleCommon.cginc"
					#include "Assets/Res/FolderMode/Shaders/X0 Shader/X0SceneParameter.hlsl"

					sampler2D _MainTex;
					fixed4 _TintColor;

					struct appdata_t
					{
						float4 vertex : POSITION;
						fixed4 color : COLOR;
						float2 texcoord : TEXCOORD0;
					};

					struct v2f
					{
						float4 vertex : SV_POSITION;
						fixed4 color : COLOR;
						float2 texcoord : TEXCOORD0;
						SOFT_PARTICLE_V2F(1)
					};

					float4 _MainTex_ST;

					float4 _Center;
					float4 _Scale;
					float4 _Normal;

					uniform float4x4 _Camera2World;

					v2f vert(appdata_t v)
					{
						v2f o;
						 o.vertex = UnityObjectToClipPos(v.vertex);

						o.color = v.color;
						o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);

						SOFT_PARTICLE_VERT(o)

						return o;
					}

					fixed4 frag(v2f i) : SV_Target
					{
						float fade;
						SOFT_PARTICLE_FRAG_FADE(i, fade)
						fixed4 col = saturate(2.0f * i.color * _TintColor * tex2D(_MainTex, i.texcoord));
						col.a *= fade;

						float4 SceneColor = GetSceneColor();

						col.a *= SceneColor.a;
						col.rgb *= SceneColor.rgb;

						return col;
					}
					ENDCG
				}
			}
		}
}