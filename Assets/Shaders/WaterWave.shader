// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Starter/WaterWave"
{
    Properties
    {
        main_tex ("Base Texture", 2D) = "white" {}
        bump_tex ("Bump Texture for Wave",2D) = "white" {}
        cubemap("Environment Cubemap",Cube)="_Skybox"{}
        main_color ("Main Color",Color) =(1,1,1,1)
        speed_waveh ("Wave Horizontal Speed",Range(-1,1))=0.1
        speed_wavev ("Wave Vertical Speed",Range(-1,1))=0.1
        distortion ("Distortion", Range(0,100))=10 //折射扰动
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent" 
            "RenderType"="Opaque" //shader replacement 需求
        }

        CGINCLUDE 
        sampler2D main_tex;
        float4 main_tex_ST;
        sampler2D bump_tex;
        float4 bump_tex_ST;
        samplerCUBE cubemap;
        fixed4 main_color;
        fixed speed_waveh;
        fixed speed_wavev;
        float distortion;
        sampler2D refract_tex; //GrabPass 存储变量
        float4 refract_tex_TexelSize;
        #include "Lighting.cginc"
        #include "AutoLight.cginc"
        ENDCG
        GrabPass {"refract_tex"} //屏幕抓取到tex

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag


            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord: TEXCOORD;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 pos_screen : TEXCOORD0;
                float4 uvuv: TEXCOORD1;
                float4 tangent_to_world0: TEXCOORD2;
                float4 tangent_to_world1: TEXCOORD3;
                float4 tangent_to_world2: TEXCOORD4;

            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.pos_screen=ComputeGrabScreenPos(o.pos); //含w的屏幕坐标
                o.uvuv.xy=TRANSFORM_TEX(v.texcoord,main_tex);
                o.uvuv.zw=TRANSFORM_TEX(v.texcoord,bump_tex);

                //bump法线从切线空间到世界空间的变换矩阵
                float3 pos_world=mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 normal_world=UnityObjectToWorldNormal(v.normal);
                fixed3 tangent_world=UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 binormal_world=cross(normal_world,tangent_world) * v.tangent.w;
                o.tangent_to_world0=float4(tangent_world.x,binormal_world.x,normal_world.x,pos_world.x);
                o.tangent_to_world1=float4(tangent_world.y,binormal_world.y,normal_world.y,pos_world.y);
                o.tangent_to_world2=float4(tangent_world.z,binormal_world.z,normal_world.z,pos_world.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 pos_world=float3(i.tangent_to_world0.w,i.tangent_to_world1.w,i.tangent_to_world2.w);
                fixed3 view_dir=normalize(UnityWorldSpaceViewDir(pos_world));
                float2 speed = _Time.y * float2(speed_waveh,speed_wavev);
                i.pos_screen/=i.pos_screen.w;//注意相机near far 大的时候 z值特别小

                fixed3 bump1=UnpackNormal(tex2D(bump_tex,i.uvuv.zw+speed)).rgb;
                fixed3 bump2=UnpackNormal(tex2D(bump_tex,i.uvuv.zw-speed)).rgb;
                fixed3 normal_bump=normalize(bump1+bump2);

                //计算折射偏移  深度越大 折射越大
                float2 offset=normal_bump.xy* distortion * i.pos_screen.z*500* refract_tex_TexelSize.xy;
                i.pos_screen.xy+=offset;
                fixed3 color_refract=tex2D(refract_tex,i.pos_screen).rgb;

                //反射采样cubemap
                normal_bump.x=dot(i.tangent_to_world0.xyz,normal_bump);
                normal_bump.y=dot(i.tangent_to_world1.xyz,normal_bump);
                normal_bump.z=dot(i.tangent_to_world2.xyz,normal_bump);
                normal_bump=normalize(normal_bump);
                fixed4 tex_color=tex2D(main_tex,i.uvuv.xy);
                fixed3 reflect_dir=reflect(-view_dir,normal_bump);
                fixed3 color_reflect=texCUBE(cubemap,reflect_dir).rgb * tex_color.rgb * main_color.rgb;

                fixed fresnel=pow(1-saturate(dot(view_dir,normal_bump)),4);
                fixed3 result=color_reflect * fresnel + color_refract * (1-fresnel);

                return fixed4 (result,1);
            }
            ENDCG
        }

    }
}
