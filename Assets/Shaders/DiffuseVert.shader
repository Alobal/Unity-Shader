// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Starter/DiffuseVertexLevel"
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
                float4 vertex: POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 pos: SV_POSITION;
                fixed3 color : COLOR;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //获取环境光信息
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                //model to world 逆转置乘法。将法线从模型坐标变换为世界坐标
                fixed3 worldNormal=normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse=_LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));
                o.color=diffuse+ambient;

                return o;

            }

            fixed4 frag(v2f f):SV_Target
            {
                return fixed4(f.color,1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
