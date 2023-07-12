Shader "X0/Tools/FenceIndexPartShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _IndexPartTexParamX("_IndexPartTexParamX",Range(-3,3)) = 0
        _IndexPartTexParamY("_IndexPartTexParamY",Range(-3,3)) = 1

         _A("0.15",Color) = (0.15,0.15,0.15,0.15)
        _B("0.3",Color) = (0.3,0.3,0.3,0.3)
        _C("0.45",Color) = (0.45,0.45,0.45,0.45)
        _D("0.6",Color) = (0.6,0.6,0.6,0.6)
        _E("0.75",Color) = (0.75,0.75,0.75,0.75)
        _F("0.9",Color) = (0.9,0.9,0.9,0.9)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float4 _A, _B, _C, _D, _E, _F;


            float _IndexPartTexParamY, _IndexPartTexParamX;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                fixed R = smoothstep(_IndexPartTexParamX, _IndexPartTexParamY, tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).r);
                fixed G = smoothstep(_IndexPartTexParamX, _IndexPartTexParamY, tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).g);
                fixed B = smoothstep(_IndexPartTexParamX, _IndexPartTexParamY, tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).b);

                if (R == G && G == B)
                {
                    col.rgb = _F.rgb;
                }
                else
                {
                    if (R > G)
                    {
                        if (G > B)
                        {
                            col.rgb = _A.rgb;
                        }
                        else
                        {
                            col.rgb = _B.rgb;
                        }
                    }
                    else if (G > B)
                    {
                        if (B > R)
                        {
                            col.rgb = _C.rgb;
                        }
                        else
                        {
                            col.rgb = _D.rgb;
                        }
                    }
                    else if (B > R)
                    {
                        if (G > R)
                        {
                            col.rgb = _E.rgb;
                        }
                        else
                        {
                            col.rgb = _F.rgb;
                        }
                    }
                }

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
