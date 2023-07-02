Shader "X0/Item/2D"
{
    Properties
    {
        _AlphaClip("AlphaClip",Range(0,1.1))=0.5
        _BaseColor("Color",Color)=(1,1,1,1)
        _MainTex("Texture", 2D) = "white" {}

        _TexRowColumn("TexRowColumn",vector) = (1,1,1,1)
        _TexIndex("TexIndex",float) = 1
        _ZOffset("ZOffset",float) = 0
    }

    SubShader
    {
       Tags{ "LightMode" = "ForwardBase"}

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
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(int, _TexIndex)
                UNITY_DEFINE_INSTANCED_PROP(float, _ZOffset)
            UNITY_INSTANCING_BUFFER_END(Props)

            float _AlphaClip;
            int _TexGroup;
            float4 _TexRowColumn;

            v2f vert(a2v v)
            {
                v2f o=(v2f)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                v.vertex.z += UNITY_ACCESS_INSTANCED_PROP(Props, _ZOffset); ;
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
            half2 GetUV(half2 baseuv, half index, half inRow, half inColumn, half2 inUVOffset)
            {
                half2 uv = baseuv.xy / half2(inRow, inColumn) + half2(inUVOffset.x, inUVOffset.y);

                float Column = fmod((index) / inColumn, inColumn) - floor((index) / inColumn);
                float Row = floor((index) / inRow) / inRow;

                uv = uv + half2(Row, Column);
                return uv;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float3 worldPos = float3(i.t2wSpaceData[0].w, i.t2wSpaceData[1].w, i.t2wSpaceData[2].w);
                //half3 worldnormal = CustomPerPixelWorldNormal(i.uv, i.t2wSpaceData);
                //half3 worldlightdir = WorldLightDir(worldPos);

                int texindex = UNITY_ACCESS_INSTANCED_PROP(Props, _TexIndex);

                half2 uv = GetUvFormIndex(i.uv,texindex, _TexRowColumn.x, _TexRowColumn.y);
                fixed4 col = tex2D(_MainTex, uv);
                half Alpha = max(max(col.r, col.g), col.b);
                clip(Alpha - _AlphaClip);

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                float3 cloud = 1;// GetCloud(worldnormal, worldPos, 0).rgb;
                float3 EnvDark = min(cloud * 0.7 + 0.2, atten * 0.8 + 0.1);

                half3 BaseColor = UNITY_ACCESS_INSTANCED_PROP(Props, _BaseColor).rgb;
                float3 FinallColor = EnvDark * col.rgb * BaseColor;

                return float4(FinallColor,1);
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

            //float4 _MainTex_ST;
            float4 _TexRowColumn;
            //sampler3D _DitherMaskLOD;//Unity���õ���ά��������

            half2 GetUV(half2 baseuv, half index, half inRow, half inColumn, half2 inUVOffset)
            {
                half2 uv = baseuv.xy / half2(inRow, inColumn) + half2(inUVOffset.x, inUVOffset.y);

                float Column = fmod((index) / inColumn, inColumn) - floor((index) / inColumn);
                float Row = floor((index) / inRow) / inRow;

                uv = uv + half2(Row,Column );
                return uv;
            }

            v2f vert(a2v v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                //���ڱ��涥�㵽��Դ������
                o.vec = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;
                //�ڲü��ռ��ж�����z����Ӧ�����ƫ��
                o.pos = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(v.vertex,v.normal));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            //sampler2D _MainTex;
            fixed _AlphaClip;
            fixed4 _BaseColor;
            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(int, _TexIndex)
            UNITY_INSTANCING_BUFFER_END(Props)

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                int texindex = UNITY_ACCESS_INSTANCED_PROP(Props, _TexIndex);
                //hard shadow:�ο��������Ӱ
                 half2 uv = GetUvFormIndex(i.uv, texindex, _TexRowColumn.x, _TexRowColumn.y);
                fixed4 texcol = tex2D(_MainTex, uv);
                float alpha  = max(max(texcol.r, texcol.g), texcol.b);
                clip(alpha - _AlphaClip);

                //soft shadow(fade shadow):��͸���������Ӱ,��Ӿ���Ӱ����˸
                //float dither = tex3D(_DitherMaskLOD, float3((i.pos.xy) * 0.5, alpha )).a;
                //clip(dither - _AlphaClip);

                //�������
                return UnityEncodeCubeShadowDepth((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
            }
            ENDHLSL
        }
    }
}