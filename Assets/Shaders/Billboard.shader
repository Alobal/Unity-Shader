// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Starter/Billboard"
{   //�����������¹����µĻ���������ת����
    Properties
    {
        main_tex ("Main Tex",2D) ="white" {}
        main_color ("Main Color",Color) =(1,1,1,1)
        vertical_restraints ("Vertical Restraints",Range(0,1))=1
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "DisableBatching"="True" //������ᵼ��ÿ��ģ�͵�����ģ�Ϳռ䶪ʧ�������޷���ģ�Ϳռ��������㶯����
        }
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            ZWrite Off
            Cull Off //����cull off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"


            sampler2D main_tex;
            float4 main_tex_ST;
            fixed4 main_color;
            float vertical_restraints;

            struct a2v
            {
                float4 vertex :  POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f 
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            v2f vert (a2v v)
            {
			 	v2f o;
                float3 center_pos = float3(0,0,0);
                float3 viewer_pos=mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));//�����ģ�Ϳռ��λ��
                float3 normal=viewer_pos-center_pos;
                normal.y*=vertical_restraints;
                normal=normalize(normal);

                //������ʱ�����������right up  ע��������ʱ���������normalƽ�� ���²������
                float3 up=abs(normal.y)>0.999? float3(0,0,1): float3(0,1,0);
                float3 right=normalize(cross(up,normal));
                up=normalize(cross(normal,right));

                float3 local_pos=center_pos+right*v.vertex.x+up*v.vertex.y+normal*v.vertex.z;

                o.pos=UnityObjectToClipPos(float4(local_pos,1));
                o.uv=TRANSFORM_TEX(v.texcoord,main_tex);
			 	return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed4 color=tex2D(main_tex,i.uv);

                return color*main_color;
            }
            ENDCG
        }

    }

}
