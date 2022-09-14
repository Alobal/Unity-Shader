// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Starter/SingleTexture"
{
    Properties
    {
        _Color ("Color Tint",Color) =(1,1,1,1)
        _MainTex ("MainTex",2D)="white" {}
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
            sampler2D _MainTex;
            //纹理属性
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord: TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 world_normal : TEXCOORD0;
                float3 world_pos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v a)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(a.vertex);
                o.world_normal=UnityObjectToWorldNormal(a.normal);
                o.world_pos=mul(unity_ObjectToWorld,a.vertex).xyz;
                o.uv=a.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 world_normal=normalize(i.world_normal);
                fixed3 world_lightdir=normalize(UnityWorldSpaceLightDir(i.world_pos));

                fixed3 albedo=tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse=_LightColor0.rgb * albedo * saturate(dot(world_normal,world_lightdir)*0.5+fixed3(0.5,0.5,0.5));

                fixed3 view_dir=normalize(UnityWorldSpaceViewDir(i.world_pos));
                fixed3 half_dir=normalize(world_lightdir+view_dir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(world_normal,half_dir)),_Gloss);

                return fixed4(ambient+diffuse+specular,1.0);
            }
            ENDCG
        }

    }
}
