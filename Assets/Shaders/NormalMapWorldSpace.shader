// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Starter/NormalMapWorldSpace"
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
                float4 uvuv : TEXCOORD0;
                float4 tan_to_world0 : TEXCOORD1;
                float4 tan_to_world1 : TEXCOORD2;
                float4 tan_to_world2 : TEXCOORD3;
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                //获取纹理坐标
                o.uvuv.xy=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uvuv.zw=TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 world_pos=mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 world_normal=UnityObjectToWorldNormal(v.normal);
                fixed3 world_tangent=UnityObjectToWorldDir(v.tangent.xyz);
                //计算副法线 tangent.w 决定binormal的正负方向
                fixed3 world_binormal=cross(normalize(world_normal),normalize(world_tangent))*v.tangent.w;
                //世界空间转为切线空间 world_to_tangent=float3x3(world_tangent,world_binormal,world_normal);
                //取逆得到 切线空间转为世界空间
                o.tan_to_world0=float4(world_tangent.x,world_binormal.x,world_normal.x,world_pos.x);
                o.tan_to_world1=float4(world_tangent.y,world_binormal.y,world_normal.y,world_pos.y);
                o.tan_to_world2=float4(world_tangent.z,world_binormal.z,world_normal.z,world_pos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 world_pos=float3(i.tan_to_world0.z,i.tan_to_world1.z,i.tan_to_world2.z);
                fixed3x3 tang_to_world=fixed3x3(i.tan_to_world0.xyz,i.tan_to_world1.xyz,i.tan_to_world2.xyz);
                //tex2d 获取 0~1 表示的法线 ,需要转换为-1~1。
                // 注意标记为Normal Map 时，并不是简单的范围转换packed_normal.xy*2-1，需要内置解包
                fixed4 packed_normal=tex2D(_BumpMap,i.uvuv.zw);
                fixed3 tangent_normal=UnpackNormal(packed_normal);
                tangent_normal.xy*=_BumpScale;
                tangent_normal.z=sqrt(1.0-saturate(dot(tangent_normal.xy,tangent_normal.xy)));

                fixed3 world_normal=normalize(mul(tang_to_world,tangent_normal));
                fixed3 world_light_dir=normalize(UnityWorldSpaceLightDir(world_pos));
                fixed3 world_view_dir=normalize(UnityWorldSpaceViewDir(world_pos));
                
                fixed3 albedo =tex2D(_MainTex,i.uvuv).rgb*_Color.rgb;
                fixed3 ambient =UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(world_normal,world_light_dir));

                fixed3 half_dir=normalize(world_view_dir+world_light_dir);
                fixed3 specular=_LightColor0 * _Specular.rgb * pow(saturate(dot(world_normal,half_dir)),_Gloss);

                return fixed4(ambient+diffuse+specular,1.0);
            }
            ENDCG
        }
    }
}
