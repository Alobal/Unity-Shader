using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BrightnessSaturationContrast : PostProcessBase
{
    [Range(0f, 3f)]
    public float brightness = 1.0f;
    [Range(0f,3f)]
    public float saturation = 1.0f;
    [Range(0f, 3f)]
    public float contrast =1.0f;


    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material!=null)
        {
            material.SetFloat("brightness", brightness);
            material.SetFloat("saturation", saturation);
            material.SetFloat("contrast", contrast);
            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
