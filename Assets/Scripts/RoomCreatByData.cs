using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using UnityEditor.PackageManager;

public class RoomInfo
{
    public AreaDes des;
    public Vector3 pos;
    public Vector3 size;
    public Color color;
    public string prefabName;
    public Vector3 prefabScale;
    public Vector3 prefabRot;
}

public class RoomCreatByData : MonoBehaviour
{
    public bool Use2DRes;
    GameObject Root;
    GameObject ItemRoot;
    GameObject WaterRoot;
    GameObject InOutRoot;
    GameObject GrssRoot;
    private List<RoomInfo> roomInfos = new List<RoomInfo>();


    [InlineButton("CreatBaseRes", "���ɸò�")]
    public TextAsset TextJson_Base;
    public void CreatBaseRes()
    {
        GetRoot();
        CreatRes(TextJson_Base);
        Debug.LogError("���ײ��������");
    }

    //[InlineButton("Creat1stRes", "���ɸò�")]
    //public TextAsset TextJson_1First;
    //public void Creat1stRes()
    //{
    //    GetRoot();
    //    CreatRes(TextJson_1First);
    //    Debug.LogError("1st���������");
    //}

    [InlineButton("CreatLoad", "���ɵ�·")]
    public LineParamResources lineParamResources;
    public void CreatLoad()
    {

    }


    private void GetRoot()
    {
        if (Root == null)
        {
            Root = new GameObject("Root");
        }

        if (WaterRoot == null)
        {
            WaterRoot = new GameObject("@Water");
            WaterRoot.transform.SetParent(Root.transform);
        }

        if (GrssRoot == null)
        {
            GrssRoot = new GameObject("@Grass");
            GrssRoot.transform.SetParent(Root.transform);
            GrssRoot.AddComponent<AdjustTools>();
        }

        if (ItemRoot == null)
        {
            ItemRoot = new GameObject("@Items");
            ItemRoot.transform.SetParent(Root.transform);
            ItemRoot.AddComponent<AdjustTools>();
        }

        if (InOutRoot == null)
        {
            InOutRoot = new GameObject("@InOut");
            InOutRoot.transform.SetParent(Root.transform);
        }
    }

    private void CreatRes(TextAsset inTextJson)
    {
        roomInfos = TextAsset2Data(inTextJson);

        for (int i = 0; i < roomInfos.Count; i++)
        {
            var info = roomInfos[i];

            info.prefabName = "";
            info.prefabScale = Vector3.zero;            

            info = GetDataFromInfo(info);

            if (info.prefabName == "")
            {
                Debug.LogError(info.prefabName.ToString());
                GameObject room = GameObject.CreatePrimitive(PrimitiveType.Cube);
                room.name = info.des.Tag.ToString();
                room.transform.SetParent(GrssRoot.transform);
                room.transform.localPosition = roomInfos[i].pos;
                room.transform.localScale = roomInfos[i].size;
                room.transform.GetComponent<Renderer>().sharedMaterial.SetColor("_Color", roomInfos[i].color);
            }
            else
            {
                Debug.LogError(info.prefabName.ToString());
                GameObject room = GameObject.Instantiate(Resources.Load(info.prefabName)) as GameObject;
                room.name = info.prefabName;

                SetParentAndFixData(room, info);

                room.transform.localPosition = info.pos;
                room.transform.localRotation = Quaternion.Euler(info.prefabRot);

                if (info.prefabScale != Vector3.zero)
                    room.transform.localScale = info.prefabScale;

                if (room.transform.GetComponent<FullWhiteSpace>())
                {
                    room.transform.GetComponent<FullWhiteSpace>().parent = GrssRoot.transform;
                    room.transform.GetComponent<FullWhiteSpace>().CreatRes();
                    GameObject.DestroyImmediate(room.transform.gameObject);
                }
            }
        }
    }

