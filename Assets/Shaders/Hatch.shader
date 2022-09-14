// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Starter/Hatch"
{
    Properties
    {
        main_color ("Main Color",Color)=(1,1,1,1)
        hatch_density("Hatch Density", Float) = 1.0
        outline ("Outline", Range(0,1)) =0.1
        outline_color ("Outline Color",Color)=(1,1,1,1)
        hatch_base("Hatch Base Color",Color)=(1,1,1,1)
        hatch_tex0("Hatch Texture 0",2D)= "white" {}
        hatch_tex1("Hatch Texture 1",2D)= "white" {}
        hatch_tex2("Hatch Texture 2",2D)= "white" {}
        hatch_tex3("Hatch Texture 3",2D)= "white" {}
        hatch_tex4("Hatch Texture 4",2D)= "white" {}
        hatch_tex5("Hatch Texture 5",2D)= "white" {}

    }
    SubShader
    {   
        Tags
        {
            "RenderType"="Opaque"
            "Queue" = "Geometry"
        }
        UsePass "Starter/Toon/OUTLINE"

        CGINCLUDE
        fixed4 main_color;
        float hatch_density;
        float outline;
        fixed4 outline_color;
        fixed4 hatch_base;
        sampler2D hatch_tex0;
        float4 hatch_tex0_ST;
        sampler2D hatch_tex1;
        float4 hatch_tex1_ST;
        sampler2D hatch_tex2;
        float4 hatch_tex2_ST;
        sampler2D hatch_tex3;
        float4 hatch_tex3_ST;
        sampler2D hatch_tex4;
        float4 hatch_tex4_ST;
        sampler2D hatch_tex5;
        float4 hatch_tex5_ST;
        #include "Lighting.cginc"
        #include "AutoLight.cginc"
        ENDCG

         Pass 
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase 
            struct a2v
            {
                float4 vertex :  POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv: TEXCOORD0;
                fixed hatch_weight[2]: TEXCOORD1; //6个hatch纹理+2个basecolor 的权重
                float4 world_pos_and_index : TEXCOORD3;
                SHADOW_COORDS(4)
            };
             
            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=v.texcoord.xy * hatch_density;

                fixed3 world_light=normalize(WorldSpaceLightDir(v.vertex));
                fixed3 world_normal=UnityObjectToWorldNormal(v.normal);
                fixed diff=saturate(dot(world_light,world_normal));

                //根据漫反射程度选择素描程度
                float hatch_factor=diff * 6.9;
                int index = int(hatch_factor);
                o.hatch_weight[1]=hatch_factor-index;
                o.hatch_weight[0]=1-o.hatch_weight[1];

                o.world_pos_and_index.w=index;
                o.world_pos_and_index.xyz=mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
                int index =i.world_pos_and_index.w;
                float3 world_pos=i.world_pos_and_index.xyz;

                fixed4 hatch_color[8];
                hatch_color[0]=tex2D(hatch_tex0,i.uv);
                hatch_color[1]=tex2D(hatch_tex1,i.uv);
                hatch_color[2]=tex2D(hatch_tex2,i.uv);
                hatch_color[3]=tex2D(hatch_tex3,i.uv);
                hatch_color[4]=tex2D(hatch_tex4,i.uv);
                hatch_color[5]=tex2D(hatch_tex5,i.uv);
                hatch_color[6]=hatch_base;
                hatch_color[7]=hatch_base;
                
                fixed4 hatch_result=hatch_color[index+1]*i.hatch_weight[1]+hatch_color[index]*i.hatch_weight[0];

                //计算阴影
                UNITY_LIGHT_ATTENUATION(atten,i,world_pos);

                return fixed4(hatch_result.rgb*main_color.rgb*atten,1.0);
            }
            ENDCG 
        }
    }
    FallBack "Diffuse"
}
