// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Starter/Dissolve"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white" {}
        bump_texture ("Normal Tex",2D)="white" {}
        burn_texture("Burn Tex",2D) = "white" {}
        burn_amount("Burn Amount",Range(0,1))=0.0
        burn_border_width("Burn Line Width",Range(0,1))=0.1
        burn_firstcolor("Burn First Color",Color)=(1,0,0,1)
        burn_secondcolor("Burn Second Color",Color)=(1,0,0,1)



    }
    SubShader
    {   
        CGINCLUDE
        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D burn_texture;
        float4 burn_texture_ST;
        sampler2D bump_texture;
        float4 bump_texture_ST;
        half burn_amount;
        half burn_border_width;
        fixed4 burn_firstcolor;
        fixed4 burn_secondcolor;
        #include "Lighting.cginc"
        #include "AutoLight.cginc"
        ENDCG

         Pass 
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            Cull Off //消融理应露出背面

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase 
            struct a2v
            {
                float4 vertex :  POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 main_uv: TEXCOORD0;
                float2 bump_uv : TEXCOORD1;
                float2 burn_uv : TEXCOORD2;
                float3 light_dir : TEXCOORD3;
                float3 world_pos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.main_uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.burn_uv=TRANSFORM_TEX(v.texcoord,burn_texture);
                o.bump_uv=TRANSFORM_TEX(v.texcoord,bump_texture);

                //先获取模型空间到切线空间的变换矩阵rotation，再对光源进行变换。
                TANGENT_SPACE_ROTATION;
                o.light_dir=mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;

                o.world_pos=mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
               fixed3 burn_sample =tex2D(burn_texture,i.burn_uv).rgb;
               float burn_value =dot(burn_sample,fixed3(1,1,1))/3;
               burn_amount=lerp(0,1,frac(_Time.y*0.1));
               clip(burn_value - burn_amount);//纹理采样值决定是否消融

               float3 light_dir_tangent=normalize(i.light_dir);
               float3 normal_tangent=UnpackNormal(tex2D(bump_texture,i.bump_uv));

               fixed3 albedo=tex2D(_MainTex,i.main_uv).rgb;
               fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
               fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(normal_tangent,light_dir_tangent));
               UNITY_LIGHT_ATTENUATION(atten,i,i.world_pos);
               fixed3 origin_color=ambient+diffuse*atten;

               //消融边界的 未被消融的像素的颜色处理  burn_border越接近1越靠近边界
               fixed burn_border=1-smoothstep(0,burn_border_width,burn_value-burn_amount);
               fixed3 burn_color=lerp(burn_firstcolor,burn_secondcolor,burn_border);
               burn_color=pow(burn_color,5);

               fixed3 result=lerp(origin_color,burn_color,burn_border);

               return fixed4(result,1);

            }
            ENDCG 
        }

         Pass 
         {  //自定义shadow pass 剔除透明frag
            Tags
            {
                "LightMode" ="ShadowCaster"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            struct v2f
            {
                V2F_SHADOW_CASTER;
                float2 burn_uv: TEXCOORD1;
            };

            v2f vert(appdata_base v)
            {
                v2f o;

                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.burn_uv = TRANSFORM_TEX(v.texcoord,burn_texture);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
               fixed3 burn_sample =tex2D(burn_texture,i.burn_uv).rgb;
               float burn_value =dot(burn_sample,fixed3(1,1,1))/3;
               burn_amount=lerp(0,1,frac(_Time.y*0.1));
               clip(burn_value - burn_amount);//纹理采样值决定是否消融

               SHADOW_CASTER_FRAGMENT(i)
                
            }
            ENDCG
         }

    }
    FallBack "Diffuse"

}
