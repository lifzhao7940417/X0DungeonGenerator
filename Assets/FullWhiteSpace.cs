using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

public class FullWhiteSpace : MonoBehaviour
{
    [InlineButton("CreatRes", "实例化")]
    public GameObject Obj;

    public bool UsePanelGrass;

    public Vector2 ObjSize;
    [Range(0,1)]
    public float RandomPos;

    private Vector3 Face2CameraRotation=new Vector3(33.33f,0,0);

    [SerializeField]
    [ReadOnly]
    private Vector2 Size;

    [SerializeField]
    [ReadOnly]
    private Vector2 Count;

    private Vector3 左下 = new Vector3();
    private Vector3 右下 = new Vector3();
    private Vector3 左上 = new Vector3();
    private Vector3 右上 = new Vector3();

    public Transform parent;
    public Transform SpaceEnable;

    [InlineButton("Dis2HideRes", "隐藏较远的填充资源")]
    public float Dis2Hide;

    public void Dis2HideRes()
    {
        for (int j = 0; j < this.transform.childCount; j++)
        {
            var objChild = this.transform.GetChild(j);
            bool enableActive = false;

            for (int i = 0; i < SpaceEnable.childCount; i++)
            {
                var child = SpaceEnable.GetChild(i);
                var dis = (child.transform.position - objChild.transform.position).magnitude;

                if (dis < Dis2Hide)
                {
                    enableActive = true;
                    break;
                }
            }

            objChild.gameObject.SetActive(enableActive);
        }
    }

    [Button("显示所有子物体")]
    public void ShowAll()
    {
        for (int j = 0; j < this.transform.childCount; j++)
        {
            var thisChild = this.transform.GetChild(j);
            thisChild.gameObject.SetActive(true);
        }
    }


    public void CreatRes()
    {
        Check();

        float cellSizeX = ObjSize.x;
        float cellSizeZ = ObjSize.y;

        float startx = 左下.x - cellSizeX * 0.5f;
        float startz = 左下.z - cellSizeZ * 0.5f;

        for (int i = 0; i < Count.x; i++)
        {
            float posX = startx - i * cellSizeX;

            for (int j = 0; j < Count.y; j++)
            {
                float posZ = 0;

                if (UsePanelGrass)
                {
                    posZ = startz - (j+0.5f )* cellSizeZ;
                }
                else
                {
                    posZ = startz - j * cellSizeZ;
                }

                GameObject grass = GameObject.Instantiate(Obj) as GameObject;
                grass.name = Obj.name;

                if (UsePanelGrass)
                {
                    grass.transform.localRotation = Quaternion.Euler(Face2CameraRotation);
                }
                else
                {
                    float rot = Random.Range(-360, 360);
                    grass.transform.localRotation = Quaternion.Euler(0, rot, 0);
                }

                var random = Mathf.Lerp(0, ObjSize.x, RandomPos) * Random.onUnitSphere * (Random.Range(0, 100) > 50 ? 1 : -1);

                grass.transform.position = new Vector3(posX+ random.x, 0, posZ + random.z);

                if (parent != null)
                    grass.transform.SetParent(parent);
            }
        }
    }

    private void Check()
    {
        float SizeZ = Mathf.Max(1, Mathf.FloorToInt(this.transform.localScale.z));
        float SizeX = Mathf.Max(1, Mathf.FloorToInt(this.transform.localScale.x));

        Size = new Vector2(SizeX, SizeZ);

        float BaseSize = 0.5f;

        左上 = this.transform.position - new Vector3(-BaseSize * Size.x, 0, BaseSize * Size.y);
        左下 = this.transform.position - new Vector3(-BaseSize * Size.x, 0, -BaseSize * Size.y);
        右下 = this.transform.position - new Vector3(BaseSize * Size.x, 0, -BaseSize * Size.y);
        右上 = this.transform.position - new Vector3(BaseSize * Size.x, 0, BaseSize * Size.y);

        if (Obj != null)
        {
            float CountX = Mathf.FloorToInt(Mathf.Abs((右上 - 左上).x) / ObjSize.x);
            float CountZ = Mathf.FloorToInt(Mathf.Abs((右上 - 右下).z) / ObjSize.y);

            Count = new Vector2(CountX, CountZ);
        }
    }


    private void OnDrawGizmos()
    {
        Check();

        Gizmos.color = Color.green;
        Gizmos.DrawLine(右下, 右上);
        Gizmos.color = Color.white;
        Gizmos.DrawLine(左上, 右上);
        Gizmos.DrawLine(左上, 左下);
        Gizmos.color = Color.yellow;
        Gizmos.DrawLine(右下, 左下);

    }
}
