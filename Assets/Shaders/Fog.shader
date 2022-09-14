Shader "Starter/Fog"
{   //运动模糊是摄像机的运动产生的模糊，因此pos改变的是V矩阵。
    Properties
    {
        _MainTex ("Base", 2D) = "white" {}
    }
    SubShader
    {

        CGINCLUDE

        sampler2D _MainTex;
        half4 _MainTex_TexelSize; //单位纹素大小 用于偏移纹素计算
        sampler2D _CameraDepthTexture;
        sampler2D noise_tex;
        float noise_amount;
        float4x4 VP_inverse;
        float4x4 frustum_corners;
        float fog_density=1.0;
        fixed4 fog_color=(1,1,1,1);
        float fog_starth=0.0;
        float fog_endh=1.0;
        float fog_speedv=1.0;
        float fog_speedh=1.0;


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
                float4 inter_ray : TEXCOORD1;
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

                int index=0;
                if(o.uv.x<0.5 && o.uv.y<0.5)
                    index=0;
                else if(o.uv.x>0.5 && o.uv.y<0.5)
                    index=1;
                else if(o.uv.x>0.5 && o.uv.y>0.5)
                    index=2;
                else if(o.uv.x<0.5 && o.uv.y>0.5)
                    index=3;

                o.inter_ray=frustum_corners[index];//顶点射线，转换到片元着色器时会插值处理

			 	return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float linear_depth=LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv));
               float3 pos_world=_WorldSpaceCameraPos+linear_depth * i.inter_ray.xyz;

               //noise 偏移
               float2 fog_offset=_Time.y * float2(fog_speedh,fog_speedv);
               float3 noise_sample=tex2D(noise_tex,i.uv+fog_offset);
               float noise=dot(noise_sample,float3(1,1,1))/3 * noise_amount;

               //计算fog程度
               float fog_scale=(fog_endh-pos_world.y)/(fog_endh-fog_starth);
               fog_density=saturate(fog_density*fog_scale*(1+noise));
               fixed4 color=tex2D(_MainTex,i.uv);
               color.rgb=lerp(color.rgb,fog_color.rgb,fog_density);

                return color;
            }
        ENDCG
        }
    }
}
