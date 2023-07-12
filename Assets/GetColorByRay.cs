using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

public class GetColorByRay : MonoBehaviour
{
    public GameObject text;

    void Start()
    {
        
    }


    void Update()
    {
        GetColor();
    }

    public Color Color;

    public Color NoiseColor(Color inColor)
    {
        Color newC= inColor;

        float R =Mathf.SmoothStep(0,1, inColor.r) ;
        float G = Mathf.SmoothStep(0, 1, inColor.g);
        float B = Mathf.SmoothStep(0, 1, inColor. b);

        if (R == G && G == B)
        {
            newC = new Color(1, 1, 1, 1);// _F.rgb;
        }
        else
        {
            if (R > G)
            {
                if (G > B)
                {
                    newC = new Color(0.15F, 0.15F, 0.15F, 1);//  col.rgb = _A.rgb;
                }
                else
                {
                    newC = new Color(0.3F, 0.3F, 0.3F, 1);//  col.rgb = _B.rgb;
                }
            }
            else if (G > B)
            {
                if (B > R)
                {
                    newC = new Color(0.45F, 0.45F, 0.45F, 1);// col.rgb = _C.rgb;
                }
                else
                {
                    newC = new Color(0.6F, 0.6F, 0.6F, 1);//  col.rgb = _D.rgb;
                }
            }
            else if (B > R)
            {
                if (G > R)
                {
                    newC = new Color(0.75F, 0.75F, 0.75F, 1);//  col.rgb = _E.rgb;
                }
                else
                {
                    newC = new Color(1, 1, 1, 1);//col.rgb = _F.rgb;
                }
            }
        }

        return newC;
    }

    [Button("GetColor")]
    private void GetColor()
    {
        RaycastHit hit;
        if (Physics.Raycast(this.transform.position, Vector3.down, out hit))
        {
            Debug.LogError(hit.collider.gameObject.name);

            Renderer rend = hit.transform.GetComponent<Renderer>();
            MeshCollider meshCollider = hit.collider as MeshCollider;

            if (rend == null || rend.sharedMaterial == null || rend.sharedMaterial.mainTexture == null || meshCollider == null)
                return;

            Texture2D tex = rend.sharedMaterial.mainTexture as Texture2D;
            Vector2 pixelUV = hit.textureCoord;
            pixelUV.x *= tex.width;
            pixelUV.y *= tex.height;

            Color = tex.GetPixel((int)pixelUV.x, (int)pixelUV.y);

            Color = NoiseColor(Color);
        }

        text.GetComponent<TextMesh>().color= Color;
    }
}
