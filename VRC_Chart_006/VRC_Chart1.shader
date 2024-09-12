Shader "VRC_Chart/Chart1"
{
    //グラフを描くシェーダー
    Properties
    {
        [Header(General)]
            _drawrange("drawrange",Vector) = (-1.0, 1.0, -1.0, 1.0)
            _BackGroundColor("BackGroundColor", Color) = (0,0,0,1)
            _GridColor("GridColor", Color) = (1,1,1,1)
            _gridthick("gridthick", Float) = 0.005
            //_Color ("Color", Color) = (1,1,1,1)
            //_MainTex ("Albedo (RGB)", 2D) = "white" {}
        [Space(15)]
        [Header(DrawPoint)]
            _drawpointthick("drawpointthick", Float) = 0.01
        [Space(15)]
        [Header(DrawPoint1)]
            [KeywordEnum(LINEAR, PARABOLA, EXPONENTIAL)] _MODE1("Chart Mode", Float) = 0
            _LineColor1("LineColor1", Color) = (1,0,0,1)
            _a1("a1", Float) = 1.0
            _b1("b1", Float) = 1.0
            _c1("c1", Float) = 1.0
        [Space(15)]
        [Header(DrawPoint)]
            [KeywordEnum(LINEAR, PARABOLA, EXPONENTIAL)] _MODE2("Chart Mode", Float) = 0
            _LineColor2("LineColor2", Color) = (0,1,0,1)
            _a2("a2", Float) = 1.0
            _b2("b2", Float) = 1.0
            _c2("c2", Float) = 1.0
        
        [Space(15)]
        [Header(DrawPoint)]
            [KeywordEnum(LINEAR, PARABOLA, EXPONENTIAL)] _MODE3("Chart Mode", Float) = 0
            _LineColor3("LineColor3", Color) = (0,0,1,1)
            _a3("a3", Float) = 1.0
            _b3("b3", Float) = 1.0
            _c3("c3", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass{
            CGPROGRAM

            #pragma multi_compile _MODE1_LINEAR _MODE1_PARABOLA _MODE1_EXPONENTIAL
            #pragma multi_compile _MODE2_LINEAR _MODE2_PARABOLA _MODE2_EXPONENTIAL
            #pragma multi_compile _MODE3_LINEAR _MODE3_PARABOLA _MODE3_EXPONENTIAL

            #include "UnityCG.cginc"
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma vertex vert
            #pragma fragment frag

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            sampler2D _MainTex;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv :TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            #define _POINTS 100

            float _x0;
            float _y0;

            float4 _drawrange;

            fixed4 _BackGroundColor;
            fixed4 _GridColor;
            fixed4 _LineColor1;
            fixed4 _LineColor2;
            fixed4 _LineColor3;

            float2 _drawpoint[_POINTS];
            float _drawpointthick;
            float _gridthick;

            float _a1;
            float _b1;
            float _c1;
            float _function1(float x_axis){
                //ここに表示したい数式1を書く。横軸x_axis
                #ifdef _MODE1_LINEAR
                    return _a1 * x_axis +_b1;
                #endif
                #ifdef _MODE1_PARABOLA
                    return _a1 * x_axis * x_axis +_b1 * x_axis + _c1;
                #endif
                #ifdef _MODE1_EXPONENTIAL
                    return _a1 * exp(_b1 * x_axis) +_c1;
                #endif
            }

            float _a2;
            float _b2;
            float _c2;
            float _function2(float x_axis){
                #ifdef _MODE2_LINEAR
                    return _a2 * x_axis +_b2;
                #endif
                #ifdef _MODE2_PARABOLA
                    return _a2 * x_axis * x_axis +_b2 * x_axis + _c2;
                #endif
                #ifdef _MODE2_EXPONENTIAL
                    return _a2 * exp(_b2 * x_axis) +_c2;
                #endif
            }

            float _a3;
            float _b3;
            float _c3;
            float _function3(float x_axis){
                #ifdef _MODE3_LINEAR
                    return _a3 * x_axis +_b3;
                #endif
                #ifdef _MODE3_PARABOLA
                    return _a3 * x_axis * x_axis +_b3 * x_axis + _c3;
                #endif
                #ifdef _MODE3_EXPONENTIAL
                    return _a3 * exp(_b3 * x_axis) +_c3;
                #endif
            }

            float2 uv2xy(float2 uv){
                return float2(((_drawrange.y - _drawrange.x) * uv.x) + _drawrange.x, ((_drawrange.w - _drawrange.z) * uv.y) + _drawrange.z);
            }

            float2 xy2uv(float2 xy){
                return float2((xy.x - _drawrange.x)/(_drawrange.y - _drawrange.x), (xy.y - _drawrange.z)/(_drawrange.w - _drawrange.z));
            }

            v2f vert(appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 c;

                float2 xy = uv2xy(IN.uv);

                c = _BackGroundColor;
                c += lerp(_GridColor, _BackGroundColor, smoothstep(0, _gridthick*(_drawrange.w - _drawrange.z), abs(frac(xy.y+0.5)-0.5))); //x軸
                c += lerp(_GridColor, _BackGroundColor, smoothstep(0, _gridthick*(_drawrange.y - _drawrange.x), abs(frac(xy.x+0.5)-0.5))); //y軸
                c += lerp(_GridColor, _BackGroundColor, smoothstep(1.9*_gridthick, 2*_gridthick, distance(float2(IN.uv.x, IN.uv.y), xy2uv(float2(0, 0))))); //原点

                for(int i=0;i<_POINTS;i++){
                    float _drawpointXi = ((_drawrange.y - _drawrange.x)/(_POINTS+1) *(i+1)) + _drawrange.x;
                    _drawpoint[i] = float2(_drawpointXi, _function1(_drawpointXi));
                    if(distance(float2(IN.uv.x, IN.uv.y), xy2uv(_drawpoint[i])) < _drawpointthick){
                        c = _LineColor1;
                    }
                }

                for(int i=0;i<_POINTS;i++){
                    float _drawpointXi = ((_drawrange.y - _drawrange.x)/(_POINTS+1) *(i+1)) + _drawrange.x;
                    _drawpoint[i] = float2(_drawpointXi, _function2(_drawpointXi));
                    if(distance(float2(IN.uv.x, IN.uv.y), xy2uv(_drawpoint[i])) < _drawpointthick){
                        c = _LineColor2;
                    }
                }

                for(int i=0;i<_POINTS;i++){
                    float _drawpointXi = ((_drawrange.y - _drawrange.x)/(_POINTS+1) *(i+1)) + _drawrange.x;
                    _drawpoint[i] = float2(_drawpointXi, _function3(_drawpointXi));
                    if(distance(float2(IN.uv.x, IN.uv.y), xy2uv(_drawpoint[i])) < _drawpointthick){
                        c = _LineColor3;
                    }
                }

                return c;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}