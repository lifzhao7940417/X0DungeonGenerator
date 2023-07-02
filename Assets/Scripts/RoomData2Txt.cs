using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

public class RoomData2Txt : MonoBehaviour
{
    private List<RoomInfo> roomInfos = new List<RoomInfo>();

    static public void WriteIntoLocalFile(string path, string txtValue)
    {
        //Write some text to the test.txt file
        System.IO.StreamWriter writer = new System.IO.StreamWriter(path, false);
        writer.WriteLine(txtValue);
        writer.Close();
        UnityEditor.AssetDatabase.Refresh();
    }

    public void OutPutData2Txt()
    {
        // @"F:\@BearCoding\HT_2019LTS\UnityProject\HMZY\Assets\Resources\DataAnim";
        string AbsolutePath = @"F:\@BearCoding\@AllUnityProjects\@Others\DungeonGenerator-master\Assets\Resources\RoomRes";
        string txtName = string.Format(@"/{0}.txt", "Test1"); ;
        string path = AbsolutePath + txtName;
        string txtValue = "";

        for (int i = 0; i < roomInfos.Count; i++)
        {
            string split = (i == roomInfos.Count - 1) ? "" : "#";
            txtValue = txtValue + JsonUtility.ToJson(roomInfos[i]) + split + "\n";
            //Log.e(txtValue as string);
        }

        WriteIntoLocalFile(path, txtValue);

        Debug.LogError("完成数据输入: " + txtName);
    }

    [Button("WriteRes")]
    public void WriteRes()
    {
        if (this.transform.childCount <= 0)
            return;

        roomInfos = new List<RoomInfo>();


        for (int i = 0; i < this.transform.childCount; i++)
        {
            var child = this.transform.GetChild(i);

            RoomInfo info = new RoomInfo();
            info.des = child.transform.GetComponent<Room>().Des;
            info.pos = new Vector3(child.transform.position.x, 0, child.transform.position.y);
            info.size = new Vector3(child.transform.localScale.x, 1, child.transform.localScale.y);
            info.color = child.transform.GetComponent<SpriteRenderer>().color;

            roomInfos.Add(info);
        }

        OutPutData2Txt();
    }
}
