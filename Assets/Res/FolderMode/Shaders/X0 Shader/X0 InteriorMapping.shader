Shader "X0/Environment/Floor/InteriorMapping"
{
    Properties
    {
        _Deepth("Deepth",Range(0.01,10)) = 1
        _FloorColor("FloorColor",Color) = (1,1,1,1)
        _EdgeFloorColorDeepth("EdgeFloorColorDeepth",Range(0,1)) = 0.4
        _CloudInWaterInstensity("CloudInWaterInstensity",Range(0,2)) = 1.4

        _RoomThings("RoomThings",2D) = "black" {}
        _inScale("RoomScale",Range(0,3)) = 1.5
        _inPosY("RoomDeepth",Range(0,1)) = 0.15
        _inPosX("RoomPosX",Range(-1,1)) = 0
        _inPosZ("RoomPosZ",Range(-1,1)) = 0

        _WaterColor("WaterColor",Color) = (0,0,1,1)
        _WaterTransparent("WaterTransparent",Range(0,1)) = 0.5
        _WaterNoiseMap("Water Noise Map", 2D) = "white" {}
        _WaterNoiseValue("Water Noise Value",Range(0,1)) = 1
        _WaterNoiseSpeed("Water Noise Speed",Range(0,1)) = 1
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            Blend One OneMinusSrcAlpha
            LOD 100

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #pragma multi_compile_instancing
                #include "UnityCG.cginc"
                #include "Lighting.cginc"
                #include "AutoLight.cginc"
                 #include "X0SceneParameter.hlsl"
                #pragma target 3.0


                #define mat3 float3x3
                #define vec3 float3
                #define vec4 float4
                #define vec2 float2
                #define mix lerp
                # define M_PI_2 1.57079632679489661923 /* pi/2 */
                #define PI 3.1415926535
                #define point float3
                #define output out

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float4 uv : TEXCOORD0;
                    float4 uv2:TEXCOORD1;
                };

                struct v2f
                {
                    float4 uv : TEXCOORD0;
                    float4 vertexOS:TEXCOORD1;
                    float4 posWorld : TEXCOORD2;

                    float3 tangentDir : TEXCOORD3;
                    float3 bitangentDir : TEXCOORD4;
                    float3 normalDir : TEXCOORD5;

                    float4 screenPos : TEXCOORD6;

                    float4 vertex : SV_POSITION;
                };

                float _Deepth;
                float4 _RightPos;
                float _RightRotation;
                float4 _RightScale;
                float _CloudInWaterInstensity, _EdgeFloorColorDeepth, _WaterTransparent;
                float _WaterNoiseValue, _WaterNoiseSpeed;


                half _inScale;
                half _inPosY;
                half _inPosX;
                half _inPosZ;

                sampler2D _WaterNoiseMap;
                float4 _WaterNoiseMap_ST;


                sampler2D _RoomThings;

                sampler2D _RoomThings3;
                uniform float4 _RoomThings3_ST;

                float4 _FloorColor, _WaterColor;



                float3 GetGeometryInComing(v2f i)
                {
                    float3 viewWS = (i.posWorld.rgb - _WorldSpaceCameraPos);
                    return  viewWS;
                }

                float3 TransformWorld2Tangent(float3 inNormalWS,float3 inViewWS,v2f i)
                {
                    return  float3(dot(inViewWS, i.tangentDir), dot(inViewWS, i.bitangentDir), dot(inViewWS, inNormalWS));
                }

                float3 TransformU2B(float3 inValue)
                {
                    return float3(inValue.x, inValue.z, inValue.y);
                }

                float SteppedLinear(float InComingTSRevert)
                {
                    return smoothstep(0, 0, InComingTSRevert);
                }

                void map_range_stepped(float value, float fromMin, float fromMax, float toMin, float toMax, float steps, out float result)
                {
                    if (fromMax != fromMin)
                    {
                        float factor = (value - fromMin) / (fromMax - fromMin);
                        factor = (steps > 0.0) ? floor(factor * (steps + 1.0)) / steps : 0.0;
                        result = toMin + factor * (toMax - toMin);
                    }
                    else
                    {
                        result = 0.0;
                    }
                }

                //inMask--理解为已知的深度量（标量）(源于视线方向或者是给定的)
                //inObjectSep-理解为深度的起始标量(标量) (源于UV)
                //inInComingSep--理解为已知的视线深度的总长度 (标量) (源于视线方向)
                //(inMask - inObjectSep)--理解深度的实际距离 (标量)
                //(inMask - inObjectSep) / inInComingSep--理解每单位视线方向上深度距离  (标量)
                //(inMask - inObjectSep) / inInComingSep * inInComing--理解为实际视线方向提供了多少深度距离 (矢量)
                //(inMask - inObjectSep) / inInComingSep * inInComing + inObject --理解为视线方向的深度提供了多少uv的偏移 (inObject为偏移起点)
                float3 GetUVOffset(float3 inViewTS, float3 inUVTS, float inViewOffset, float inUVStart, float inViewOffsetValue)
                {
                    return  (inViewOffset - inUVStart) / inViewOffsetValue * inViewTS + inUVTS;
                }

                float LessThen(float A,float B)
                {
                    return clamp(ceil(A - B),0,1);
                }


                point safe_divide(point a, point b)
                {
                    return point((b[0] != 0.0) ? a[0] / b[0] : 0.0,
                        (b[1] != 0.0) ? a[1] / b[1] : 0.0,
                        (b[2] != 0.0) ? a[2] / b[2] : 0.0);
                }

                float3x3 euler_to_mat(float3 euler)
                {
                    float cx = cos(euler[0]);
                    float cy = cos(euler[1]);
                    float cz = cos(euler[2]);
                    float sx = sin(euler[0]);
                    float sy = sin(euler[1]);
                    float sz = sin(euler[2]);

                    float3x3 mat = (float3x3)(1.0);
                    mat[0][0] = cy * cz;
                    mat[0][1] = cy * sz;
                    mat[0][2] = -sy;

                    mat[1][0] = sy * sx * cz - cx * sz;
                    mat[1][1] = sy * sx * sz + cx * cz;
                    mat[1][2] = cy * sx;

                    mat[2][0] = sy * cx * cz + sx * sz;
                    mat[2][1] = sy * cx * sz - sx * cz;
                    mat[2][2] = cy * cx;
                    return mat;
                }


                void node_mapping_point(
                    float3 VectorIn,
                    float3 Location,
                    float3 Rotation,
                    float3 Scale,
                    out float3 result)
                {
                    //point :  transform(euler_to_mat(Rotation), (VectorIn * Scale)) + Location;
                    result = mul(euler_to_mat(Rotation), (VectorIn * Scale)) + Location;

                    //texture : safe_divide(transform(transpose(euler_to_mat(Rotation)), (VectorIn - Location)),Scale);
                    //vector :  transform(euler_to_mat(Rotation), (VectorIn * Scale));
                    //normal : normalize((vector)transform(euler_to_mat(Rotation), safe_divide(VectorIn, Scale)));
                }

                float3 snap(float3 a, float3 b)
                {
                    return floor(safe_divide(a, b)) * b;
                }

                void node_mapping_texture
                (
                    float3 VectorIn,
                    float3 Location,
                    float3 Rotation,
                    float3 Scale,
                    out float3 result)
                {
                    result = safe_divide(mul(transpose(euler_to_mat(Rotation)), (VectorIn - Location)), Scale);
                }

                void GetTextureMapping
                (
                    float3 VectorIn,
                    float3 Rotation,
                    float locX,
                    float locY,
                    float scaleX,
                    float scaleY,
                    out float3 result
                )
                {
                    result = float3(0, 0, 0);

                    float3 CombineA = float3(locX, locY, 0);
                    float3 CombineB = float3(scaleX, scaleY, 0);
                    node_mapping_texture(VectorIn, CombineA, Rotation, CombineB, result);

                }

                void GetTextureVector(
                    float3 RightColor,
                    float3 Deepth,
                    float RepeatOrStretch,
                    out float3 result)
                {
                    result = float3(0, 0, 0);

                    float3 scale = lerp(float3(1,1,1), Deepth.xxx, RepeatOrStretch);
                    scale.y = 1;
                    scale.z = 1;

                    node_mapping_texture(RightColor, (float3)0, (float3)0, scale, result);
                }

                //这是省略计算mapping的建议版本
                void GetRightColor(sampler2D InteriorTexR ,float3 HorizontalOffset, float HFactor, float3 Pos, float3 Rot, float3 Scale, out float3 Wall)
                {
                    Wall = float3(0, 0, 0);
                    float3 Mapping;

                    node_mapping_point(HorizontalOffset, Pos, Rot, Scale, Mapping);

                    float3 uvFactor = lerp(float3(0, 0, 0), Mapping, HFactor);

                    //float3 texVector;  GetTextureVector(uvFactor, _Deepth.xxx, 0, texVector);
                    //float3 texMapping;  GetTextureMapping(uvFactor, float3(0, 0, M_PI_2), 1, 1, 1, 1, texMapping);

                    Wall =  tex2D(InteriorTexR, uvFactor);
                }

                float3 GetDeepthDir(float3 HorizontalOffset, float HFactor, float3 Pos, float3 Rot, float3 Scale)
                {

                    float3 Mapping;

                    node_mapping_point(HorizontalOffset, Pos, Rot, Scale, Mapping);

                    return lerp(float3(0, 0, 0), Mapping, HFactor);
                }

                void GetLeftColor(sampler2D InteriorTexL,float3 HorizontalOffset, float HFactor, float3 Pos, float3 Rot, float3 Scale, out float3 Wall)
                {
                    Wall = float3(0, 0, 0);
                    float3 Mapping;
                    node_mapping_point(HorizontalOffset, Pos, Rot, Scale, Mapping);

                    float3 Color = lerp(Mapping, float3(0, 0, 0), HFactor);

                    float3 texVector;  GetTextureVector(Color, _Deepth.xxx, 0, texVector);
                    float3 texMapping;  GetTextureMapping(texVector, float3(0, 0, M_PI_2), 1, 1, 1, 1, texMapping);

                    Wall = tex2D(InteriorTexL, texMapping);
                }

                void GetBackColor(sampler2D InteriorTexB,float3 DeepthOffset, float3 Pos, float3 Rot, float3 Scale, out float3 Wall)
                {
                    Wall = float3(0, 0, 0);
                    float3 Mapping;
                    node_mapping_point(DeepthOffset, Pos, Rot, Scale, Mapping);

                    Wall = tex2D(InteriorTexB, Mapping);
                }

                void GetFloorColor(sampler2D InteriorTexF,float3 Offset, float Factor, float3 Pos, float3 Rot, float3 Scale, out float3 Wall)
                {
                    Wall = float3(0, 0, 0);
                    float3 Mapping;
                    node_mapping_point(Offset, Pos, Rot, Scale, Mapping);

                    float3 uvFactor = lerp(Mapping, float3(0, 0, 0), Factor);

                    float3 texVector;  GetTextureVector(uvFactor, _Deepth.xxx, 0, texVector);
                    float3 texMapping;  GetTextureMapping(texVector, float3(0, 0, 0), 1, 1, 1, 1, texMapping);

                    Wall = tex2D(InteriorTexF, texMapping);
                }

                void GetCeilingColor(sampler2D InteriorTexC,float3 Offset, float Factor, float3 Pos, float3 Rot, float3 Scale, out float3 Wall)
                {
                    Wall = float3(0, 0, 0);
                    float3 Mapping;
                    node_mapping_point(Offset, Pos, Rot, Scale, Mapping);

                    float3 Color = lerp( float3(0, 0, 0), Mapping, Factor);

                    float3 texVector;  GetTextureVector(Color, _Deepth.xxx, 0, texVector);
                    float3 texMapping;  GetTextureMapping(texVector, float3(0, 0, 0), 1, 1, 1, 1, texMapping);

                    Wall = tex2D(InteriorTexC, texMapping);
                }




                float4 GetRoomThings(sampler2D Texture, float4 RoomThingsST ,float3 InComingTSRevert, float3 uvPart)
                {
                    float3 DeepthOffset = GetUVOffset(InComingTSRevert, uvPart, RoomThingsST.y, uvPart.y, InComingTSRevert.y);

                    float3 Mapping;

                    float3 Pos = float3(-RoomThingsST.z +0.5, 0.5- RoomThingsST.w, 0);
                    float3 Rot = float3(degrees(90), 0, 0);
                    float3 Scale =float3(1/ RoomThingsST.x, 0, -1/ RoomThingsST.x);

                    node_mapping_point(DeepthOffset, Pos, Rot, Scale, Mapping);

                    return tex2D(Texture, Mapping);
                }

                //GetRightColor(_InteriorTexR,HorizontalOffset, HFactor, float3(-_InteriorTexR_ST.w - 0.5, _InteriorTexR_ST.z, 0), float3(0, degrees(90), 0), float3(0, _InteriorTexR_ST.x, _InteriorTexR_ST.y), RightWall);
                //GetLeftColor(_InteriorTexL,HorizontalOffset, HFactor, float3(-_InteriorTexL_ST.w - 0.5, _InteriorTexL_ST.z, 0), float3(0, degrees(90), 0), float3(0, -_InteriorTexL_ST.x, _InteriorTexL_ST.y), LeftWall);
                //GetBackColor(_InteriorTexB,DeepthOffset,float3(-_InteriorTexB_ST.z - 0.5, -_InteriorTexB_ST.w - 0.5, 0),float3(degrees(90), degrees(0),0), float3(_InteriorTexB_ST.x, 0, -_InteriorTexB_ST.y),BackWall);
                //GetFloorColor(_InteriorTexF,VerticalOffset,VFactor, float3(-_InteriorTexF_ST.z - 0.5, -_InteriorTexF_ST.w , 0), float3(0, 0, 0), float3(_InteriorTexF_ST.x,  _InteriorTexF_ST.y, 0), FloorWall);
                //GetCeilingColor(_InteriorTexC,VerticalOffset, VFactor, float3(-_InteriorTexC_ST.z - 0.5, -_InteriorTexC_ST.w, 0), float3(0, 0, 0), float3(_InteriorTexC_ST.x, -_InteriorTexC_ST.y, 0), UpWall);

                //float4 RoomThings1 = GetRoomThings(_RoomThings,  _RoomThings_ST,InComingTSRevert, uvPart);
                //float4 RoomThings2 = GetRoomThings(_RoomThings2, _RoomThings2_ST, InComingTSRevert, uvPart);
                //float4 RoomThings3 = GetRoomThings(_RoomThings3, _RoomThings3_ST,InComingTSRevert, uvPart);


                //float3 ColorLR = lerp(LeftWall, RightWall, HFactor);
                //float3 ColorUD = lerp(FloorWall, UpWall, VFactor);
                //float3 ColorAround = lerp(ColorLR, ColorUD, Face01);
                //float3 ColorRoom = lerp(ColorAround, BackWall, Face02);

                //float3 FinallColor = lerp(ColorRoom, RoomThings1.rgb, RoomThings1.a);
                //FinallColor = lerp(FinallColor, RoomThings2.rgb, RoomThings2.a);
                //FinallColor = lerp(FinallColor, RoomThings3.rgb, RoomThings3.a);

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertexOS = v.vertex;

                    o.normalDir = UnityObjectToWorldNormal(v.normal);
                    o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                    o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);

                    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.screenPos = ComputeScreenPos(o.vertex);

                    o.uv.xy = v.uv.xy;
                    o.uv.zw = v.uv2.xy;
                        //v.uv.xy * _WaterNoiseMap_ST.xy + _WaterNoiseMap_ST.zw + _Time.y * _WindAllCtrl * _WaterNoiseSpeed;

                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float3 LeftWall = float3(1, 0, 0);
                    float3 RightWall = float3(0, 1, 0);
                    float3 UpWall = float3(0, 0, 1);
                    float3 FloorWall = float3(1, 1, 1);
                    float3 BackWall = float3(0.5, 0.5, 0.5);

                    float3 normalWS = normalize(i.normalDir);
                    float3 posWS = i.posWorld.xyz;

                    float3 InComingWS = GetGeometryInComing(i);
                    float3 InComingTS = TransformWorld2Tangent(normalWS,InComingWS, i);
                    float3 InComingTSRevert = normalize(InComingTS * -1);
                    InComingTSRevert = TransformU2B(InComingTSRevert);

                    //uv (0,1)=>(0.5,-0.5)
                    float3 uvPart = float3(1 - frac(i.uv.xy) * 2, 0) * 0.5f;
                    uvPart = TransformU2B(uvPart);

                    //maskZ(-1,1)=>(-0.5,0.5)
                    float maskZ;    map_range_stepped(InComingTSRevert.z, -1, 1, -0.5, 0.5, 1, maskZ);
                    float maskX;    map_range_stepped(InComingTSRevert.x, -1, 1, -0.5, 0.5, 1, maskX);

                    float VFactor = ceil(maskZ);
                    float HFactor = ceil(maskX);

                    //整体方向是放视线在TS空间下偏移UV
                    //maskZ会更具视线方向变化,所以要去和uvPart.z做差找到绝对距离
                    //总距离/时间(方向)    =   单位时间内的位移    (单位方向上的偏移)
                    //原始UV起点    +   单位方向偏移量*方向  =   最终uv偏移的量
                    //注:为什么uvPart.z? uvPart.z代表UV上的每一个z上的点都是一个z方向上的起点啊
                    float3 VerticalOffset = GetUVOffset(InComingTSRevert, uvPart, maskZ, uvPart.z, InComingTSRevert.z);
                    float3 HorizontalOffset = GetUVOffset(InComingTSRevert, uvPart, maskX, uvPart.x, InComingTSRevert.x);
                    float3 DeepthOffset = GetUVOffset(InComingTSRevert, uvPart, _Deepth, uvPart.y, InComingTSRevert.y);

                    float3 VerticalDirAbs = abs(VerticalOffset);
                    float3 HorizontalDirAbs = abs(HorizontalOffset);
                    float3 DeepthDirAbs = abs(DeepthOffset);

                    //这里为什么是.y啊,因为Face02算的是深度,深度是使用的坐标轴中的y (B3D坐标系)
                    float Face02 = LessThen(min(VerticalDirAbs.y, HorizontalDirAbs.y),DeepthDirAbs.y);
                    //ceil(0.5-(abs(VerticalOffset.x)).xxx)
                    float Face01 = LessThen(HorizontalDirAbs.x, VerticalDirAbs.x);

                    float WaterFac = Face02.x;
                    float  DeepthFloorFac = saturate(1 - Face02.x);

                    float3 DeepthFloorColor = DeepthFloorFac * _FloorColor.rgb;

                    float InteriorMask = tex2D(_RoomThings, i.uv).a;

                    float3 DeepthDir = min(VerticalDirAbs.y, HorizontalDirAbs.y);

                    //向下逐渐变深色的土壤颜色
                    DeepthFloorColor = DeepthFloorColor * pow(DeepthDir, _EdgeFloorColorDeepth);

                    float4 RoomThingsValue= float4(_inScale, _inPosY, _inPosX, _inPosZ);
                    float  WaterShadow = GetRoomThings(_RoomThings, RoomThingsValue +float4(0,0.02,0,0), InComingTSRevert, uvPart).x;
                    float WaterRange = GetRoomThings(_RoomThings, RoomThingsValue, InComingTSRevert, uvPart).x;
                    float4 WaterColor = _WaterColor * WaterRange;

                    float2 NoiseUV= i.uv.xy * _WaterNoiseMap_ST.xy + _WaterNoiseMap_ST.zw + _Time.y * _WindAllCtrl * _WaterNoiseSpeed;
                    float4 WaterNoise = tex2D(_WaterNoiseMap, NoiseUV);
                    float WaterForm =ceil(saturate(WaterNoise.r -0.6)* saturate(WaterRange - WaterShadow-0.5));

                    float2 WNoiseuv = WaterNoise.rr;
                    float3 cloud = GetCloud(normalWS, posWS, 0).rgb;
                    float3 RelfectColor = tex2D(_ReflectionTex, (i.screenPos.xy + WNoiseuv * _WaterNoiseValue) / i.screenPos.w).rgb;
                    float3 cloudInWater = lerp(_WaterColor.rgb, saturate(0.4f - cloud * 0.6), _CloudInWaterInstensity);
                    WaterColor.rgb = WaterColor.rgb *_MainLightColor.rgb * (WaterForm + cloudInWater + _WaterColor.rgb + RelfectColor);

                    //将中心水的区域透明化
                    InteriorMask = lerp(InteriorMask, _WaterTransparent * InteriorMask, WaterRange);

                    float3 InteriorColor = lerp(DeepthFloorColor, WaterColor.rgb, WaterRange);
                    float3 FinallColor = lerp(float3(0, 0, 0), InteriorColor, InteriorMask);


                    return float4(FinallColor, InteriorMask);
                }
                ENDCG
            }
        }
}
