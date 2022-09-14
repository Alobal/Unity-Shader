Shader "Starter/EdgeCG"
{
    Properties
    {
        _MainTex ("Base", 2D) = "white" {}
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
            float sample_distance;
            float depth_threshold;
            float normal_threshold;
            sampler2D _CameraDepthNormalsTexture;

            struct a2v
            {
                float4 vertex :  POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
                half2 uv[5] : TEXCOORD0; //������Զ����Ϊ���TEXCOORD
            };

            float CheckEdge(half4 sample1, half4 sample2)
            {
                half2 normal1=sample1.xy;
                half2 normal2=sample2.xy;
                float depth1=DecodeFloatRG(sample1.zw);
                float depth2=DecodeFloatRG(sample2.zw);

                half2 normal_diff=abs(normal1-normal2);
                float normal_passcheck=(normal_diff.x+normal_diff.y)*normal_threshold;
                float depth_diff=abs(depth1-depth2);
                float depth_passcheck=depth_diff*depth_threshold;
                float edge_passcheck=normal_passcheck + depth_passcheck;

                return edge_passcheck;
            }


            v2f vert (a2v v)
            {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);
                half2 uv=v.texcoord;

                //����DXƽ̨�������������·�ת
                #if UNITY_UV_STARTS_AT_TOP
                if(_MainTex_TexelSize.y<0)
                    uv.y=1-uv.y;
                #endif

                o.uv[0]=uv;
                o.uv[1]=uv+_MainTex_TexelSize.xy*half2(1,1)*sample_distance;
                o.uv[2]=uv+_MainTex_TexelSize.xy*half2(-1,-1)*sample_distance;
                o.uv[3]=uv+_MainTex_TexelSize.xy*half2(-1,1)*sample_distance;
                o.uv[4]=uv+_MainTex_TexelSize.xy*half2(1,-1)*sample_distance;

			 	return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 top_right=tex2D(_CameraDepthNormalsTexture,i.uv[1]);
                half4 bottom_left=tex2D(_CameraDepthNormalsTexture,i.uv[2]);
                half4 bottom_right=tex2D(_CameraDepthNormalsTexture,i.uv[3]);
                half4 top_left=tex2D(_CameraDepthNormalsTexture,i.uv[4]);

                float edge_intensity =1.0;
                edge_intensity*=CheckEdge(top_right,bottom_left)+CheckEdge(top_left,bottom_right);


                fixed4 base_plus_edge = lerp(tex2D(_MainTex,i.uv[0]),edge_color,edge_intensity);
                fixed4 background_plus_edge= lerp(background_color,edge_color,edge_intensity);

                return lerp(background_plus_edge,base_plus_edge,base_alpha);
                //return edge_intensity;
            }
        ENDCG
        }
    }
}
