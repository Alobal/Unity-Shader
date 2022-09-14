using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostProcessBase
{
    public float blur_size = 1;
    private Matrix4x4 VP;
    private Camera m_camera;
    new public Camera camera
    {
        get
        {
            if(m_camera == null)
                m_camera = GetComponent<Camera>();
            return m_camera;
        }
    }
    private void OnEnable()
    {
        camera.depthTextureMode|=DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
            Graphics.Blit(source, destination);

        material.SetFloat ("blur_size", blur_size);
        material.SetMatrix("VP_last", VP);
        VP=camera.projectionMatrix*camera.worldToCameraMatrix;
        material.SetMatrix("VP_inverse", VP.inverse);//逆MVP矩阵，用于从深度图NDC坐标重建世界坐标

        Graphics.Blit(source, destination, material);
    }
}
