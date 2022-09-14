// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Starter/Water"
{
    Properties
    {
        main_tex ("Main Tex",2D) ="white" {}
        main_color ("Main Color",Color) =(1,1,1,1)
        magnitude ("Distortion Magnitude",Float) = 1
        frequence ("Distortion Frequence",Float) = 1
        inv_wavelength ("Wave Length Inv",Float) = 10
        speed ("Speed",Float)=0.5
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "DisableBatching"="True" //批处理会导致每个模型单独的模型空间丢失，导致无法在模型空间下做顶点动画。
        }
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"


            sampler2D main_tex;
            float4 main_tex_ST;
            fixed4 main_color;
            float magnitude;
            float frequence;
            float inv_wavelength;
            float speed;

            struct a2v
            {
                float4 vertex :  POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            v2f vert (a2v v)
            {
			 	v2f o;
                float4 offset;
                offset.yzw=float3(0.0,0.0,0.0);
                offset.x= sin(frequence * _Time.y + (v.vertex.x+v.vertex.y+v.vertex.z) * inv_wavelength) * magnitude; 

			 	o.pos = UnityObjectToClipPos(v.vertex+offset);

                o.uv=TRANSFORM_TEX(v.texcoord,main_tex)+float2(0.0,_Time.y * speed);// 竖直滚动
			 	return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed4 color=tex2D(main_tex,i.uv);

                return color*main_color;
            }
            ENDCG
        }

    }

}
