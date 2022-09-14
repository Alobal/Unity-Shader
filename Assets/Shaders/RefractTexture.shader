// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Starter/RefractTexture"
{
    Properties
    {
        _Color ("Color Tint",Color) =(1,1,1,1)
        _RefractColor("Refract Color",Color)=(1,1,1,1)
        _RefractAmount("Refract Amount",Range(0,1))=1
        _RefractRatio("Refract Ratio",Range(0.1,1))=0.5
        _Cubemap("Refraction Cubemap",Cube)="_Skybox"{}

    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            fixed4 _Color;
            fixed4 _RefractColor;
            fixed _RefractAmount;
            fixed _RefractRatio;
            samplerCUBE _Cubemap;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 world_normal : TEXCOORD0;
                float3 world_pos : TEXCOORD1;
                SHADOW_COORDS(2) 
            };

            v2f vert(a2v a)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(a.vertex);
                o.world_normal=UnityObjectToWorldNormal(a.normal);
                o.world_pos=mul(unity_ObjectToWorld,a.vertex).xyz;

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 world_normal=normalize(i.world_normal);
                fixed3 world_lightdir=normalize(UnityWorldSpaceLightDir(i.world_pos));
                fixed3 world_view=normalize(UnityWorldSpaceViewDir(i.world_pos));
                //逆向计算反射入射光线

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*_Color.rgb;
                fixed3 diffuse=_LightColor0.rgb * _Color.rgb * saturate(dot(world_normal,world_lightdir));


                fixed3 world_refract=refract(-world_view,world_normal,_RefractRatio);
                fixed3 refraction=texCUBE(_Cubemap,world_refract).rgb*_RefractColor.rgb;

                UNITY_LIGHT_ATTENUATION(atten,i,i.world_pos);

                return fixed4(ambient+lerp(diffuse,refraction,_RefractAmount)*(atten*0.5+0.5),1.0);
            }
            ENDCG
        }

    }

    FallBack "Reflective/VertexLit"
}
