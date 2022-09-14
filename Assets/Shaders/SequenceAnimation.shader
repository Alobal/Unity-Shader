// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Starter/SequenceAnimation"
{
    Properties
    {
        _Color ("Color Tint",Color) =(1,1,1,1)
        _MainTex ("Image Sequence",2D)="white" {}
        _HorizontalAmount ("Horizontal Amount", Float) = 4
        _VerticalAmount ("Vertical Amount", Float) = 4
        _Speed ("Speed", Range(1,100))= 30

    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent" //半透明图像
            "IgnoreProjector"="True" 
            "RenderType"="Transparent"
        }

        Pass
        {
            Tags{"LightMode"="ForwardBase"}

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time=floor(_Time.y * _Speed);
                float row=floor(time/_HorizontalAmount);
                float column=time-row*_HorizontalAmount; //余数作为列索引

                half2 uv=i.uv+half2(column,-row);//纹理坐标缩放到子图坐标系中，并根据索引选取子图,注意竖直方向相反。
                uv.x/=_HorizontalAmount;
                uv.y/=_VerticalAmount;

                fixed4 color=tex2D(_MainTex,uv);
                color.rgb*=_Color;

                return color;
            }
            ENDCG
        }

    }
}
