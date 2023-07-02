Shader "X0/Environment/Stone"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Main Color", Color) = (1,1,1,1)
        _2ndColor("Color", Color) = (1,1,1,1)

        [Space(10)]
        _LayerNoiseMap("LayerNoiseMap", 2D) = "bump" {}
        _LayerNoisePower("Layer Noise Power", Range(0 , 1)) = 1
        _LayerNoiseTiling("Layer Noise Tiling", Float) = 1

        _LayerPower("Layer Power", Range(0 , 1)) = 0.5
        _LayerThreshold("Layer Threshold", Range(0 , 50)) = 50
        _LayerPosition("Layer Position", Float) = 0
        _LayerContrast("Layer Contrast", Float) = 0

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

                #pragma shader_feature_local _VERTEXCOLORCHANNEL_R _VERTEXCOLORCHANNEL_G _VERTEXCOLORCHANNEL_B _VERTEXCOLORCHANNEL_A
                #pragma shader_feature_local _SEEVERTEXCOLORS_ON

                struct v2f
                {
                    float4 uv : TEXCOORD0;
                    float4 vertex_world : TEXCOORD1;
                    SHADOW_COORDS(2)
                    float4 tSpace0 : TEXCOORD3;
                    float4 tSpace1 : TEXCOORD4;
                    float4 tSpace2 : TEXCOORD5;
                    half4 color : COLOR0;
                    float4 pos : SV_POSITION;
                };

                sampler2D _MainTex;
                uniform float4 _MainTex_ST;

                uniform sampler2D _LayerNoiseMap;
                uniform float _LayerNoiseTiling;
                uniform float _LayerNoisePower;
                uniform float _LayerContrast;
                uniform float _LayerPosition;
                uniform float _LayerPower;
                uniform float _LayerThreshold;

                uniform float4 _Color;
                uniform float4 _2ndColor;

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

                    o.color = v.color;
                    TRANSFER_SHADOW(o)
                    return o;
                }


                inline float3 TriplanarSamplingDetail(sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index)
                {
                    float3 projNormal = (pow(abs(worldNormal), falloff));
                    projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
                    float3 nsign = sign(worldNormal);
                    half4 xNorm; half4 yNorm; half4 zNorm;
                    xNorm = tex2D(topTexMap, tiling * worldPos.zy * float2(nsign.x, 1.0));
                    yNorm = tex2D(topTexMap, tiling * worldPos.xz * float2(nsign.y, 1.0));
                    zNorm = tex2D(topTexMap, tiling * worldPos.xy * float2(-nsign.z, 1.0));
                    xNorm.xyz = half3(UnpackScaleNormal(xNorm, normalScale.y).xy * float2(nsign.x, 1.0) + worldNormal.zy, worldNormal.x).zyx;
                    yNorm.xyz = half3(UnpackScaleNormal(yNorm, normalScale.x).xy * float2(nsign.y, 1.0) + worldNormal.xz, worldNormal.y).xzy;
                    zNorm.xyz = half3(UnpackScaleNormal(zNorm, normalScale.y).xy * float2(-nsign.z, 1.0) + worldNormal.xy, worldNormal.z).xyz;
                    return normalize(xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + zNorm.xyz * projNormal.z);
                }
                inline float4 TriplanarSampling(sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index)
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


                float3 GetDetailNormal0(float3 worldNormal, float3 worldTangent, float3 worldBitangent, float3 worldPos)
                {
                    float2 uv_tilling1 = (float2(_LayerNoiseTiling, _LayerNoiseTiling));
                    float3x3 worldToTangent = float3x3(worldTangent, worldBitangent, worldNormal);

                    float3 triplanarDetailNormal0 = TriplanarSamplingDetail(_LayerNoiseMap, worldPos, worldNormal, 1.0, uv_tilling1, _LayerNoisePower, 0);
                    float3 tanTriplanarDetailNormal0 = mul(worldToTangent, triplanarDetailNormal0);
                    return tanTriplanarDetailNormal0;
                }

                float3 GetWorldVector(v2f IN,float3 InVector)
                {
                    return half3(dot(IN.tSpace0.xyz, InVector), dot(IN.tSpace1.xyz, InVector), dot(IN.tSpace2.xyz, InVector));
                }

                float4 GetBlendAlpha(v2f IN, float2 uv_texcoord, float3 tanTriplanarDetailNormal0,float3 worldNormal, float3 worldTangent, float3 worldBitangent,float3 worldPos, float4 vertexColor)
                {
                    float3x3 worldToTangent = float3x3(worldTangent, worldBitangent, worldNormal);

                    float4 DetailNormal0YWS = ((GetWorldVector(IN , tanTriplanarDetailNormal0)).y).xxxx;
                    float4 Layer1 = (pow(vertexColor.r, _LayerPosition)).xxxx;
                    float4 Layer1Clamp = clamp(CalculateContrast(_LayerContrast, Layer1), float4(0, 0, 0, 0), float4(1, 1, 1, 0));
                    float4 LayerPower = ((1.0 - _LayerPower)).xxxx;
                    float4 LayerThreshold = ((0.001 + (_LayerThreshold - 0.0) * (1.0 - 0.001) / (1.0 - 0.0))).xxxx;
                    float4 BlendAlpha = pow(saturate(DetailNormal0YWS + _LayerPower), LayerThreshold);

                    return BlendAlpha;
                }

                float4 GetAlbedo(v2f IN, float4 BlendAlpha, float2 uv_texcoord, float3 worldPos, float4 vertexColor)
                {
                    float2 uv_tilling1 = (float2(_LayerNoiseTiling, _LayerNoiseTiling));

                    float3 worldNormal = GetWorldVector(IN, float3(0, 0, 1));
                    float2 uv_MainTex = uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
                    float4 Triplanar = TriplanarSampling(_MainTex, worldPos, worldNormal, 1.0, uv_tilling1, 1.0, 0);
                    float4 MainColor = _Color * tex2D(_MainTex, uv_MainTex);
                    float4 SecondColor = _2ndColor * Triplanar;
                    float4 BaseColor = lerp(MainColor, SecondColor, BlendAlpha);
                    return BaseColor;
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
                    float3 worldTangent = GetWorldVector(i, float3(1, 0, 0));
                    float3 worldBitangent = GetWorldVector(i, float3(0, 1, 0));
                    float2 uv = i.uv;
                    float4 vertexColor = i.color;

                    fixed shadow = SHADOW_ATTENUATION(i);
                    float3 cloud = GetCloud(normalWS, posWS,0).rgb;
                    float3 envDark = min(shadow, cloud) * 0.5 + 0.5;

                    float3 tanTriplanarDetailNormal0 = GetDetailNormal0(normalWS, worldTangent, worldBitangent, posWS);

                    float4 BlendAlpha = GetBlendAlpha(i,uv, tanTriplanarDetailNormal0, normalWS, worldTangent, worldBitangent, posWS, vertexColor);

                    float3 Albedo = GetAlbedo(i, BlendAlpha, uv, posWS, vertexColor);

                    Albedo = Albedo * _MainLightColor * envDark;

                    return float4(Albedo,1);
                }

                ENDCG
            }
        }

            FallBack "Specular"
}
