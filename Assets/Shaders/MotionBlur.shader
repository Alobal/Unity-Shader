Shader "Starter/MotionBlur"
{   //运动模糊是摄像机的运动产生的模糊，因此pos改变的是V矩阵。
    Properties
    {
        _MainTex ("Base", 2D) = "white" {}
        blur_size("Blur Size",Float)=1
    }
    SubShader
    {

        CGINCLUDE

        sampler2D _MainTex;
        half4 _MainTex_TexelSize; //单位纹素大小 用于偏移纹素计算
        sampler2D _CameraDepthTexture;
        float4x4 VP_inverse;
        float4x4 VP_last;
        half blur_size;

        ENDCG


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

            struct a2v
            {
                float4 vertex :  POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
            };


            v2f vert (a2v v)
            {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);
                o.uv=v.texcoord;
                
                //处理DX平台的纹理坐标上下翻转
                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y<0)
                    o.uv.y=1-o.uv.y;
                #endif

			 	return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float d_screen=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);
                float4 pos_ndc=float4(i.uv.x *2-1, i.uv.y *2 -1 ,d_screen*2-1,1);
                float4 pos_temp=mul(VP_inverse,pos_ndc);
                float4 pos_world=pos_temp/pos_temp.w; //easy to prove now pos_temp.w=pos_world.w/pos_mvp.w.  so  by divided pos_temp.w, pos_temp becomes the true pos_world.

                float4 pos_lastndc=mul(VP_last,pos_world);
                pos_lastndc/=pos_lastndc.w;

                float2 pixel_velocity=(pos_ndc.xy-pos_lastndc.xy)/2.0f;


                float4 color=tex2D(_MainTex,i.uv);
                
                for (int j=1;j<3;j++)
                {
                    color+=tex2D(_MainTex,i.uv-pixel_velocity*blur_size*j);
                }

                color/=3;

                return fixed4(color.rgb,1);
            }
        ENDCG
        }
    }
}
