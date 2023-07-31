Shader "X0/Item/2D/LineRender"
{
    Properties
    {
        [HDR] _TintColor("Tint Color", Color) = (0.5,0.5,0.5,0.5)
        _AlphaClip("AlphaClip",Range(0,1))=0.5
        [NoScaleOffset]_MainTex("Texture", 2D) = "white" {}
        _ScaleY("ScaleY",float)=1
        _ScaleX("ScaleX",float)=1
        _OffsetY("OffsetY",float) = 0
        _OffsetX("OffsetX",float) = 0
        _TexIndex("TexIndex",float)=1
        _TexGroupY("TexGroup",float)=2
    }

    SubShader
    {
       Tags{ "LightMode" = "ForwardBase"}

       ZWrite on

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase 
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
             #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "BearCodingHelper.hlsl"
            #include "X0SceneParameter.hlsl"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 t2wSpaceData[3]	: TEXCOORD2; //2-4
                SHADOW_COORDS(5)
                float4 screenPos : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                
            };

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(int, _TexIndex)
                UNITY_DEFINE_INSTANCED_PROP(float, _ScaleX)
            UNITY_INSTANCING_BUFFER_END(Props)

            float _AlphaClip;
            int _TexGroupY;
            float4 _TintColor;
            half  _ScaleY, _OffsetY, _OffsetX;

            v2f vert(a2v v)
            {
                v2f o=(v2f)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                half ScaleX = UNITY_ACCESS_INSTANCED_PROP(Props, _ScaleX);

                o.uv.xy = v.uv * half2(ScaleX, _ScaleY) + half2(_OffsetX, _OffsetY);
                o.pos = UnityObjectToClipPos(v.vertex);

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

                float3x3	t2wMatrix = T2WMatrix(v.tangent, worldNormal);

                o.t2wSpaceData[0].xyz = t2wMatrix[0].xyz;
                o.t2wSpaceData[1].xyz = t2wMatrix[1].xyz;
                o.t2wSpaceData[2].xyz = t2wMatrix[2].xyz;

                o.t2wSpaceData[0].w = worldPos.x;
                o.t2wSpaceData[1].w = worldPos.y;
                o.t2wSpaceData[2].w = worldPos.z;

                o.screenPos = ComputeScreenPos(o.pos);
                TRANSFER_SHADOW(o);
                return o;
            }

            half2 GetUV(half2 baseuv,half index,half inGroup,half2 inUVOffset)
            {
                half2 uv = baseuv.xy / (half2(1, _TexGroupY))+half2(inUVOffset.x, inUVOffset.y);

                float lie = 0;// fmod((index) / inGroup, inGroup) - floor((index) / inGroup);
                float hang = floor((index) / inGroup) / inGroup;

                uv = uv + half2(lie, hang);
                return uv;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float3 worldPos = float3(i.t2wSpaceData[0].w, i.t2wSpaceData[1].w, i.t2wSpaceData[2].w);
                //half3 worldnormal = CustomPerPixelWorldNormal(i.uv, i.t2wSpaceData);
                //half3 worldlightdir = WorldLightDir(worldPos);

                int texindex = UNITY_ACCESS_INSTANCED_PROP(Props, _TexIndex);

                half2 uv = i.uv;// GetUV(i.uv, texindex, _TexGroupY, 0);
                fixed4 col = tex2D(_MainTex, uv);
                half Alpha = max(max(col.r, col.g), col.b);
                clip(Alpha - _AlphaClip);

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                float3 cloud = 1;// GetCloud(worldnormal, worldPos, 0).rgb;
                float3 EnvDark = min(cloud * 0.7 + 0.2, atten * 0.8 + 0.1);

                float3 FinallColor = EnvDark * col.rgb* _TintColor.rgb;

                return float4(FinallColor,1);
            }
            ENDHLSL
        }
    }
}
