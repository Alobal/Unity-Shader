Shader "Starter/RampTexture"
{
    Properties
    {
        _Color("Color Tint",Color)=(1,1,1,1)
        _RampTex ("RampTeX",2d)="white" {}
        _Specular ("Specular", Color) =(1,1,1,1)
        _Gloss ("Gloss", Range(8.0,256)) =20

    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed4 _Specular;
            half _Gloss;

            struct a2v
            {
                float4 vertex :  POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 world_normal : TEXCOORD0;
                float3 world_pos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.world_pos=mul(unity_ObjectToWorld,v.vertex);
                o.world_normal=UnityObjectToWorldNormal(v.normal);
                o.uv=TRANSFORM_TEX(v.texcoord,_RampTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                fixed3 world_normal=normalize(i.world_normal);
                fixed3 world_light_dir=normalize(UnityWorldSpaceLightDir(i.world_pos));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //texture for diffuse  ， why use lambert to texcoord
                fixed half_lambert=0.5 * dot(world_normal,world_light_dir)+0.5;
                fixed3 texcolor=tex2D(_RampTex,fixed2(half_lambert,half_lambert)).rgb*_Color.rgb;
                fixed3 diffuse=_LightColor0.rgb * texcolor;

                fixed3 view_dir=normalize(UnityWorldSpaceViewDir(i.world_pos));
                fixed3 half_dir=normalize(view_dir+world_light_dir);
                fixed3 specular= _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(world_normal,half_dir)),_Gloss);
                
                return fixed4(diffuse+specular+ambient,1.0);
            }
            ENDCG
        }
    }
}
