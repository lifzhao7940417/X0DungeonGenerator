using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Sirenix.OdinInspector;

public enum AreaDesTag
{
    Boss,
    Items,
    Areas,
    ÈË,
    Ë®,
    Ñ¨,
    ²Ý,
}

[Serializable]
public class AreaDes
{
    public Color Color;
    public AreaDesTag Tag;
    public int Count;
    public int[] Distribution = new int[] { };
    public bool isQuad;
}

[CreateAssetMenu]
public class AreaParamResources : ScriptableObject
{
    [Serializable]
    public class AreaParam
    {
        public AreaDes[] Area1;
    }

    [Title("AreParams", bold: false)]
    [HideLabel]
    public AreaParam areaParams;
}

