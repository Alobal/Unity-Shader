// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Starter/AlphaBlend"
{
    Properties
    {
        _Color("Main Color",Color)=(1,1,1,1)
        _MainTex("Main Tex",2D)="white" {}
        _Specular("Specular",Color)=(1,1,1,1)
        _AlphaScale("Alpha Blend",Range(0,1))=0.5
    }
    SubShader
    {
        Tags 
        { 
            "Queue"="Transparent" 
            "IgnoreProjector"="True" 
            "RenderType"="Transparent"
        }

        Pass
        {   
            ZWrite On//保存深度值
            ColorMask 0 //pass不写入任何颜色
        }

        Pass
        {
            // Cull Off //保证两面都渲染，但是由于没有深度值，前后会错乱
            Tags{"LightMode"="ForwardBase"}
            // ZWrite Off //关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha //设置Blend模式
            // BlendOp Sub
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            fixed4 _Specular;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex :POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 world_normal: TEXCOORD0;
                float3 world_pos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.world_normal=UnityObjectToWorldNormal(v.normal);
                o.world_pos=mul(unity_ObjectToWorld,v.vertex);
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 world_normal=normalize(i.world_normal);
                fixed3 world_pos=normalize(i.world_pos);
                fixed3 world_light=normalize(UnityWorldSpaceLightDir(i.world_pos));
                fixed3 world_view=normalize(UnityWorldSpaceViewDir(i.world_pos));
                fixed3 world_half=normalize(world_light+world_view);
                fixed4 texcolor=tex2D(_MainTex,i.uv);

                fixed3 albedo =texcolor.rgb * _Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz *albedo;
                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(world_normal,world_light)*0.5+fixed3(0.5,0.5,0.5));
                fixed3 specular=_LightColor0.rgb * _Specular * pow(dot(world_view,world_half),20);

                return fixed4(ambient+diffuse,texcolor.a*_AlphaScale);
            }
            ENDCG
        }

    }
}
