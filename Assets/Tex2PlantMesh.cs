using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using System;
using static UnityEditor.PlayerSettings;
using System.Reflection;
using System.Linq;
using TMPro;
using static UnityEngine.GraphicsBuffer;

public class Tex2PlantMesh : MonoBehaviour
{
    private Color[] grey2ScaleIndex;

    private Vector3 startPos = new Vector3(0, 0, 0);
    private float girdsize;
    private float transSacle;

    private Vector3[] pos;
    private Color[] color2TreeIndex;

    [LabelText("Χ��ͼ��Size��Grid����һ��")]
    public Texture2D DynamicTex;
    [LabelText("Noiseͼ����ȡ��Ӧ��ɫ����")]
    public Texture2D NoiseTex;
    [LabelText("Gird�ߴ�")]
    public int targetGrid = 32;
    [LabelText("Gizmo��ɫ")]
    public Color gizmoCol = Color.white;

    public GameObject testPlantExample;

    [Button("����λ���ϵ���ɫ��")]
    private void InitData()
    {
        transSacle = this.transform.localScale.x*10;
        GetPixel();
        CheckPos();
    }


    private bool lastflag = false;
    [Button("��ʾԭ��Mask��Χ")]
    private void RenderFloor()
    {
        lastflag = !lastflag;
        var render = this.transform.GetComponent<Renderer>();
        if (render)
            render.enabled = lastflag;
    }


    [ReadOnly]
    [LabelText("FenceȺ��")]
    public List<GameObject> testPlantExampleList = new List<GameObject>();
    [LabelText("FenceȺ��-PosY")][Range(-3, 3)]
    public float testPlantY = 1;
    [LabelText("FenceȺ��-Rotation")]
    public Vector3 testPlantR = new Vector3(33.33f, 0, 0);
    [LabelText("FenceȺ��-ScaleIntensity")]
    [Range(0, 5)]
    public float testPlantScale = 1;
    [LabelText("FenceȺ��-ScaleMinLimit-��ֹ<0��ֵ���ź�Ҳ������")]
    [Range(0,01)]
    [ReadOnly]
    public float scaleindexScaleMinLimit = 0.0f;
    [LabelText("FenceȺ��-ScaleRampMin")]
    public float scaleindexRampMin = 0;
    [LabelText("FenceȺ��-ScaleRampMax")]
    public float scaleindexRampMax = 1;

    [Button("����Χ��ScaleIndex������Ƭģ��")]
    private void CreatItemWithData()
    {
        for (int i = 0; i < testPlantExampleList.Count; i++)
        {
            var obj = testPlantExampleList[i];
            GameObject.DestroyImmediate(obj);
        }

        testPlantExampleList = new List<GameObject>();

        for (int i = 0; i < color2TreeIndex.Length; i++)
        {
            if (testPlantExample)
            {
                var target = GameObject.Instantiate(testPlantExample);
                target.transform.localRotation = Quaternion.Euler(testPlantR);
                target.transform.position = pos[i];
                target.transform.SetParent(this.transform);
                testPlantExampleList.Add(target);
            }
        }

        Adjust();
    }

    private void OnValidate()
    {
        InitData();
        Adjust();
    }

    int GetIndexFromGreyAndColorValue(float inScale,float inIntensity )
    {
        var valuePartIndex = UnityEngine.Random.Range(0, 5);
        var valueScaleIndex = 0;


        if (inScale < 0.25f* inIntensity)
            valueScaleIndex = 1;
        else if (inScale <= 0.5f * inIntensity)
            valueScaleIndex = 6;
        else if (inScale <= 0.75f * inIntensity)
            valueScaleIndex = 11;
        else
            valueScaleIndex = 16;


        return valuePartIndex+ valueScaleIndex;
    }

