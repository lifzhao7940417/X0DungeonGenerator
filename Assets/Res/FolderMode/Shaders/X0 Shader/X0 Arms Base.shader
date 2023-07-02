Shader "X0/Character/Arms_Base"
{
    Properties
    {
        _DarkMode("Dark Mode", Range(0,1)) = 0
        _MainTex ("Texture", 2D) = "white" {}

        [Space(30)]
        [Enum(Normal, 0, Smail, 1, No, 2, Soso, 3)] _Facial("Facial Mode", Int) = 0
        _EyePos("AnchorEyeUV",vector)=(0,0,0,5)
        _EyeBaseNormalPos("Normal&Soso_UV",Vector) = (0,0,0,0)
        _EyeSmallSadPos("Smail&No_UV",Vector)=(0,0,0,0)

        [HideInInspector]_OutlineColor("Outline Color", COLOR) = (0,0.678,0.749,0.247)
        [HideInInspector]_OutlineSize("_OutlineSize",Float)=0
        [HideInInspector]_OutlineOffset("_OutlineOffset",Float) = 0

        [Space(30)]
        _ShakeParams("ShakeParam",Vector) = (2.5,0.01,1,1)  //x-range,y-intensity
        [HideInInspector]_ShakePosWS("ShakePosWS",Vector) = (0,0,0,1)
        [HideInInspector]_ShakeDirWS("ShakeDirWS",Vector) = (0,0,0,1)
        _ShakeDur("ShakeDur",Range(0,1))=0

        [Space(30)]
        [HDR]_DamageColor("Damage Color",Color)=(1,0,0,1)
        _DamageDur("Damage Dur",Range(0,1)) = 0
    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Tags {  "Queue" = "Geometry+500" "IgnoreProjector" = "True" }
        LOD 100

        Pass
        {
            Name "Outline"
            ZWrite Off
            Cull Front
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "X0SceneParameter.hlsl"

            float _OutlineSize,_OutlineOffset;
            float4 _OutlineColor;
            //float _Cullable;

            struct v2f 
            {
                float4 pos : SV_POSITION;
                float4 screenPos:TEXCOORD0;
            };


            v2f vert(appdata_full  v) {
                v2f o;

                v.vertex = GetShakeVertex(v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);

                o.screenPos = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
                float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                float2 offset = TransformViewToProjection(vnormal.xy);
                o.pos.xy += offset * _OutlineSize * lerp(1, abs(_SinTime.w), _OutlineOffset);
                return o;
            }

            fixed4 frag(v2f i) :SV_Target
            {
                float4 screenPosition = i.screenPos;
                //DitheredCutOffSelf(1, screenPosition, _Cullable, 0.35f,0.45f,0);
                return float4(_OutlineColor);
            }

            ENDCG
        }


        Pass
        {
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "X0SceneParameter.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 posWS : TEXCOORD2;
                SHADOW_COORDS(3)
                float4 screenPos:TEXCOORD5;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;float4 _MainTex_ST;
           
            int _Facial;

            float4 _EyePos;float4 _EyeSmallSadPos, _EyeBaseNormalPos;

            float _DarkMode; float _Cullable;

            float4 _DamageColor; float _DamageDur;

            float2 GetEyeUV(float2 baseUV,int index)
            {
                float2 eyeUV = baseUV;
                if (index == 0)
                {
                    eyeUV = baseUV * float2(1, 1) + _EyeBaseNormalPos.xy;
                }
                else if (index == 1)
                {
                    eyeUV = baseUV * float2(1, 1) + _EyeSmallSadPos.xy;
                }
                else if (index == 2)
                {
                    eyeUV = baseUV * float2(1, 1) + _EyeSmallSadPos.zw;
                }
                else if (index == 3)
                {
                    eyeUV = baseUV * float2(1, 1) + _EyeBaseNormalPos.zw;
                }

                return eyeUV;
            }

            float3 GetDamageOutLine(float3 inViewWS, float3 inNormalWS)
            {
                fixed nov = clamp(pow((1 - dot(inViewWS, inNormalWS)), 2) - 0.33,0,1);
                return lerp(fixed3(0,0,0), nov *_DamageColor.rgb, _DamageDur);
            }

            v2f vert (appdata v)
            {
                v2f o;

                v.vertex = GetShakeVertex(v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.uv.xy;
                o.uv.zw = GetEyeUV(v.uv.xy, _Facial);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.screenPos = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
                o.posWS.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.posWS.w = v.vertex.y;

                TRANSFER_SHADOW(o)
                return o;
            }


            fixed4 frag(v2f i) : SV_Target
            {
                float3 posWS = i.posWS;
                float3 normalWS = normalize(i.normal);
                float localPosy = i.posWS.w;
                float4 screenPosition = i.screenPos;
                half3 viewWS = normalize(UnityWorldSpaceViewDir(posWS));

                //DitheredCutOffSelf(1, screenPosition, _Cullable, 0.35f, 0.45f, 0);
                fixed4 MainColor = tex2D(_MainTex, i.uv.xy);

                #ifndef USING_DIRECTIONAL_LIGHT
                        fixed3 lightWS = normalize(UnityWorldSpaceLightDir(posWS));
                #else
                        fixed3 lightWS = _WorldSpaceLightPos0.xyz;
                #endif

                float ndl = step(0.1,dot(normalWS, lightWS)) * 0.5 + 0.5;

                float shadow = (1 - step(SHADOW_ATTENUATION(i), 0.5));
                float3 cloud =  GetCloud(normalWS, posWS, 1).rgb;
                float3 envDark = min(shadow, cloud) * 0.5 + 0.5;

                float3 eyeCol = tex2D(_MainTex, i.uv.zw);
                float eyeRange = step(distance(_EyePos.xy, i.uv.xy) * _EyePos.w, 1);

                float3 Albedo = envDark* ndl* lerp(_MainLightColor* MainColor.rgb, eyeCol, eyeRange);
                
                Albedo = lerp(Albedo, dot(Albedo, vec3(0.299, 0.587, 0.114)), _DarkMode);

                Albedo += GetDamageOutLine(viewWS, normalWS);

                return float4(Albedo,1);
            }
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
            ZWrite On ZTest LEqual
            CGPROGRAM

            #pragma vertex vertShadowCaster_ShakeBone
            #pragma fragment fragShadowCaster
            #pragma target 3.0
            #pragma multi_compile_shadowcaster

            #ifndef UNITY_PASS_SHADOWCASTER
                #define UNITY_PASS_SHADOWCASTER
            #endif

            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2


            #include "X0ShadowCaster.hlsl"
            #include "X0SceneParameter.hlsl"

            float4 Cus_UnityApplyLinearShadowBias(float4 clipPos)
            {
                // For point lights that support depth cube map, the bias is applied in the fragment shader sampling the shadow map.
                // This is because the legacy behaviour for point light shadow map cannot be implemented by offseting the vertex position
                // in the vertex shader generating the shadow map.
            #if !(defined(SHADOWS_CUBE) && defined(SHADOWS_CUBE_IN_DEPTH_TEX))
            #if defined(UNITY_REVERSED_Z)
                // We use max/min instead of clamp to ensure proper handling of the rare case
                // where both numerator and denominator are zero and the fraction becomes NaN.
                clipPos.z += max(-1, min(unity_LightShadowBias.x / clipPos.w, 0));
            #else
                clipPos.z += saturate(unity_LightShadowBias.x / clipPos.w);
            #endif
            #endif

            #if defined(UNITY_REVERSED_Z)
                float clamped = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
            #else
                float clamped = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
            #endif
                clipPos.z = lerp(clipPos.z, clamped, unity_LightShadowBias.y);
                return clipPos;
            }

            float4 Cus_UnityClipSpaceShadowCasterPos(float4 vertex, float3 normal)
            {
                vertex = GetShakeVertex(vertex);

                float4 wPos = mul(unity_ObjectToWorld, vertex);

                if (unity_LightShadowBias.z != 0.0)
                {
                    float3 wNormal = UnityObjectToWorldNormal(normal);
                    float3 wLight = normalize(UnityWorldSpaceLightDir(wPos.xyz));

                    // apply normal offset bias (inset position along the normal)
                    // bias needs to be scaled by sine between normal and light direction
                    // (http://the-witness.net/news/2013/09/shadow-mapping-summary-part-1/)
                    //
                    // unity_LightShadowBias.z contains user-specified normal offset amount
                    // scaled by world space texel size.

                    float shadowCos = dot(wNormal, wLight);
                    float shadowSine = sqrt(1 - shadowCos * shadowCos);
                    float normalBias = unity_LightShadowBias.z * shadowSine;

                    wPos.xyz -= wNormal * normalBias;
                }

                return mul(UNITY_MATRIX_VP, wPos);
            }

            void vertShadowCaster_ShakeBone(VertexInput v,
            #if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(UNITY_STANDARD_USE_SHADOW_UVS)
                out VertexOutputShadowCaster o,
            #endif
                out float4 opos : SV_POSITION)
            {
                //	TRANSFER_SHADOW_CASTER_NOPOS(o, opos)
                opos = Cus_UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
                opos = Cus_UnityApplyLinearShadowBias(opos);


            #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
                    o.tex = TRANSFORM_TEX(v.uv0, _MainTex);
            #endif

            #if defined(Dithered)
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.screenPos = ComputeScreenPos(opos);
            #endif
            }


            ENDCG
        }
    }
}
