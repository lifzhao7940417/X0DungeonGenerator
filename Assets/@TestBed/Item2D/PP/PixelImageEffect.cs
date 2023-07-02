using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PixelImageEffect : MonoBehaviour
{
    // Start is called before the first frame update
    public Material effectMaterial;


    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, effectMaterial);
    }
}