    private void Adjust()
    {
        MaterialPropertyBlock props = new MaterialPropertyBlock();

        for (int i = 0; i < testPlantExampleList.Count; i++)
        {
            var colorindex = color2TreeIndex[i];
            var scaleIndex = color2TreeIndex[i].a;

            if(scaleIndex > scaleindexScaleMinLimit)
                scaleIndex = Mathf.SmoothStep(scaleindexRampMin, scaleindexRampMax, scaleIndex);

            var target = testPlantExampleList[i];
            target.transform.localScale = Vector3.one * testPlantScale * scaleIndex;
            target.transform.localPosition = new Vector3(target.transform.localPosition.x, 0 + testPlantY, target.transform.localPosition.z);

            //scaleϵ������Ϊ4���ֶΣ���Ӧ��ͼ4�У���ϵ���ɻҶ�ֵ��0-1��ƽ���ֶζ���, scale ϵ��ֻ���ǣ�1��2��3��4��=>(1,6,11,16,)�������ͼ��Խ����ֲ��Խ��
            //Ⱥ��ֲ�ϵ������Ϊ5���ֶΣ���Ӧ��ͼ5�У���ϵ���ɲ�ɫֵ��0-255��ƽ���ֶζ��� ��ϵ��ֻ����֣�0��1��2��3��4��
            //����ϵ����������Ϊ��ϵ����scaleϵ��+Ⱥ��ֲ�ϵ������ֵȡֵ��Χ��1��20��

            int Index = GetIndexFromGreyAndColorValue(scaleIndex, testPlantScale);
            float zoffsetStep = 0.001f;
            float zoffset = ((i % 32) - (int)(targetGrid * 0.5f)) * zoffsetStep;

            //props.SetColor("_BaseColor", colorindex);
            props.SetInt("_TexIndex", Index);
            props.SetFloat("_ZOffset", zoffset);

            testPlantExampleList[i].GetComponent<Renderer>().SetPropertyBlock(props);
        }
    }

    private void GetPixel()
    {
        color2TreeIndex = NoiseTex.GetPixels();
        grey2ScaleIndex = DynamicTex.GetPixels();

        for (int i = 0; i < color2TreeIndex.Length; i++)
        {
            color2TreeIndex[i].a =1- grey2ScaleIndex[i].r;
        }
    }

    public static void Vector3Rotate(ref Vector3 source, Vector3 axis, float angle)
    {
        Quaternion q = Quaternion.AngleAxis(angle, axis);// ��תϵ��
        source = q * source;
    }

    private void CheckPos()
    {
        pos = new Vector3[targetGrid* targetGrid];

        startPos.x = -transSacle / 4;// + targetGrid * 0.1f;
        startPos.z = -transSacle / 4; //+ targetGrid * 0.1f;

        girdsize = transSacle / targetGrid;

        for (int i = 0; i < targetGrid; i++)
        {
            for (int j = 0; j < targetGrid; j++)
            {
                int index = i * targetGrid + j;
                
                var addPos = new Vector3();
                addPos.x = startPos.x + girdsize * (i + 0.5f);
                addPos.z = startPos.z + girdsize * (j + 0.5f);

                var finallPos = startPos + addPos;

                Vector3Rotate(ref finallPos, Vector3.up, 90);
                Vector3Rotate(ref finallPos, Vector3.right, 180);
                Vector3Rotate(ref finallPos, Vector3.up, 180);

                pos[index] = finallPos;
            }
        }
    }


    public enum GizmoColorTips
    {
        WalkableOrMask,
        LookUpColorID,
        ScaleLevel,
        ColorIDAndScaleLevel,
        Closed,
    }

    public GizmoColorTips gizmoColorType;

    private void OnDrawGizmos()
    {
        if (gizmoColorType == GizmoColorTips.Closed)
            return;

        for (int i = 0; i < pos.Length; i++)
        {
            Color color= Color.white;
            switch (gizmoColorType)
            {
                case GizmoColorTips.LookUpColorID:
                    color = color2TreeIndex[i];
                    Gizmos.color =  new Color(color.r, color.g, color.b, 1);
                    break;
                case GizmoColorTips.ColorIDAndScaleLevel:
                    color = color2TreeIndex[i];
                    Gizmos.color = color.a * new Color(color.r, color.g, color.b, 1);
                    break;
                case GizmoColorTips.ScaleLevel:
                    color = color2TreeIndex[i];
                    Gizmos.color = new Color(color.a, color.a, color.a, 1);
                    break;
                case GizmoColorTips.WalkableOrMask:
                    color = color2TreeIndex[i];
                    Gizmos.color = new Color(1-color.a, 1 - color.a, 1 - color.a, 1);
                    break;
                case GizmoColorTips.Closed:
                    color = color2TreeIndex[i];
                    Gizmos.color = new Color(1 - color.a, 1 - color.a, 1 - color.a, 0);
                    break;
                default:
                    color = color2TreeIndex[i];
                    Gizmos.color = new Color(1 - color.a, 1 - color.a, 1 - color.a, 1);
                    break;
            }
            Gizmos.DrawSphere(pos[i], girdsize * 0.5f);
        }
    }
}
