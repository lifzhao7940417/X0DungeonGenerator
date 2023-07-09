using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using static Tex2PlantMesh;

public enum samplerTexChannel { R, G, B, A }

[System.Serializable]
public class PlantFenceLayer
{
    [ReadOnly]
    [LabelText("围栏层-网格高度、缩放、朝向")]
    public Vector3 gridParam=new Vector3(0,45,33);
    [LabelText("围栏层--生成物预制体")]
    public GameObject testPlantExample;
    [LabelText("围栏层--植被密度、尺寸、材质Index、材质Clip")]
    public Vector4 fenceParam =new Vector4(32,0.01f,0,0.45f);
    [LabelText("围栏层--植被采样通道")]
    public samplerTexChannel samplerTexChannel;
    [LabelText("围栏层--植被分布图")]
    public Texture2D texFence;
    [LabelText("围栏层--植被随机位置")]
    [Range(0,1)]
    public float RangePos=1;
    [LabelText("围栏层--植被Root")]
    public Transform trans;
    [ReadOnly]
    public List<GameObject> fencObj=new List<GameObject>();

    private Vector3 startPos = new Vector3(0, 0, 0);
    private Vector3[] pos;
    private float girdsize;
    private float transSacle;

    public static void Vector3Rotate(ref Vector3 source, Vector3 axis, float angle)
    {
        Quaternion q = Quaternion.AngleAxis(angle, axis);// 旋转系数
        source = q * source;
    }

    public Vector3 RandomPos(Vector3 inPos)
    {
        Vector2 random = Random.insideUnitCircle;
        inPos.x += random.x* RangePos;
        inPos.z += random.y* RangePos;
        return inPos;
    }

    private RaycastHit hit;
    Color GetColorBySelection(Vector3 startPos, Vector3 forward)
    {
        Color color = Color.black;
        if (Physics.Raycast(startPos, forward, out hit))
        {
            Renderer rend = hit.transform.GetComponent<Renderer>();
            MeshCollider meshCollider = hit.collider as MeshCollider;

            if (rend == null || rend.sharedMaterial == null || rend.sharedMaterial.mainTexture == null || meshCollider == null)
                return Color.black;

            Texture2D tex = rend.sharedMaterial.mainTexture as Texture2D;
            Vector2 pixelUV = hit.textureCoord;
            pixelUV.x *= tex.width;
            pixelUV.y *= tex.height;

            color = tex.GetPixel((int)pixelUV.x, (int)pixelUV.y);
        }
        return color;
    }

    [GUIColor(0, 1, 0, 1)]
    [Button("刷新模型")]
    public void FreshObj()
    {
        MaterialPropertyBlock props = new MaterialPropertyBlock();
        for (int i = 0; i < fencObj.Count; i++)
        {
            var startPos = fencObj[i].transform.position + Vector3.up;
            var dir = Vector3.down;
            var scaleGreyValue = GetColorBySelection(startPos, dir);//从贴图上可以分出具体的灰度
            var index = (int)fenceParam.z;

            int TexIndex = index + UnityEngine.Random.Range(0, 4);
            float alphaClip = fenceParam.w;
            float scaleTrans = fenceParam.y;
            var name = "Fence";

            switch (samplerTexChannel)
            {
                case samplerTexChannel.R:
                    name += "_R";
                    if (scaleGreyValue.r < 1)
                        scaleTrans = 0;
                    scaleGreyValue = new Color(scaleGreyValue.r, scaleGreyValue.r, scaleGreyValue.r, 1);


                    name += "_" + scaleGreyValue.r.ToString();
                    break;
                case samplerTexChannel.G:
                    name += "_G";
                    if (scaleGreyValue.g < 1)
                        scaleTrans = 0;
                    scaleGreyValue = new Color(scaleGreyValue.g, scaleGreyValue.g, scaleGreyValue.g, 1);


                    name += "_" + scaleGreyValue.g.ToString();
                    break;
                case samplerTexChannel.B:
                    name += "_B";
                    if (scaleGreyValue.b < 1)
                        scaleTrans = 0;
                    scaleGreyValue = new Color(scaleGreyValue.b, scaleGreyValue.b, scaleGreyValue.b, 1);


                    name += "_" + scaleGreyValue.b.ToString();
                    break;
                case samplerTexChannel.A:
                    name += "_A";
                    if (scaleGreyValue.a < 1)
                        scaleTrans = 0;
                    scaleGreyValue = new Color(scaleGreyValue.a, scaleGreyValue.a, scaleGreyValue.a, 1);
                    name += "_" + scaleGreyValue.a.ToString();
                    break;
            }


            int targetGrid = (int)fenceParam.x;
            float zoffsetStep = 0.001f;
            float zoffset = ((i % targetGrid) - (int)(targetGrid * 0.5f)) * zoffsetStep;

            props.SetColor("_BaseColor", scaleGreyValue);
            props.SetInt("_TexIndex", TexIndex);
            props.SetFloat("_ZOffset", zoffset);
            props.SetFloat("_AlphaClip", alphaClip);

            fencObj[i].GetComponent<Renderer>().SetPropertyBlock(props);

            var target = fencObj[i];

            target.name = name;
            target.transform.localScale = Vector3.one * scaleTrans;
            target.transform.localPosition = RandomPos(new Vector3(target.transform.localPosition.x, 0 + gridParam.x, target.transform.localPosition.z));
        }
    }

