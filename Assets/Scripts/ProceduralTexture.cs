using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ProceduralTexture : MonoBehaviour
{

    public Material material=null;
    private Texture2D generated_texture = null;

    #region Material properties
    [SerializeField]
    private int m_texture_width = 512;

    public int textrue_width
    {
        get { return m_texture_width; }

        set 
        { 
            m_texture_width = value;
            UpdateMaterial();
        }
    }

    [SerializeField]
    private Color m_background_color=Color.blue;
    public Color background_color
    {
        get { return m_background_color; }
        set
        {
            m_background_color = value;
            UpdateMaterial();
        }
    }

    private Color m_circle_color = Color.white;
    public Color circle_color
    {
        get { return m_circle_color; }
        set
        {
            m_circle_color = value;
            UpdateMaterial();
        }
    }

    private float m_blur_factor = 2.0f;
    public float blur_factor
    {
        get { return m_blur_factor; }
        set
        {
            m_blur_factor = value;
            UpdateMaterial();
        }
    }
    #endregion

    // Start is called before the first frame update
    void Start()
    {
        if(material==null)
        {
            Renderer renderer=gameObject.GetComponent<Renderer>();
            if(renderer==null)
            {
                Debug.LogWarning("找不到renderer");
                return;
            }
            material = renderer.sharedMaterial;
            UpdateMaterial();
        }
    }

    private void Awake()
    {
        textrue_width = 1024;
    }

    void UpdateMaterial()
    {
        if(material!=null)
        {
            generated_texture = GenerateProceduralTexture();
            material.SetTexture("_MainTex",generated_texture);
        }
    }

    Texture2D GenerateProceduralTexture()
    {
        Texture2D procedural_texture = new Texture2D(textrue_width, textrue_width);
        float circle_interval = m_texture_width / 4.0f;
        float radius = textrue_width / 10.0f;
        float edge_blur = 1.0f / blur_factor;
        for (int w=0;w<textrue_width; w++)
        {
            for(int h=0;h<textrue_width;h++)
            {
                Color pixel = background_color;//像素初始色
                for (int i=0;i<3;i++)
                {
                    for(int j=0;j<3;j++)
                    {
                        Vector2 cicle_center = new Vector2(circle_interval * (i + 1), circle_interval*(j+1));
                        float dist = Vector2.Distance(new Vector2(w, h), cicle_center) - radius;
                        //像素根据circle距离变色
                        Color color = MixColor(circle_color, pixel, Mathf.SmoothStep(0f, 1.0f, dist * edge_blur));
                        pixel = MixColor(pixel, color, color.a);
                    }
                }
                procedural_texture.SetPixel(w, h, pixel);
            }
        }

        procedural_texture.Apply();
        return procedural_texture;
    }


    Color MixColor(Color a,Color b,float factor)
    {
        Color mix_color = Color.white;
        mix_color.r=Mathf.Lerp(a.r,b.r,factor);
        mix_color.g=Mathf.Lerp(a.g,b.g,factor);
        mix_color.b=Mathf.Lerp(a.b,b.b,factor);
        mix_color.a=Mathf.Lerp(a.a,b.a,factor);

        return mix_color;
    }
    // Update is called once per frame
    void Update()
    { 
    }

}
