Shader "Starter/NormalMapTangentSpace"
{
    Properties
    {
        _Color("Color Tint",Color)= (1,1,1,1)
        _MainTex("Main Tex",2D)="white" {}
        _BumpMap("Normal Map",2D) = "bump" {}
        _BumpScale("Bump Scale",Float)=1.0
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
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            fixed _BumpScale;
            fixed4 _Specular;
            half _Gloss;

            struct a2v
            {
                float4 vertex :  POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0; //注意切线的w分量用于描述副切线
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 light_dir : TEXCOORD1;
                float3 view_dir : TEXCOORD2;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //获取纹理坐标
                o.uv.xy=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw=TRANSFORM_TEX(v.texcoord,_BumpMap);
                //计算副法线 tangent.w 决定binormal的正负方向
                float3 binormal=cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w;
                //模型空间转为切线空间
                float3x3 to_tangent_space=float3x3(v.tangent.xyz,binormal,v.normal);
                o.light_dir=mul(to_tangent_space,ObjSpaceLightDir(v.vertex)).xyz;
                o.view_dir=mul(to_tangent_space,ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tangent_light_dir=normalize(i.light_dir);
                fixed3 tangent_view_dir=normalize(i.view_dir);
                //tex2d 获取 0~1 表示的法线 ,需要转换为-1~1。
                fixed4 packed_normal=tex2D(_BumpMap,i.uv.zw);
                // 注意标记为Normal Map 时，并不是简单的范围转换packed_normal.xy*2-1，需要内置解包
                fixed3 tangent_normal=UnpackNormal(packed_normal);
                tangent_normal.xy*=_BumpScale;
                tangent_normal.z=sqrt(1.0-saturate(dot(tangent_normal.xy,tangent_normal.xy)));

                fixed3 albedo =tex2D(_MainTex,i.uv).rgb*_Color.rgb;
                fixed3 ambient =UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangent_normal,tangent_light_dir));

                fixed3 half_dir=normalize(tangent_view_dir+tangent_light_dir);
                fixed3 specular=_LightColor0 * _Specular.rgb * pow(saturate(dot(tangent_normal,half_dir)),_Gloss);

                return fixed4(ambient+diffuse+specular,1.0);
            }
            ENDCG
        }
    }
}
