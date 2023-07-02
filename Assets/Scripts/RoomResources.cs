using System;
using System.Collections.Generic;
using Sirenix.OdinInspector;
using UnityEngine;


[CreateAssetMenu]
public class RoomResources : ScriptableObject
{
    [Serializable]
    public class RoomsData
    {
        public List<RoomInfo> roomInfos = new List<RoomInfo>();
    }

    [Title("RoomsInfo", bold: false)]
    [HideLabel]
    public RoomsData RoomData;
}