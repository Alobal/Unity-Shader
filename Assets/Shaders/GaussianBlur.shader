Shader "Starter/GaussianBlur"
{
    Properties
    {
        _MainTex ("Base", 2D) = "white" {}
    }
    SubShader
    {
        ZTest Always
        ZWrite Off
        Cull Off


        CGINCLUDE


        #include "Lighting.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize; //单位纹素大小 用于偏移纹素计算
        int blur_size;



        struct a2v
        {
            float4 vertex :  POSITION;
            float4 texcoord : TEXCOORD0;
        };

        struct v2f 
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0; //数组会自动拆分为多个TEXCOORD
        };

        v2f vert (a2v v)
        {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
            o.uv=v.texcoord.xy;
			return o;
        }

        fixed4 fragH (v2f i) : SV_Target
        {
            half kernel[3]={6,3,1};
            kernel[0]/=2;

            half4 result=half4(0,0,0,0);
            int count=0;
            for(int j =0;j<2;j++)//手搓卷积
            {
                half2 pos_index=i.uv+_MainTex_TexelSize.xy*half2(j,1);
                half2 neg_index=i.uv-_MainTex_TexelSize.xy*half2(j,1);

                result+=(tex2D(_MainTex,pos_index)+tex2D(_MainTex,neg_index))*kernel[j];
                count+=kernel[j]*2;
            }

            result=result/count;
            return result;
        }

        fixed4 fragV (v2f i) : SV_Target
        {
            const half kernel[3]={6,3,1};
            kernel[0]/=2;


            half4 result=half4(0,0,0,0);
            int count=0;
            for(int j =0;j<2;j++)//手搓卷积
            {
                half2 pos_index=i.uv+_MainTex_TexelSize.xy*half2(1,j);
                half2 neg_index=i.uv-_MainTex_TexelSize.xy*half2(1,j);

                result+=(tex2D(_MainTex,pos_index)+tex2D(_MainTex,neg_index))*kernel[j];
                count+=kernel[j]*2;
            }

            result=result/count;
            return result;
        }
        ENDCG

       Pass
        {   //屏幕后处理是绘制一个屏幕大小的四边形 因此要取消相应的深度剔除
            Tags{"LightMode"="ForwardBase"}
            NAME "BLUR_VERTICAL"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragV

            ENDCG
        }

        Pass
        {   //屏幕后处理是绘制一个屏幕大小的四边形 因此要取消相应的深度剔除
            Tags{"LightMode"="ForwardBase"}
            NAME "BLUR_HORIZON"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragH

            ENDCG
        }
    }
}
