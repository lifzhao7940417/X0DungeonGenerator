Shader "X0/Character/Player_Base"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RimColor("RimColor",Color) = (1,0,0,0)
        _RimLerp("RimLerp",Range(0,1)) = 0
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque"}
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase  

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
             #include "X0SceneParameter.hlsl"


            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                SHADOW_COORDS(1)
                float4 tSpace0 : TEXCOORD2;
                float4 tSpace1 : TEXCOORD3;
                float4 tSpace2 : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _RimColor;
            float _RimLerp;

            v2f vert (a2v v)
            {
                v2f o=(v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.uv.xy;

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

            float3 GetWorldVector(v2f IN, float3 InVector)
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

                float ndl = step(0.1,dot(normalWS, lightWS)) * 0.5 + 0.5;

                float shadow = (1 - step(SHADOW_ATTENUATION(i), 0.5));
                float3 cloud = GetCloud(normalWS, posWS,1).rgb;
                float3 envDark = min(shadow, cloud) * 0.5 + 0.5;

                float4 albedo = tex2D(_MainTex, i.uv.xy);

                float toon = min(envDark, ndl);

                float4 DirectDiffuse = albedo * ndl;
                float4 DirectSpecular = 0;
                float4 inDirectDiuffuse = 0;
                float4 inDirectSpecular = 0;

                float alpha = 1;

                float3 col = _MainLightColor * toon * (DirectDiffuse + DirectSpecular) + inDirectDiuffuse + inDirectSpecular;

                col = lerp(col, _RimColor.rgb, _RimLerp);



                return float4(col,alpha);
            }
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
            ZWrite On ZTest LEqual
            CGPROGRAM
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
            #pragma target 3.0
            #pragma multi_compile_shadowcaster

            #ifndef UNITY_PASS_SHADOWCASTER
                #define UNITY_PASS_SHADOWCASTER
            #endif

            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #include "X0ShadowCaster.hlsl"
            ENDCG
        }
    }

    FallBack "Specular"
}
