using System.Collections;
using System.Collections.Generic;
using UnityEditor.PackageManager.UI;
using UnityEngine;
using Sirenix.OdinInspector;

public class UVChecker : MonoBehaviour
{

    public Vector4 UVTillingOffset;
    public int Index;
    public Vector2 RowColumn;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }


    [Button("GetUVValue")]
    void GetUV()
    {
        float inColumn = RowColumn.y;
        float inRow = RowColumn.x;
        int inIndex = Index;

        float index = Mathf.Max(inIndex, 1) * 1.0f;//1
        float xeach = (1 / inColumn);//0.2
        float xaddStep = Mathf.Min(index % inColumn, 1);//1
        float uvx = Mathf.Lerp((inColumn - 1) * xeach, (index % inColumn - 1) * xeach, xaddStep);

        float yeach = (1 / inRow);
        
        float uvy = Mathf.FloorToInt(index / inColumn) * yeach;

        float finallStep = Mathf.Floor(inIndex/(inColumn * inRow));

        UVTillingOffset =  new Vector4(xeach, yeach,uvx, uvy);
    }
}
