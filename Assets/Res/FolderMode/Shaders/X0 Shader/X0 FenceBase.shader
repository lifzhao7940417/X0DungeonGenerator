Shader "X0/Fence/Base"
{

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase 
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
               
                UNITY_FOG_COORDS(1)
                 // float3 posWS:TEXCOORD2;
                //SHADOW_COORDS(3)
                //float4 screenPos : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o=(v2f)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.posWS = mul(unity_ObjectToWorld, v.vertex);

                UNITY_TRANSFER_FOG(o,o.pos);

                //o.screenPos = ComputeScreenPos(o.pos);
                //TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
               
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.r - 0.45);

                //float3 posWS = i.posWS;
                //UNITY_LIGHT_ATTENUATION(atten, i, posWS);
                //col = col * atten;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDHLSL
        }


        Pass
        {

            Tags { "LightMode" = "ShadowCaster" }


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
             #include "BearCodingHelper.hlsl"

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 vec : TEXCOORD0;
                float2  uv : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            v2f vert(a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                //用于保存顶点到光源的向量
                o.vec = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;
                //在裁剪空间中对坐标z分量应用深度偏移
                o.pos = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(v.vertex,v.normal));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                fixed4 texcol = tex2D(_MainTex, i.uv);
                float alpha = max(max(texcol.r, texcol.g), texcol.b);
                clip(alpha - 0.45);

                //计算深度
                return UnityEncodeCubeShadowDepth((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
            }
            ENDHLSL
        }
    }
}
