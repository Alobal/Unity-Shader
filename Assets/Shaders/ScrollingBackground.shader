// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Starter/ScrollingBackground"
{
    Properties
    {
        main_tex ("Base",2D)="white" {}
        detail_tex ("Detail",2D)="white" {}
        scroll_x ("Base Speed",Float)=1.0
        scroll_x2 ("Detail Speed",Float)=1.0
        multiplier("Layer multiplier",float)=1

    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            sampler2D main_tex;
            float4 main_tex_ST;
            sampler2D detail_tex;
            float4 detail_tex_ST;
            float scroll_x;
            float scroll_x2;
            float multiplier;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uvuv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uvuv.xy=TRANSFORM_TEX(v.texcoord,main_tex)+frac(float2(scroll_x,0.0)*_Time.y);//frac 返回小数部分
                o.uvuv.zw=TRANSFORM_TEX(v.texcoord,detail_tex)+frac(float2(scroll_x2,0.0)*_Time.y);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 main_layer=tex2D(main_tex,i.uvuv.xy);
                fixed4 detail_layer=tex2D(detail_tex,i.uvuv.zw);

                fixed4 color=lerp(main_layer,detail_layer,detail_layer.a);
                color.rgb*=multiplier;

                return color;
            }
            ENDCG
        }

    }
}
