using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using System.Reflection;

public class UVEvaluation : MonoBehaviour
{
    public int Index = -1;
    public int AllCount = 0;

    [Button("获取id")]
    public void GetIndex()
    {
        Material mat = null;
        var tag = this.transform.GetComponent<MeshRenderer>();
        if (tag)
        {
            mat = tag.material;
            Index = mat.GetInt("_TexIndex");
            if (mat.shader == Shader.Find("X0/Item/2D"))
            {
                
            }
        }
    }


    [Button("重新调整UV")]
    public void UVChecker()
    {
        if (Index < 0)
            return;

        Mesh mesh = GetComponent<MeshFilter>().mesh;
        Vector2[] baseUV = new Vector2[4];

        baseUV[0] = new Vector2(0, 0);
        baseUV[1] = new Vector2(0, 1);
        baseUV[2] = new Vector2(1, 1);
        baseUV[3] = new Vector2(1, 0);


        for (int i = 0; i < baseUV.Length; i++)
        {
            baseUV[i] = GetUVCheck(AllCount,baseUV[i], Index);
        }

        mesh.uv = baseUV;
    }


    Vector2 GetUVCheck(int inAllCount, Vector2 baseUV, int Index)
    {
        if (inAllCount == 20)
            return GetUVOMG20(baseUV, Index);
        else if (inAllCount == 9)
            return GetUVOMG9(baseUV, Index);
        else
            return baseUV;
    }

    Vector2 GetUVOMG9(Vector2 baseuv, int index)
    {
        Vector2 tilling = new Vector2(0.333f, 0.333f);
        if (index == 1)
            return baseuv * tilling + new Vector2(0, 0);
        else if (index == 2)
            return baseuv * tilling + new Vector2(0.333f, 0);
        else if (index == 3)
            return baseuv * tilling + new Vector2(0.666f, 0);
        else if (index == 4)
            return baseuv * tilling + new Vector2(0, 0.333f);
        else if (index == 5)
            return baseuv * tilling + new Vector2(0.333f, 0.333f);
        else if (index == 6)
            return baseuv * tilling + new Vector2(0.666f, 0.333f);
        else if (index == 7)
            return baseuv * tilling + new Vector2(0, 0.666f);
        else if (index == 8)
            return baseuv * tilling + new Vector2(0.333f, 0.666f);
        else if (index == 9)
            return baseuv * tilling + new Vector2(0.666f, 0.666f);
        else if (index < 1)
            return baseuv * tilling + new Vector2(0, 0);
        else if (index > 9)
            return baseuv * tilling + new Vector2(0.666f, 0.666f);
        else
            return baseuv;
    }

    Vector2 GetUVOMG20(Vector2 baseuv, int index)
    {
        Vector2 tilling = new Vector2(0.2f, 0.25f);
        if (index == 1)
            return baseuv * tilling + new Vector2(0, 0);
        else if (index == 2)
            return baseuv * tilling + new Vector2(0.2f, 0);
        else if (index == 3)
            return baseuv * tilling + new Vector2(0.4f, 0);
        else if (index == 4)
            return baseuv * tilling + new Vector2(0.6f, 0);
        else if (index == 5)
            return baseuv * tilling + new Vector2(0.8f,0);
        else if (index == 6)
            return baseuv * tilling + new Vector2(0, 0.25f);
        else if (index == 7)
            return baseuv * tilling + new Vector2(0.2f, 0.25f);
        else if (index == 8)
            return baseuv * tilling + new Vector2(0.4f, 0.25f);
        else if (index == 9)
            return baseuv * tilling + new Vector2(0.6f, 0.25f);
        else if (index == 10)
            return baseuv * tilling + new Vector2(0.8f, 0.25f);
        else if (index == 11)
            return baseuv * tilling + new Vector2(0, 0.5f);
        else if (index == 12)
            return baseuv * tilling + new Vector2(0.2f, 0.5f);
        else if (index == 13)
            return baseuv * tilling + new Vector2(0.4f, 0.5f);
        else if (index == 14)
            return baseuv * tilling + new Vector2(0.6f, 0.5f);
        else if (index == 15)
            return baseuv * tilling + new Vector2(0.8f, 0.5f);
        else if (index == 16)
            return baseuv * tilling + new Vector2(0, 0.75f);
        else if (index == 17)
            return baseuv * tilling + new Vector2(0.2f, 0.75f);
        else if (index == 18)
            return baseuv * tilling + new Vector2(0.4f, 0.75f);
        else if (index == 19)
            return baseuv * tilling + new Vector2(0.6f, 0.75f);
        else if (index == 20)
            return baseuv * tilling + new Vector2(0.8f, 0.75f);
        else if (index < 1)
            return baseuv * tilling + new Vector2(0, 0);
        else if (index > 20)
            return baseuv * tilling + new Vector2(0.8f, 0.75f);
        else
            return baseuv;
    }
}
