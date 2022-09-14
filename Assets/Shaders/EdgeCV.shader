Shader "Starter/EdgeCV"
{
    Properties
    {
        _MainTex ("Base", 2D) = "white" {}
        base_alpha("",Float)=1.0
        edge_color ("", Color)=(0,0,0,1)
        background_color("",Color)=(1,1,1,1)
    }
    SubShader
    {
       Pass
        {   //��Ļ�����ǻ���һ����Ļ��С���ı��� ���Ҫȡ����Ӧ������޳�
            Tags{"LightMode"="ForwardBase"}
            ZTest Always
            ZWrite Off
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"


            sampler2D _MainTex;
            half4 _MainTex_TexelSize; //��λ���ش�С ����ƫ�����ؼ���
            float base_alpha;
            fixed4 edge_color;
            fixed4 background_color;


            struct a2v
            {
                float4 vertex :  POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
                half2 uv[9] : TEXCOORD0; //������Զ����Ϊ���TEXCOORD
            };


            v2f vert (a2v v)
            {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);
                half2 uv=v.texcoord;

                o.uv[0]=uv+_MainTex_TexelSize.xy*half2(-1,-1);
                o.uv[1]=uv+_MainTex_TexelSize.xy*half2(0,-1);
                o.uv[2]=uv+_MainTex_TexelSize.xy*half2(1,-1);
                o.uv[3]=uv+_MainTex_TexelSize.xy*half2(-1,0);
                o.uv[4]=uv+_MainTex_TexelSize.xy*half2(0,0);
                o.uv[5]=uv+_MainTex_TexelSize.xy*half2(1,0);
                o.uv[6]=uv+_MainTex_TexelSize.xy*half2(-1,1);
                o.uv[7]=uv+_MainTex_TexelSize.xy*half2(0,1);
                o.uv[8]=uv+_MainTex_TexelSize.xy*half2(1,1);
			 	return o;
            }

            fixed ToGray(fixed4 color)
            {
                return 0.2125 *color.r + 0.7154*color.g+0.0721*color.b;
            }

            half Sobel(v2f i)
            {
                const half Gx[9]={-1,0,1,
                                   -2,0,2,
                                   -1,0,1};
                const half Gy[9]={-1,-2,-1,
                                  0,0,0,
                                  1,2,1};

                half tex_color;
                half edge_x=0;
                half edge_y=0;
                for(int j =0;j<9;j++)//�ִ���
                {
                    float j_lumin=ToGray(tex2D(_MainTex,i.uv[j]));
                    edge_x+=j_lumin * Gx[j];
                    edge_y+=j_lumin * Gy[j];
                }

                half edge=abs(edge_x)+abs(edge_y);
                return edge;
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half edge_intensity=Sobel(i);
                fixed4 edge_withbase = lerp(tex2D(_MainTex,i.uv[4]),edge_color,edge_intensity);
                fixed4 edge_withback=lerp(background_color,edge_color,edge_intensity);
                return lerp(edge_withbase,edge_withback,base_alpha);
            }
        ENDCG
        }
    }
}