    [Button("生成模型")]
    public void Generation()
    {
        transSacle = gridParam.y* 10;
        int targetGrid = (int)fenceParam.x;
        pos = new Vector3[targetGrid * targetGrid];

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

        //删除旧资产
        for (int i = 0; i < fencObj.Count; i++)
        {
            var obj = fencObj[i];
            GameObject.DestroyImmediate(obj);
        }


        fencObj = new List<GameObject>();

        //生成网格点上的物体
        for (int i = 0; i < targetGrid * targetGrid; i++)
        {
            if (testPlantExample)
            {
                var target = GameObject.Instantiate(testPlantExample);
                target.transform.localRotation = Quaternion.Euler(new Vector3(gridParam.z, 0,0));
                target.transform.position = pos[i];
                target.transform.SetParent(trans);
                fencObj.Add(target);
            }
        }

        FreshObj();

        List<GameObject> temp = new List<GameObject>();
        for (int i = 0; i < fencObj.Count; i++)
        {
            var target = fencObj[i];
            if (target.transform.localScale == Vector3.zero)
            {
                temp.Add(target.gameObject);
            }
        }

        for (int i = 0; i < temp.Count; i++)
        {
            fencObj.Remove(temp[i]);
            var obj = temp[i];
            GameObject.DestroyImmediate(obj);
        }
    }

    public void Clear()
    {
        fencObj=new List<GameObject>();
    }
}

public class Tex2PlantMesh : MonoBehaviour
{
    public List<PlantFenceLayer> PlantFenceDataArray = new List<PlantFenceLayer>();

    private void OnEnable()
    {
        FreshAll();
    }

    private bool lastflag = true;
    [Button("辅助：隐藏/显示Fence图")]
    private void RenderFloor()
    {
        lastflag = !lastflag;
        var render = this.transform.GetComponent<Renderer>();
        if (render)
            render.enabled = lastflag;
    }
    [Button("刷新所有层的植被样式")]
    [GUIColor(0,1,0,1)]
    private void FreshAll()
    {
        for (int i = 0; i < PlantFenceDataArray.Count; i++)
        {
            PlantFenceDataArray[i].FreshObj();
        }
    }
    [Button("创建所有层的植被预制体")]
    [GUIColor(0, 1, 1, 1)]
    private void GeneraAll()
    {
        for (int i = 0; i < PlantFenceDataArray.Count; i++)
        {
            PlantFenceDataArray[i].Generation();
        }
    }

    [Button("删除所有层植被预制体")]
    [GUIColor(1, 0, 0, 1)]
    private void DeleAll()
    {
        for (int i = 0; i < PlantFenceDataArray.Count; i++)
        {
            PlantFenceDataArray[i].Clear();
        }

        for (int i = 0; i < this.transform.childCount; i++)
        {
            var gameobject = this.transform.GetChild(0).gameObject;
            GameObject.DestroyImmediate(gameobject);
        }
    }
}
