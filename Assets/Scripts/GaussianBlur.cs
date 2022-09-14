using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostProcessBase
{
    // Start is called before the first frame update
    public int blur_times = 1;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material == null)
            Graphics.Blit(source, destination);

        RenderTexture temp=RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        Graphics.Blit(source, temp);

        for (int i = 0; i < blur_times; i++)
        {
            Graphics.Blit(source, temp, material,0);
            Graphics.Blit(temp, source,material,0);
        }

        Graphics.Blit(source, destination);
        RenderTexture.ReleaseTemporary(temp);
    }
}
