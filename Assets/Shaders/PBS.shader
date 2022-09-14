// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Starter/PBS"
{
    Properties
    {
        _MainTex("Main Tex",2D)="white" {}
        main_color ("Main Color",Color)= (1,1,1,1)
        glossiness ("Smoothness",Range(0,1))=0.5
        spec_basecolor ("Specular Color",Color)=(0.2,0.2,0.2)
        spec_glossmap ("Specular (RGB) Smoothness (A)",2D)= "white"{}
        bump_scale ("Bump Scale",Float) =1.0
        bump_map ("Normal Map", 2D)= "bump" {}
        emission_color ("Emission Color",Color) = (0,0,0,0)
        emission_map ("Emission Map", 2D) = "white"




    }
    SubShader
    {   
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 300

        CGINCLUDE
        sampler2D _MainTex;
        float4 _MainTex_ST;
        fixed4 main_color;
        fixed glossiness;
        fixed4 spec_basecolor;
        sampler2D spec_glossmap;
        float4 spec_glossmap_ST;
        float bump_scale;
        sampler2D bump_map;
        float4 bump_map_ST;
        fixed4 emission_color;
        sampler2D emission_map;
        float4 emission_map_ST; 
        #include "Lighting.cginc"
        #include "AutoLight.cginc"
        #include "HLSLSupport.cginc"
        #pragma target 3.0
        #pragma multi_compile_fwdbase
        #pragma multi_compile_fog

        inline half3 CustomDisneyDiffuseTerm(half n_dot_v,half n_dot_l,half l_dot_h,half roughness, half3 base_color)
        {
            half fd90=0.5 + 2 * l_dot_h * l_dot_h * roughness;
            half light=(1+(fd90-1) * pow(1-n_dot_l,5));
            half view=(1+(fd90-1) * pow(1-n_dot_v,5));
            return base_color * UNITY_INV_PI * light * view;
        }

        inline half CustomGGXVisibilityTerm(half nl,half nv,half roughness)
        {
            half a2 = roughness * roughness;
            half lambda_v=nl * (nv * (1-a2)+a2);
            half lambda_l=nv * (nl * (1-a2)+a2);
            float epision= 1e-5f;
            return 0.5f / (lambda_v + lambda_l + epision);
        }

        inline half CustomGGXNormalTerm(half nh,half roughness)
        {
            half a2 = roughness * roughness;
            half d = (nh * a2 - nh) * nh + 1.0f;
            return UNITY_INV_PI * a2 / (d * d + 1e-7f);
        }
        inline half CustomFresnelTerm(half3 c, half cosa)
        {
            half t = pow (1- cosa, 5);
            return c + (1-c) *t;
        }
        inline half3 CustomFresnelLerp(half3 c0,half3 c1, half cosa)
        {
            half t = pow(1-cosa,5);
            return lerp(c0,c1,t);
        }
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
                float2 uv: TEXCOORD0;
                float4 t2w0 : TEXCOORD1;
                float4 t2w1 : TEXCOORD2;
                float4 t2w2 : TEXCOORD3;
                SHADOW_COORDS(4)
                UNITY_FOG_COORDS(5)
            };
             
            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);

                float3 world_pos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 world_normal=UnityObjectToWorldNormal(v.normal);
                fixed3 world_tangent=UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 world_binormal=cross(world_normal,world_tangent) * v.tangent.w;

                o.t2w0=float4(world_tangent.x,world_binormal.x,world_normal.x,world_pos.x);
                o.t2w1=float4(world_tangent.y,world_binormal.y,world_normal.y,world_pos.y);
                o.t2w2=float4(world_tangent.z,world_binormal.z,world_normal.z,world_pos.z);

                TRANSFER_SHADOW(o);//shadow generate
                UNITY_TRANSFER_FOG(o,o.pos);//fog render

                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
               //rough data
               half4 spec_gloss = tex2D(spec_glossmap,i.uv);
               spec_gloss.a*=glossiness;
               half3 spec_color= spec_gloss.rgb * spec_basecolor.rgb;
               half reflect_scale=max(max(spec_color.r,spec_color.g),spec_color.b);
               half3 diffuse_color = main_color.rgb * tex2D(_MainTex,i.uv).rgb * (1-reflect_scale);

               half roughness=1-spec_gloss.a;

               //world data
               half3 tan_normal=UnpackNormal(tex2D(bump_map,i.uv));
               tan_normal.xy*=bump_scale;
               tan_normal.z= sqrt(1.0-saturate(dot(tan_normal.xy,tan_normal.xy)));
               half3 world_normal= normalize(half3(dot(i.t2w0.xyz,tan_normal),dot(i.t2w1.xyz,tan_normal),dot(i.t2w2.xyz,tan_normal)));
               float3 world_pos=float3(i.t2w0.z,i.t2w1.z,i.t2w2.z);
               half3 light_dir=normalize(UnityWorldSpaceLightDir(world_pos));
               half3 view_dir=normalize(UnityWorldSpaceViewDir(world_pos));
               half3 reflect_dir=reflect(-view_dir,world_normal);

               UNITY_LIGHT_ATTENUATION(atten,i,world_pos);

               half3 half_dir=normalize(light_dir+view_dir);
               half n_dot_v=saturate(dot(world_normal,view_dir));
               half n_dot_l=saturate(dot(world_normal,light_dir));
               half n_dot_h=saturate(dot(world_normal,half_dir));
               half l_dot_v=saturate(dot(light_dir,view_dir));
               half l_dot_h=saturate(dot(light_dir,half_dir));

               //Diffuse Term
               half3 diffuse_term=CustomDisneyDiffuseTerm(n_dot_v,n_dot_l,l_dot_h,roughness,diffuse_color);
               //Specular Term
               half v= CustomGGXVisibilityTerm(n_dot_l,n_dot_v,roughness);
               half d=CustomGGXNormalTerm(n_dot_h,roughness * roughness);
               half3 f=CustomFresnelTerm(spec_color,l_dot_h);
               half3 specular_term= f * v * d;
               //Self-Emission  Term
               half3 emission_term = tex2D(emission_map, i.uv).rgb * emission_color.rgb;
               //IBL 对环境贴图进行LOD采样
               half perceptual_roughness =roughness * (1.7-0.7 * roughness);
               half mip = perceptual_roughness * 6;//放大roughness以在多级mipmap中采样
               half4 env_color = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflect_dir,mip);//SpecCube0 代表周围的reflection probe包含的环境贴图，默认是skybox的环境贴图
               half grazing_term= saturate((1-roughness) + reflect_scale);
               half surface_reduction = 1.0 / (roughness * roughness +1.0);
               half3 indirect_specular=surface_reduction * env_color.rgb * CustomFresnelLerp(spec_color,grazing_term,n_dot_v);

               half3 color = emission_term+UNITY_PI * (diffuse_term + specular_term) * _LightColor0.rgb * n_dot_l * atten + indirect_specular;
               UNITY_APPLY_FOG(i.fogCoord,color.rgb);
               return half4(color,1);
            }
            ENDCG 
        }
    }
    FallBack "Diffuse"

}
