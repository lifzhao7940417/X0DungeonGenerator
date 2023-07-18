using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using GameWish.Game;
using Unity.Jobs;

public class AdjustTools : MonoBehaviour
{
    public List<GameObject> ItemsList= new List<GameObject>();
    [Range(0,30)]
    public float scale = 1;
    [Range(-10, 10)]
    public float objPosY = 0;

    public void OnValidate()
    {
        Adjust();
    }

    private void Start()
    {
        SetRandomTex();
    }

    //[Button("收集草实例")]
    //public void CollectInstance()
    //{
    //    for (int i = 0; i < this.transform.childCount; i++)
    //    {
    //        var child = this.transform.GetChild(i);
    //        ItemsList.Add(child.gameObject);
    //    }
    //}

    private void Adjust()
    {
        for (int i = 0; i < ItemsList.Count; i++)
        {
            if (isTarget(ItemsList[i]))
            {
                var trans = ItemsList[i].transform;
                //trans.localRotation = Quaternion.Euler(objRotation);
                trans.localPosition = new Vector3(trans.localPosition.x, objPosY, trans.localPosition.z);
                trans.localScale = Vector3.one * scale;
            }

        }
    }

    bool isTarget(GameObject inObj)
    {
        return (inObj.GetComponent<Renderer>() && inObj.GetComponent<Renderer>().sharedMaterial.HasProperty("_AllCount"));
    }

    [Button("贴图随机")]
    public void SetRandomTex()
    {
        MaterialPropertyBlock props = new MaterialPropertyBlock();

        ItemsList=new List<GameObject>();

        for (int i = 0; i < this.transform.childCount; i++)
        {
            var child = this.transform.GetChild(i);
            ItemsList.Add(child.gameObject);
        }

        for (int i = 0; i < ItemsList.Count; i++)
        {
            if (isTarget(ItemsList[i]))
            {
                var rendomCount = ItemsList[i].GetComponent<Renderer>().sharedMaterial.GetInt("_AllCount");

                if (rendomCount > 0)
                {
                    int value = Random.Range(1, rendomCount + 1);
                    props.SetInt("_TexIndex", value);
                    ItemsList[i].GetComponent<Renderer>().SetPropertyBlock(props);
                }
            }
        }
    }



    //[Button("创建实例")]
    //public void CreatItem()
    //{
    //    //ClearItem();

    //    for (int i = 0; i < this.transform.childCount; i++)
    //    {
    //        var parent = this.transform.GetChild(i);
    //        var itemInstacne = GameObject.Instantiate(obj);
    //        itemInstacne.transform.SetParent(parent.transform);
    //        itemInstacne.transform.localPosition = Vector3.zero;
    //        itemInstacne.transform.localRotation = Quaternion.identity;
    //        itemInstacne.transform.localScale= Vector3.one* scale;
    //        ItemsList.Add(itemInstacne);
    //    }

    //    Adjust();

    //    SetRandomTex();
    //}

    //[Button("删除所有实例")]
    //public void ClearItem()
    //{
    //    for (int i = 0; i < ItemsList.Count; i++)
    //    {
    //        var itemInstacne = ItemsList[i].gameObject;
    //        GameObject.DestroyImmediate(itemInstacne);
    //    }

    //    for (int i = 0; i < this.transform.childCount; i++)
    //    {
    //        var count = this.transform.GetChild(i).childCount;

    //        for (int j = 0; j < count; j++)
    //        {
    //            var itemInstacne = this.transform.GetChild(i).GetChild(j).gameObject;
    //            GameObject.DestroyImmediate(itemInstacne);
    //        }
    //    }

    //    ItemsList = new List<GameObject>();
    //}
}
