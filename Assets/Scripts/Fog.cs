using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fog : PostProcessBase
{
    private Camera m_camera;
    new public Camera camera
    {
        get
        {
            if (m_camera == null)
                m_camera = GetComponent<Camera>();
            return m_camera;
        }
    }

    private Transform m_camera_transform;
    public Transform camera_transform
    {
        get
        {
            if(m_camera_transform==null)
                m_camera_transform = camera.transform;
            return m_camera_transform;
        }
    }

    [Range(0f, 1f)]
    public float fog_density = 0.3f;
    public Color fog_color=Color.white;
    public float fog_starth = 0f;
    public float fog_endh = 2.0f;
    public float fog_speedh = 1.0f;
    public float fog_speedv = 1.0f;
    public Texture noise_tex;
    public float noise_amount = 1.0f;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material==null)
            Graphics.Blit(source, destination);

        Matrix4x4 frustum_corners=Matrix4x4.identity;
        float fov = camera.fieldOfView;
        float near = camera.nearClipPlane;
        float aspect = camera.aspect;
        float half_h = near * Mathf.Tan(0.5f * fov * Mathf.Deg2Rad);
        Vector3 up = camera_transform.up * half_h;
        Vector3 right=camera_transform.right*half_h*aspect;
        Vector3 forward = camera_transform.forward * near;

        //各个方向的放缩向量，推导参考相似三角形
        Vector3 top_left = (forward+ up - right)/near; 
        Vector3 top_right =( forward+ up + right) / near;
        Vector3 bottom_left = (forward - up - right) / near;
        Vector3 bottom_right =( forward - up + right) / near;

        frustum_corners.SetRow(0, bottom_left);
        frustum_corners.SetRow(1, bottom_right);
        frustum_corners.SetRow(2, top_right);
        frustum_corners.SetRow(3, top_left);

        material.SetTexture("noise_tex", noise_tex);
        material.SetMatrix("frustum_corners", frustum_corners);
        material.SetMatrix("VP_inverse", (camera.projectionMatrix * camera.worldToCameraMatrix).inverse);
        material.SetFloat("fog_density", fog_density);
        material.SetFloat("fog_starth", fog_starth);
        material.SetFloat("fog_endh", fog_endh);
        material.SetColor("fog_color", fog_color);
        material.SetFloat("noise_amount", noise_amount);
        material.SetFloat("fog_speedh", fog_speedh);
        material.SetFloat("fog_speedv", fog_speedv);

        Graphics.Blit(source, destination, material);
    }
    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

}
