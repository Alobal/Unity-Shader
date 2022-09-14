using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeCG : PostProcessBase
{
    // Start is called before the first frame update
    [Range(0f, 1f)]
    public float base_alpha = 0f;
    public Color edge_color = Color.black;
    public Color background_color = Color.white;
    public float sample_distance = 1.0f;
    public float depth_threshold = 1f;
    public float normal_threshold=1f;

    [ImageEffectOpaque]//在opaque之后，transparent之前执行。
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material == null)
            Graphics.Blit(source, destination);

        material.SetFloat("base_alpha",(1.0f-base_alpha));
        material.SetColor("edge_color", edge_color);
        material.SetColor("background_color", background_color);
        material.SetFloat("sample_distance", sample_distance);
        material.SetFloat("depth_threshold", depth_threshold);
        material.SetFloat("normal_threshold", normal_threshold);

        Graphics.Blit(source, destination, material);
    }

    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode|=DepthTextureMode.DepthNormals;
    }
}
