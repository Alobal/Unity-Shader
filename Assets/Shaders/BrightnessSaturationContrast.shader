// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Starter/BrightnessSaturationContrast"
{
    Properties
    {
        _MainTex ("Main Tex",2D) ="white" {}
        brightness("Brightness",Float)=1
        saturation("Saturation",Float)=1
        contrast("Contrast",Float)=1
    }
    SubShader
    {

        Pass
        {   //屏幕后处理是绘制一个屏幕大小的四边形 因此要取消相应的深度剔除
            Tags{"LightMode"="ForwardBase"}
            ZTest Always
            ZWrite Off
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"


            sampler2D _MainTex;
            float brightness;
            float saturation;
            float contrast;


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
			 	o.pos = UnityObjectToClipPos(v.vertex);

                o.uv=v.texcoord;// 竖直滚动
			 	return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed4 original_color=tex2D(_MainTex,i.uv);
                fixed3 color=original_color.rgb;
                color*=brightness;

                fixed lumin=0.2125 * original_color.r + 0.7154*original_color.g+0.0721*original_color.b;
                fixed3 saturation_color=fixed3(lumin,lumin,lumin);
                color=lerp(saturation_color,color,saturation);

                fixed3 avg_color=fixed3 (0.5,0.5,0.5);
                color=lerp(avg_color,color,contrast);

                return fixed4(color,original_color.a);
            }
            ENDCG
        }

    }

}