    /// <summary>
    /// ��Ҫ�����Iitem�ȳ�����������д�С���ֳɲ�ͬʵ�����壬��һһ��Ӧ������֮�������
    /// </summary>
    /// <param name="info"></param>
    /// <returns></returns>
    private RoomInfo GetDataFromInfo(RoomInfo info)
    {
        if (info.des.Tag == AreaDesTag.Items)
        {
            if(info.size.x >= 25)
            {
                if (Use2DRes)
                {
                    info.prefabName = "i_2002_2D";
                    info.prefabScale = Vector3.one * info.size.x;
                }
            }
            else if (info.size.x >= 10)
            {
                if (Use2DRes)
                {
                    info.prefabName = "i_2002_2D";
                    info.prefabScale = Vector3.one * info.size.x;
                }
                else
                {
                    info.prefabName = "i_2002";
                    info.prefabScale = Vector3.one * info.size.x * 0.2f;
                }
            }
            else if (info.size.x == 6)
            {
                info.prefabName = "i_1003";
                info.prefabScale = Vector3.one * 2.5f;
            }
            else if (info.size.x == 3)
            {
                info.prefabName = "f_2002";
                info.prefabScale = Vector3.one * 3.0f;
            }
        }

        if (info.des.Tag == AreaDesTag.Areas)
        {
            info.prefabName = "Areas";
            info.prefabScale = info.size;
        }

        if (info.des.Tag == AreaDesTag.��)
        {
            info.prefabName = "npc";
            info.prefabScale = Vector3.one;
        }

        if (info.des.Tag == AreaDesTag.��)
        {
            info.prefabName = "��";
            info.prefabScale = info.size;
        }

        if (info.des.Tag == AreaDesTag.ˮ)
        {
            info.prefabName = "tb_water_01";
            info.prefabScale = info.size;
        }

        if (info.des.Tag == AreaDesTag.Boss)
        {
            info.prefabName = "Boss";
            info.prefabScale = info.size;
        }

        if (info.des.Tag == AreaDesTag.Ѩ)
        {
            info.prefabName = "Ѩ";
            info.prefabScale = info.size;
        }

        //if (info.des.Tag == AreaDesTag.�����谭_��ʯ)
        //{
        //    info.prefab = "Cliff02f_30_30";
        //    info.prefabScale = Vector3.zero;
        //    info.prefabRot = new Vector3(0, Mathf.FloorToInt(info.prefabRot.y / 90) * 90, 0);
        //}

        //if (info.des.Tag == AreaDesTag.���й���_ʯ����)
        //{
        //    if (info.size.x == 20)
        //    {
        //        info.prefab = "WaterWay_20_20";
        //        info.prefabScale = Vector3.zero;
        //        info.prefabRot = new Vector3(0, Mathf.FloorToInt(info.prefabRot.y / 90) * 90, 0);
        //    }
        //    else if (info.size.x == 40)
        //    {
        //        info.prefab = "WaterWay_40_40";
        //        info.prefabScale = Vector3.zero;
        //        info.prefabRot = new Vector3(0, Mathf.FloorToInt(info.prefabRot.y / 90) * 90, 0);
        //    }
        //}

        return info;
    }

    /// <summary>
    /// ����������ַ���
    /// </summary>
    /// <param name="inObj"></param>
    /// <param name="inInfo"></param>
    private void SetParentAndFixData(GameObject inObj,RoomInfo inInfo)
    {
        var name = inInfo.prefabName;

        if (name.Contains("water"))
        {
            inObj.transform.SetParent(WaterRoot.transform);
            inInfo.prefabRot = new Vector3(90, 0, 0);
            inInfo.pos = inInfo.pos + Vector3.up * 0.01f;
            inInfo.prefabScale = new Vector3(inInfo.prefabScale.x, inInfo.prefabScale.z, 1);
        }
        else
        {
            if (Use2DRes)
            {
                inInfo.prefabRot = new Vector3(33.33f, 0, 0);
                inInfo.pos = inInfo.pos - Vector3.up * 5;
            }
            else
            {
                inInfo.prefabRot = new Vector3(0, Random.Range(-360, 360), 0);
            }

            if (name.Contains("Boss"))
            {
                inInfo.prefabRot = new Vector3(0, 0, 0);
                inObj.transform.SetParent(Root.transform);
                inInfo.pos = new Vector3(inInfo.pos.x, 0, inInfo.pos.z);
            }
            else if (name.Contains("Areas"))
            {
                inInfo.prefabRot = new Vector3(0, 0, 0);
                inObj.transform.SetParent(Root.transform);
                inInfo.pos = new Vector3(inInfo.pos.x, 0, inInfo.pos.z);
            }
            else if (name.Contains("npc"))
            {
                inInfo.prefabRot = new Vector3(0, 0, 0);
                inObj.transform.SetParent(Root.transform);
                inInfo.pos = new Vector3(inInfo.pos.x, 0, inInfo.pos.z);
            }
            else if (name.Contains("Ѩ"))
            {
                inInfo.prefabRot = new Vector3(0, 0, 0);
                inObj.transform.SetParent(Root.transform);
                inInfo.pos = new Vector3(inInfo.pos.x, 0, inInfo.pos.z);
            }
            else if (name.Contains("_"))//items
            {
                inObj.transform.SetParent(ItemRoot.transform);

                if (Use2DRes && name.Contains("2D"))
                {
                    inInfo.pos = new Vector3(inInfo.pos.x, -1.5f, inInfo.pos.z);
                }
                else
                {
                    inInfo.pos = new Vector3(inInfo.pos.x, 0, inInfo.pos.z);
                }
            }
            else
            {
                inObj.transform.SetParent(Root.transform);
            }
        }


    }

    static public List<RoomInfo> TextAsset2Data(TextAsset AnimJson)
    {
        List<RoomInfo> roomInfo = new List<RoomInfo>();
        string json = AnimJson.text;

        if (!string.IsNullOrEmpty(json))
        {
            string[] jsonarray = json.Split('#');

            for (int i = 0; i < jsonarray.Length; i++)
            {
                roomInfo.Add((RoomInfo)JsonUtility.FromJson(jsonarray[i], typeof(RoomInfo)));
            }
        }

        return roomInfo;
    }
}
