Shader "X0/Item/PlanarReflection"
{	
	Properties
	{
		_Color("DeepthColor",Color)=(1,1,1,1)
		_MaskTex("Mask Map",2D)="white"{}
		_NoiseTex("Noise Map",2d)="white"{}
		_NoiseValue("Noise Value",Range(0,1))=0.005
		_NoiseSpeed("Noise Speed",Range(0,1))=0.5
		_ReflectValue("Reflect Value",Range(0,1))=0
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent+50" }
		Blend one SrcAlpha
		ZWrite OFF

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct a2v
			{
				float2 uv:TEXCOORD0;
				float4 vertex : POSITION;
			};

 
			struct v2f
			{
				float4 screenPos : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 vertex:TEXCOORD1;
				float4 uv:TEXCOORD2;
			};

			float4 _Color;
			sampler2D _NoiseTex,_MaskTex;
			float4 _NoiseTex_ST,_MaskTex_ST;
			sampler2D _ReflectionTex;
			float _NoiseValue,_NoiseSpeed,_ReflectValue;

			v2f vert (a2v v)
			{
				v2f o;
				o.uv.xy=TRANSFORM_TEX(v.uv,_MaskTex);
				o.uv.zw=TRANSFORM_TEX(v.uv,_NoiseTex)+_Time.y*_NoiseSpeed;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.vertex=v.vertex;
				o.screenPos = ComputeScreenPos(o.pos);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 noise=tex2D(_NoiseTex, i.uv.zw);
				fixed4 mask=tex2D(_MaskTex,i.uv.xy);

				half2 noiseuv={noise.r,noise.r};

				//fixed4 AddColor=fixed4(0.5,0.5,0.5,1);
				//float water=step(1,mask.r);
				//noiseuv=noiseuv*mask.r*water+mask.r*50*(1-water)*AddColor;

				float water=mask.g;
				float reflect=mask.r;
				fixed4 AddColor=fixed4(_ReflectValue,_ReflectValue,_ReflectValue,1)*reflect;
				noiseuv=noiseuv*water;

				fixed4 RelfectColor=tex2D(_ReflectionTex, (i.screenPos.xy+noiseuv*_NoiseValue) / i.screenPos.w);
				fixed4 col = pow(RelfectColor,1.7);
				col*=_Color;
				col.a=_Color.a;
				return col;
			}

			ENDCG
		}
	}
}

