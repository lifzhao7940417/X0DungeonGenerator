Shader "X0/Environment/Floor/TriplanarSamplingDefault"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,1)
        _MainTex("Main Tex", 2D) = "white" {}
        _DetailTilling("Detail Tilling",Float) = 1

    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase  
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
                #include "X0SceneParameter.hlsl"

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex_world : TEXCOORD1;
                SHADOW_COORDS(2)
                float4 tSpace0 : TEXCOORD3;
                float4 tSpace1 : TEXCOORD4;
                float4 tSpace2 : TEXCOORD5;

                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float _DetailTilling;
            float4 _Color;


            v2f vert(appdata_full v)
            {
                v2f o = (v2f)0;
                o.vertex_world = v.vertex;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord;


                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;

                o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o)
                return o;
            }


            inline float4 TriplanarSampling60(sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale)
            {
                float3 projNormal = (pow(abs(worldNormal), falloff));
                projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
                float3 nsign = sign(worldNormal);
                half4 xNorm; half4 yNorm; half4 zNorm;

                xNorm = tex2D(topTexMap, tiling * worldPos.zy * float2(nsign.x, 1.0));
                yNorm = tex2D(topTexMap, tiling * worldPos.xz * float2(nsign.y, 1.0));
                zNorm = tex2D(topTexMap, tiling * worldPos.xy * float2(-nsign.z, 1.0));

                return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
            }


            float3 GetWorldVector(v2f IN,float3 InVector)
            {
                return half3(dot(IN.tSpace0.xyz, InVector), dot(IN.tSpace1.xyz, InVector), dot(IN.tSpace2.xyz, InVector));
            }


            fixed4 frag(v2f i) : SV_Target
            {
                #ifndef USING_DIRECTIONAL_LIGHT
                        fixed3 lightWS = normalize(UnityWorldSpaceLightDir(worldPos));
                #else
                        fixed3 lightWS = _WorldSpaceLightPos0.xyz;
                #endif


                float3 posWS = float3(i.tSpace0.w, i.tSpace1.w, i.tSpace2.w);;
                float3 normalWS = GetWorldVector(i, float3(0, 0, 1));
                float3 tangentWS = GetWorldVector(i, float3(1, 0, 0));
                float3 bitangentWS = GetWorldVector(i, float3(0, 1, 0));

                fixed shadow = SHADOW_ATTENUATION(i) * 0.5 + 0.5;
                float3 cloud = GetCloud(normalWS, posWS,0).rgb;

                float3 envDark = min(shadow ,cloud) * 0.5 + 0.5;

                float4 triplanar60 = TriplanarSampling60(_MainTex, posWS, normalWS, 1.0, float2(_DetailTilling, _DetailTilling), 1.0);

                float4 col = float4(1, 1, 1, 1);
                col.rgb = _Color.rgb*(triplanar60.rgb * 0.25 + 0.25) * _MainLightColor * envDark;

                return col;
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
