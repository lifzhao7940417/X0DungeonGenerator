Shader "X0/Environment/Floor/WaterDeepth"
{
    Properties
    {
        _GrassColor("Panel Grass Color",Color) = (0,1,0,1)
        _Grass2Color("Panel Grass2 Color",Color) = (0,0.5,0,1)
        _Grass3Color("Panel Grass3 Color",Color) = (0.5,0.5,0.5,1)
        _GroundColor2("Ground Depth Color",Color) = (1,1,1,1)
        _FloorNoiseTex ("Grass Blend Map(RG)", 2D) = "white" {}
        _GrassDetailMapTilling("Grass TriplanarDetail Tilling",Range(0.0001,0.1)) = 0.01
        _GrassDetailMap("Grass TriplanarDetail Map", 2D) = "white" {}

        [Space(50)]
        _DetailIntensity("GroundColorBlendGrass", Range(0 , 1)) = 1
        _DetailMap("Ground Detail Map", 2D) = "bump" {}
        _DetailMapTilling("Ground Detail Tilling",Range(0.0001,0.1)) = 0.01
        _LayerThreshold("Layer Threshold&Power", Range(0 , 50)) = 50

        [Space(50)]
        [Toggle(_WATER_ON)] _WaterOn("Water On", Float) = 0
        [Toggle(_WATER_MASK_ON)] _WaterMaskOn("WaterMaskOn", Float) = 0
        _WaterMask("WaterMask", 2D) = "white" {}
        _WaterLine("Water Line",Range(-1,0.05))=0
        _WaterColor("Water Color",Color) = (0,1,0,1)
        _WaterNoiseMap("Water Noise Map", 2D) = "white" {}
        _WaterNoiseValue("Water Noise Value",Range(0,1))=1
        _WaterNoiseSpeed("Water Noise Speed",Range(0,1)) = 1

        _WaterFormLine("Water Form Line",Range(0,1)) =0.03

        [Space(50)]
        _HeightFogEnd("HeightFogEnd",Float)=1
        _HeightFogStart("HeightFogStart",Float)=1
        _HeightFogColor("HeightFogColor",Color) = (0,0,0,1)
        [HDR]_EmissionColor("Emission",Color) = (0,0,0,1)
    }

    SubShader
    {
       Tags { "RenderType" = "Opaque" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase  

            #pragma shader_feature_local _WATER_ON
            #pragma shader_feature_local _WATER_MASK_ON

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
             #include "X0SceneParameter.hlsl"

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertexOS : TEXCOORD1;
                SHADOW_COORDS(2)
                float4 tSpace0 : TEXCOORD3;
                float4 tSpace1 : TEXCOORD4;
                float4 tSpace2 : TEXCOORD5;
                float4 screenPos : TEXCOORD6;
                float4 pos : SV_POSITION;
            };

            sampler2D _FloorNoiseTex, _DetailMap, _SecondAlbedo, _GrassDetailMap, _WaterNoiseMap, _WaterMask;
            float4 _FloorNoiseTex_ST, _WaterNoiseMap_ST;
            float4  _GroundColor2, _GrassColor,_Grass2Color, _Grass3Color,_WaterColor;

            float _LayerThreshold, _DetailIntensity, _DetailMapTilling, _GrassDetailMapTilling,_Tiling2;
            float _WaterNoiseValue, _WaterNoiseSpeed , _WaterLine, _WaterFormLine;

            float _HeightFogEnd, _HeightFogStart;
            float4 _HeightFogColor, _EmissionColor;

            v2f vert (appdata_full v)
            {
                v2f o;
                o.vertexOS = v.vertex;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord;
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaterNoiseMap) + _Time.y * _WindAllCtrl* _WaterNoiseSpeed;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;

                o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                o.screenPos = ComputeScreenPos(o.pos);

                TRANSFER_SHADOW(o)    
                return o;
            }

            inline float4 TriplanarSamplingY(sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale)
            {
                float3 projNormal = (pow(abs(worldNormal), falloff));
                projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
                float3 nsign = sign(worldNormal);
               
                half4 yNorm;
                yNorm = tex2D(topTexMap, tiling * worldPos.xz * float2(nsign.y, 1.0));
                return yNorm * projNormal.y;

                //half4 xNorm;
                //xNorm = tex2D(topTexMap, tiling * worldPos.zy * float2(nsign.x, 1.0));
                //half4 zNorm;
                //zNorm = tex2D(topTexMap, tiling * worldPos.xy * float2(-nsign.z, 1.0));
                //return yNorm * projNormal.y +xNorm * projNormal.x + zNorm * projNormal.z;
            }

            float GetNormalYMask(float3 worldNormal)
            {
                float3 projNormal = abs(worldNormal);
                projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
                return projNormal.y;
            }

            inline float4 TriplanarSampling(sampler2D topTexMap, float3 worldPos, float3 worldNormal, float2 offset, float2 speed, float2 tiling)
            {
                float3 projNormal = abs(worldNormal);
                projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
                float3 nsign = sign(worldNormal);
                half4 yNorm = tex2D(topTexMap, (offset + speed * _Time.y) + tiling * worldPos.xz * float2(nsign.y, 1.0));
                return yNorm * projNormal.y ;
            }


            float3 GetWorldVector(v2f IN,float3 InVector)
            {
                return half3(dot(IN.tSpace0.xyz, InVector), dot(IN.tSpace1.xyz, InVector), dot(IN.tSpace2.xyz, InVector));
            }

            float2 GetWorldNormalYUV(float3 worldPos, float3 worldNormal)
            {
                float3 projNormal = abs(worldNormal);
                projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
                float3 nsign = sign(worldNormal);

                return float2(worldPos.xz * float2(nsign.y, 1.0));
            }


            float3 GetHighFogColor(float3 inColor,float posWSY)
            {
                //Polybox Calculate heightFog
                half heightFog = saturate((_HeightFogEnd - posWSY) / (_HeightFogEnd - _HeightFogStart));
                heightFog = pow(heightFog, 2.2);
                half4 heightFogColor = _HeightFogColor;
                return lerp(inColor, heightFogColor.rgb, heightFog);
            }


            fixed4 frag(v2f i) : SV_Target
            {
                #ifndef USING_DIRECTIONAL_LIGHT
                        fixed3 lightWS = normalize(UnityWorldSpaceLightDir(worldPos));
                #else
                        fixed3 lightWS = _WorldSpaceLightPos0.xyz;
                #endif

                float Alpha = 1;
                float2 uv = i.uv;
                float3 posWS = float3(i.tSpace0.w, i.tSpace1.w, i.tSpace2.w);;
                float3 normalWS = GetWorldVector(i, float3(0, 0, 1));
                float3 tangentWS = GetWorldVector(i, float3(1, 0, 0));
                float3 bitangentWS = GetWorldVector(i, float3(0, 1, 0));


                float3 cloud = GetCloud(normalWS,posWS,0).rgb ;
                fixed shadow = SHADOW_ATTENUATION(i) ;
                float3 EnvDark = min(cloud * 0.5 + 0.85, shadow * 0.6 + 0.3);

                fixed4 FloorNoise = tex2D(_FloorNoiseTex, i.uv.xy * _FloorNoiseTex_ST.xy + _FloorNoiseTex_ST.zw);
                float4 Grass12Blend = lerp(_GrassColor,_Grass2Color, FloorNoise.r);
                float GrassNoise = smoothstep(0.4,0.66,max(FloorNoise.rrrr, 1 - FloorNoise.gggg));
                float GrassDetail = TriplanarSamplingY(_GrassDetailMap, posWS, normalWS, 1.0, float2(_GrassDetailMapTilling, _GrassDetailMapTilling), 1.0).r;

                float4 GrassColor = lerp(_Grass3Color, Grass12Blend, GrassNoise);
                GrassColor = lerp(GrassColor, _Grass3Color, smoothstep(0.4, 0.66, max(GrassDetail.r, 1 - FloorNoise.a)));
                GrassColor *= lerp(GrassDetail, GrassColor,GrassDetail);

                float4 param = float4(_DetailMapTilling, _DetailIntensity, 0, _LayerThreshold);
                float PanelBlendAlpha = GetNormalYMask(normalWS);

                GrassColor = lerp(_GroundColor2, GrassColor, PanelBlendAlpha);
                float3 Albedo = _MainLightColor.rgb * GrassColor * EnvDark;

                Albedo = GetHighFogColor(Albedo + _EmissionColor.rgb, posWS.y);


                #if defined(_WATER_ON)

                    ///Water
                    float4 WaterNoise = tex2D(_WaterNoiseMap, i.uv.zw);
                    float NormalYMask = GetNormalYMask(normalWS);

                    #if defined(_WATER_MASK_ON)
                        Alpha = tex2D(_WaterMask, i.uv.xy).a;
                        float waterRange = smoothstep(0, 1, _WaterLine - posWS.y + 0.45);
                        waterRange = waterRange * smoothstep(0, 1, 1 - waterRange);
                        waterRange = pow(waterRange, 0.7)* Alpha;

                        //WaterForm
                        float up = step(0, _WaterLine + 0.35 - posWS.y);
                        float down = step(0, _WaterLine + 0.35 - (WaterNoise.r * _WaterFormLine) - posWS.y);
                        float WaterForm = WaterNoise.r * (up - down);

                        float2 WNoiseuv = WaterNoise.rr;
                        float3 RelfectColor = tex2D(_ReflectionTex, (i.screenPos.xy + WNoiseuv * _WaterNoiseValue) / i.screenPos.w).rgb;
                        float3 cloudInWater = lerp(saturate(0.3 - cloud * 0.6), _WaterColor.rgb, 0.3);


                        float3 waterColor = NormalYMask * _MainLightColor.rgb * (WaterForm + cloudInWater + _WaterColor.rgb + RelfectColor);
                        Albedo = lerp(lerp(Albedo, _WaterColor.rgb, waterRange), waterColor, waterRange);
                    #else
                        float waterRange = smoothstep(0, 1, _WaterLine - posWS.y + 0.45);
                        waterRange = waterRange * smoothstep(0, 1, 1 - waterRange);
                        waterRange = pow(waterRange, 0.7);

                        //WaterForm
                        float up = step(0, _WaterLine + 0.35 - posWS.y);
                        float down = step(0, _WaterLine + 0.35 - (WaterNoise.r * _WaterFormLine) - posWS.y);
                        float WaterForm = WaterNoise.r * (up - down);

                        float2 WNoiseuv = WaterNoise.rr;
                        float3 RelfectColor = tex2D(_ReflectionTex, (i.screenPos.xy + WNoiseuv * _WaterNoiseValue) / i.screenPos.w).rgb;
                        float3 cloudInWater = lerp(saturate(0.3 - cloud * 0.6), _WaterColor.rgb, 0.3);

                        float3 waterColor = NormalYMask * _MainLightColor.rgb * (WaterForm + cloudInWater + _WaterColor.rgb + RelfectColor);
                        Albedo = lerp(lerp(Albedo, _WaterColor.rgb, waterRange), waterColor, waterRange);
                    #endif
                #endif

                return float4(Albedo, Alpha);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
