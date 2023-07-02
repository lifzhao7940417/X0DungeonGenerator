using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Sirenix.OdinInspector;

[Serializable]
public class LineDes
{
    public Color Color;
    public Vector3 p0;
    public Vector3 p1;
}


[CreateAssetMenu]
public class LineParamResources : ScriptableObject
{
    [Serializable]
    public class LineParam
    {
        public LineDes[] Line;
    }

    [Title("LineParam", bold: false)]
    [HideLabel]
    public LineParam lineParams;
}
