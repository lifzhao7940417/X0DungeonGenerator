using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using static UnityEngine.UIElements.UxmlAttributeDescription;

public enum samplerTexChannel { R, G, B, A }

[System.Serializable]
public class PlantFenceLayer
{
    public Tex2PlantMesh BaseLeader;
    [LabelText("围栏层--生成物预制体")]
    public GameObject testPlantExample;
    [LabelText("围栏层--植被密度、尺寸、材质Index、材质Clip")]
    public Vector4 fenceParam =new Vector4(32,0.01f,0,0.45f);
    [LabelText("围栏层--植被采样通道")]
    public samplerTexChannel samplerTexChannel;
    //[LabelText("围栏层--植被分布图")]
    //public Texture2D texFence;
    //[LabelText("围栏层--植被集群图")]
    //public Texture2D texFenceIndex;
    [LabelText("围栏层--植被随机位置")]
    [Range(0,5)]
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
    private int LayerMask1;
    Color GetColorBySelection(Vector3 startPos, Vector3 forward)
    {
        LayerMask1 = 1 << LayerMask.NameToLayer("FenceIndexGeneration");
        Color color = Color.black;
        if (Physics.Raycast(startPos, forward, out hit,10, LayerMask1))
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

    public (Color,int) NoiseColor(Color inColor)
    {
        Color newC = inColor;
        int index = 0;

        float R = Mathf.SmoothStep(0, 1, inColor.r);
        float G = Mathf.SmoothStep(0, 1, inColor.g);
        float B = Mathf.SmoothStep(0, 1, inColor.b);

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
                    index = 0;
                }
                else
                {
                    newC = new Color(0.3F, 0.3F, 0.3F, 1);//  col.rgb = _B.rgb;
                    index = 1;
                }
            }
            else if (G > B)
            {
                if (B > R)
                {
                    newC = new Color(0.45F, 0.45F, 0.45F, 1);// col.rgb = _C.rgb;
                    index = 2;
                }
                else
                {
                    newC = new Color(0.6F, 0.6F, 0.6F, 1);//  col.rgb = _D.rgb;
                    index = 3;
                }
            }
            else if (B > R)
            {
                if (G > R)
                {
                    newC = new Color(0.75F, 0.75F, 0.75F, 1);//  col.rgb = _E.rgb;
                    index = 4;
                }
                else
                {
                    newC = new Color(1, 1, 1, 1);//col.rgb = _F.rgb;
                }
            }
        }

        return (newC, index);
    }


    private RaycastHit hit2;
    private int LayerMask2;
    public int GetFencePartFromNoise(Vector3 startPos, Vector3 forward)
    {
        int addIndex = 0;
        Color color = Color.black;
        LayerMask2 = 1 << LayerMask.NameToLayer("FenceIndexPartNoise");
        if (Physics.Raycast(startPos, forward, out hit2,10, LayerMask2))
        {

            Renderer rend = hit2.transform.GetComponent<Renderer>();
            MeshCollider meshCollider = hit2.collider as MeshCollider;

            if (rend == null || rend.sharedMaterial == null || rend.sharedMaterial.mainTexture == null || meshCollider == null)
                return 0;

            Texture2D tex = rend.sharedMaterial.mainTexture as Texture2D;
            Vector2 pixelUV = hit2.textureCoord;
            pixelUV.x *= tex.width;
            pixelUV.y *= tex.height;

            color = tex.GetPixel((int)pixelUV.x, (int)pixelUV.y);

            addIndex = NoiseColor(color).Item2;
        }

        return addIndex;
    }


    [GUIColor(0, 1, 0, 1)]
    [Button("刷新模型")]
    public void FreshObj()
    {
        if (BaseLeader.gridIDObj != null)
        {
            BaseLeader. gridIDObj.transform.localScale = Vector3.one * BaseLeader.gridParam;
        }

        MaterialPropertyBlock props = new MaterialPropertyBlock();
        for (int i = 0; i < fencObj.Count; i++)
        {
            var startPos = fencObj[i].transform.position + Vector3.up;
            var dir = Vector3.down;
            var scaleGreyValue = GetColorBySelection(startPos, dir);//从贴图上可以分出具体的灰度
            var index = (int)fenceParam.z;//index初始值

            int TexIndex = index + GetFencePartFromNoise(startPos, dir); //UnityEngine.Random.Range(0, 5);
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

            var TexAllCount = fencObj[i].GetComponent<Renderer>().sharedMaterial.GetInt("_AllCount");

            if (fencObj[i].GetComponent<UVEvaluation>())
            {
                var uve = fencObj[i].GetComponent<UVEvaluation>();
                uve.Index = TexIndex;
                uve.AllCount = TexAllCount;
            }
            else
            {
                var uve = fencObj[i].AddComponent<UVEvaluation>();
                uve.Index = TexIndex;
                uve.AllCount = TexAllCount;
            }

            fencObj[i].GetComponent<Renderer>().SetPropertyBlock(props);

            var target = fencObj[i];

            target.name = name;
            target.transform.localScale = Vector3.one * scaleTrans;
            target.transform.localPosition = RandomPos(new Vector3(target.transform.localPosition.x, 0, target.transform.localPosition.z));
        }
    }

    [Button("生成模型")]
    public void Generation()
    {
        //计算网格位置
        transSacle = BaseLeader.gridParam * 10;
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
        Clear();

        //生成网格点上的物体
        for (int i = 0; i < targetGrid * targetGrid; i++)
        {
            var tarPos = pos[i];

            if (tarPos.x < 211 && tarPos.z > -202)
            {
                if (testPlantExample)
                {
                    var target = GameObject.Instantiate(testPlantExample);
                    target.transform.localRotation = Quaternion.Euler(new Vector3(33.0f, 0, 0));
                    target.transform.position = pos[i];
                    target.transform.SetParent(trans);
                    fencObj.Add(target);
                }
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

    [GUIColor(1, 0, 0, 1)]
    [Button("删除模型")]
    public void Clear()
    {
        while (fencObj.Count>0) 
        {
            var go = fencObj[0].gameObject;
            GameObject.DestroyImmediate(go);
            fencObj.RemoveAt(0);
        }

        fencObj = new List<GameObject>();
    }
}

public class Tex2PlantMesh : MonoBehaviour
{
    [ReadOnly]
    //这里故意写死45时因为距离节奏刚刚好，如果要做小范围的fence，建议图片上区域小一点就可以了
    [LabelText("围栏层--最大范围（为何写死？看注释）")]
    public float gridParam = 45;
    [LabelText("围栏层--脚底遮罩片")]
    public GameObject gridIDObj;

    public List<PlantFenceLayer> PlantFenceDataArray = new List<PlantFenceLayer>();

    private void OnEnable()
    {
        FreshAll();
    }

    [Button("刷新Fence（All）")]
    [GUIColor(0,1,0,1)]
    private void FreshAll()
    {
        for (int i = 0; i < PlantFenceDataArray.Count; i++)
        {
            PlantFenceDataArray[i].FreshObj();
        }
    }
    [Button("生成Fence（All）")]
    private void GeneraAll()
    {
        for (int i = 0; i < PlantFenceDataArray.Count; i++)
        {
            PlantFenceDataArray[i].Generation();
        }
    }

    [Button("删除Fence（All）")]
    [GUIColor(1, 0, 0, 1)]
    private void DeleAll()
    {
        for (int i = 0; i < PlantFenceDataArray.Count; i++)
        {
            PlantFenceDataArray[i].Clear();
        }


        while (this.transform.childCount > 0)
        {
            var go = this.transform.GetChild(0).gameObject;
            GameObject.DestroyImmediate(go);
        }
    }
}
