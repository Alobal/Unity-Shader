using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class PostProcessBase : MonoBehaviour
{
    public Shader shader;
    private Material m_material;
    public Material material
    {
        get
        {
            m_material = CreatePostMaterial(shader, m_material);
            return m_material;
        }
    }

    protected Material CreatePostMaterial(Shader s, Material m)
    {
        if (s == null || s.isSupported==false)
            return null;
        if (m && m.shader==s)
            return m;

        Material material = new Material(s);
        material.hideFlags = HideFlags.DontSave;
        if (material)
            return material;
        else 
            return null;
        
    }
     

}
