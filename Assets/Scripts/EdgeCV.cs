using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeCV : PostProcessBase
{
    // Start is called before the first frame update
    [Range(0f, 1f)]
    public float base_alpha = 0f;
    public Color edge_color = Color.black;
    public Color background_color = Color.white;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material == null)
            Graphics.Blit(source, destination);

        material.SetFloat("base_alpha",1-base_alpha);
        material.SetColor("edge_color", edge_color);
        material.SetColor("background_color", background_color);
        Graphics.Blit(source, destination, material);
    }
}
