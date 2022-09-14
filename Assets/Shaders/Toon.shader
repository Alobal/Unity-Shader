// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Starter/Toon"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white" {}
        ramp_texture ("Ramp Tex",2D)="white" {}
        main_color ("Main Color",Color)=(1,1,1,1)
        outline ("Outline", Range(0,1)) =0.1
        outline_color ("Outline Color",Color)=(1,1,1,1)
        specular_color ("Specular", Color) = (1,1,1,1)
        specular_scale ("Specular Scale",Range(0,0.1))=0.1

    }
    SubShader
    {   
        CGINCLUDE
        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D ramp_texture;
        float4 ramp_texture_ST;
        fixed4 main_color;
        float outline;
        fixed4 outline_color;
        fixed4 specular_color;
        float specular_scale;

        #include "Lighting.cginc"
        #include "AutoLight.cginc"
        ENDCG

        Pass
        {
            NAME "OUTLINE"
            //只渲染背面
            Cull Front
            Tags{"LightMode"="ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct a2v
            {
                float4 vertex :  POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 color : COLOR;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos=mul(UNITY_MATRIX_MV,v.vertex);
                float3 world_normal =UnityObjectToWorldNormal(v.normal);
                world_normal.z=-0.5;//归一化防止outline穿模前面
                o.pos+=float4(normalize(world_normal),0)*outline; //顶点沿法线扩张，
                o.pos=mul(UNITY_MATRIX_P,o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return outline_color;
            }
            ENDCG
        }


         Pass 
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            Cull Back

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
                float3 world_normal : TEXCOORD1;
                float3 world_pos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.world_normal=UnityObjectToWorldNormal(v.normal);
                o.world_pos=mul(unity_ObjectToWorld,v.vertex).xyz;

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
                fixed3 world_normal=normalize(i.world_normal);
                fixed3 world_light=normalize(UnityWorldSpaceLightDir(i.world_pos));
                fixed3 world_view=normalize(UnityWorldSpaceViewDir(i.world_pos));
                fixed3 world_half=normalize(world_light+world_view);

                fixed3 albedo=tex2D(_MainTex,i.uv).rgb * main_color.rgb;

                fixed3 ambient_color = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //计算阴影
                UNITY_LIGHT_ATTENUATION(atten,i,i.world_pos);
                fixed diffuse_scale=dot(world_normal,world_light);
                diffuse_scale=(diffuse_scale*0.5+0.5)*atten;

                fixed3 diffuse_color=_LightColor0.rgb * albedo * tex2D(ramp_texture,float2(diffuse_scale,diffuse_scale)).rgb;

                fixed spec = dot(world_normal,world_half);
                fixed w = 0.001;
                specular_color.rgb=specular_color.rgb * smoothstep(-w,w,spec+specular_scale-1);

                return fixed4(ambient_color + diffuse_color + specular_color,1.0);
            }
            ENDCG 
        }

       
    }
    FallBack "Diffuse"

}
