Shader "Starter/DiffuseFragmentLevel"
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
    }
    SubShader
    {

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal: TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse=_LightColor0.rgb * _Diffuse.rgb *  (dot(f.worldNormal,worldLight)*0.5+fixed3(0.5,0.5,0.5));
                fixed4 color=fixed4(diffuse+ambient,1.0);
                return color;
            }

            ENDCG
        }
    }
    Fallback "Diffuse"
}
