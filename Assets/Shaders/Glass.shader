// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Starter/Glass"
{
    Properties
    {
        _MainTex ("Main Tex",2D)="white" {}
        _BumpMap("Normal Map",2D)="bump" {}
        _Cubemap("Environment Map",Cube)="_Skybox"{}
        _Distortion("Refraction Distortion",Range(0,100))=100
        _RefractAmount("Refract Amount",Range(0,1))=1

    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Opaque"
        }
        
        GrabPass{"_RefractionTex"}//string�����洢���������

        Pass
        {
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _Cubemap;
            
            float _Distortion;
            float _RefractAmount;

            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;//���ش�С

            struct a2v
            {
                float4 vertex :  POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 screen_pos : TEXCOORD1;
                float4 tangent_to_world0 : TEXCOORD2;
                float4 tangent_to_world1 : TEXCOORD3;
                float4 tangent_to_world2 : TEXCOORD4;

            };


            v2f vert (a2v v)
            {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);

			 	o.uv.xy=TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw=TRANSFORM_TEX(v.texcoord,_BumpMap);

                o.screen_pos=ComputeGrabScreenPos(o.pos);//MVP����ת������Ļ�������꣬��������γ��������ӿ����꣬��Ϊ��γ���ֻ����Frag����

                //���취�ߴ����߿ռ�תΪ����ռ�ı任����
                fixed3 world_pos=mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 world_normal=UnityObjectToWorldNormal(v.normal);
                fixed3 world_tangent=UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 world_binormal = cross(world_normal,world_tangent)*v.tangent.w;
			 	o.tangent_to_world0=float4(world_tangent.x,world_binormal.x,world_normal.x,world_pos.x);
			 	o.tangent_to_world1=float4(world_tangent.y,world_binormal.y,world_normal.y,world_pos.y);
			 	o.tangent_to_world2=float4(world_tangent.z,world_binormal.z,world_normal.z,world_pos.z);

			 	return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                float3 world_pos=float3(i.tangent_to_world0.w,i.tangent_to_world1.w,i.tangent_to_world2.w);
                fixed3 world_view=normalize(UnityWorldSpaceViewDir(world_pos));
                
                //ͨ�������Ŷ���������仯
                fixed3 bump=UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                float2 offset=bump.xy * _Distortion * _RefractionTex_TexelSize.xy;//ƫ�ƶ��ٸ�����
                i.screen_pos.xy=i.screen_pos.xy+offset;
                i.screen_pos.xy=i.screen_pos.xy/i.screen_pos.w;//�����ӿ�����

                //����Ļͼ���Ͻ���ƫ�Ʋ���
                fixed3 refract_color=tex2D(_RefractionTex,i.screen_pos.xy).rgb;

                //����ռ��µ��Ŷ����߷��� �����Ŷ���ķ��߼��㷴��
                bump=normalize(float3(dot(i.tangent_to_world0.xyz,bump),dot(i.tangent_to_world1.xyz,bump),dot(i.tangent_to_world2.xyz,bump)));
                fixed3 reflect_dir=reflect(-world_view,bump);
                fixed4 tex_color=tex2D(_MainTex,i.uv.xy);
                fixed3 reflect_color=texCUBE(_Cubemap,reflect_dir).rgb *tex_color.rgb;
                fixed3 color=reflect_color * (1-_RefractAmount) +refract_color*_RefractAmount;


                return fixed4(color,1);
            }
            ENDCG
        }

    }

}
