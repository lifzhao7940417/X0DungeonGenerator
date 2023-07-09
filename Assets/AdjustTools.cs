using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using GameWish.Game;

public class AdjustTools : MonoBehaviour
{
    public List<GameObject> ItemsList= new List<GameObject>();
    [Range(0,10)]
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

    [Button("�ռ���ʵ��")]
    public void CollectInstance()
    {
        for (int i = 0; i < this.transform.childCount; i++)
        {
            var child = this.transform.GetChild(i);
            ItemsList.Add(child.gameObject);
        }
    }

    private void Adjust()
    {
        for (int i = 0; i < ItemsList.Count; i++)
        {
            var trans = ItemsList[i].transform;


            //trans.localRotation = Quaternion.Euler(objRotation);
            trans.localPosition = new Vector3(trans.localPosition.x, objPosY, trans.localPosition.z);
            trans.localScale = Vector3.one * scale;
        }
    }

    [Button("��ͼ���")]
    public void SetRandomTex()
    {
        MaterialPropertyBlock props = new MaterialPropertyBlock();

        for (int i = 0; i < ItemsList.Count; i++)
        {
            int value = Random.Range(1, 10);
            props.SetInt("_TexIndex", value);
            ItemsList[i].GetComponent<Renderer>().SetPropertyBlock(props);
        }
    }



    //[Button("����ʵ��")]
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

    //[Button("ɾ������ʵ��")]
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
