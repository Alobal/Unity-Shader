Shader "Starter/SpecularFrag"
{
    Properties
    {
        _Diffuse ("Diffuse",Color)=(1,1,1,1)
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

            fixed4 _Diffuse;
            fixed4 _Specular;
            half _Gloss;

            struct a2v
            {
                float4 vertex :  POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 vertex :  TEXCOORD0;
                float3 normal : TEXCOORD1;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //获取环境光信息
                o.vertex=mul(unity_ObjectToWorld,v.vertex).xyz;
                //model to world 逆转置乘法。将法线从模型坐标变换为世界坐标
                o.normal=normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //定向光不存在pos，取pos就是顶点指向光的光照方向。
                fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);
                //reflect要求光指向顶点的光照方向，因此取反
                fixed3 reflectDir= normalize(reflect(-worldLightDir,i.normal));
                fixed3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.vertex);
                
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse=_LightColor0.rgb * _Diffuse.rgb * saturate(dot(i.normal,worldLightDir));
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(saturate(dot(reflectDir,viewDir)),_Gloss);
                fixed3 color=ambient+diffuse+specular;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
