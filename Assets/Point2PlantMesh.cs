using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using System.Linq;
using System.Linq.Expressions;

public class Point2PlantMesh : MonoBehaviour
{
    [ReadOnly]
    public List<Vector3> FenceOutSidePoint = new List<Vector3>();
    [ReadOnly]
    public List<Vector3> FenceInSidePoint = new List<Vector3>();
    [ReadOnly]
    public List<float> EdgeEachDis = new List<float>();
    [ReadOnly]
    public List<float> EdgeUVPercent = new List<float>();
    [ReadOnly]
    public List<Vector3> meshVerts = new List<Vector3>();
    [ReadOnly]
    public List<Vector2> meshUvs = new List<Vector2>();
    [ReadOnly]
    public List<int> meshTriangles = new List<int>();

    public Material mat;
    [Range(0, 1)]
    public float EdgeWidth = 0.5f;

    [Button("获取边缘点集，从子物体中，更具名字前缀【FenceOutSide_】")]
    public void GetData()
    {
        FenceOutSidePoint = new List<Vector3>();
        for (int i = 0; i < this.transform.childCount; i++)
        {
            var obj = this.transform.GetChild(i).gameObject;

            if (obj.name.Contains("FenceOutSide_"))
            {
                FenceOutSidePoint.Add(obj.transform.position);
            }
        }
    }

    [Button("生成模型【边缘】")]
    public void BuildEdgeMesh()
    {
        FenceInSidePoint = new List<Vector3>();
        EdgeEachDis = new List<float>();
        EdgeUVPercent = new List<float>();

        meshVerts = new List<Vector3>();
        meshUvs = new List<Vector2>();
        meshTriangles = new List<int>();

        var allcount = FenceOutSidePoint.Count;
        var middlePos = this.transform.position;


        for (int i = 0; i < allcount; i++)
        {
            //0,2
            meshVerts.Add(FenceOutSidePoint[i] - this.transform.position);

            //1,3
            var inSidePos = Vector3.Lerp(FenceOutSidePoint[i], middlePos, EdgeWidth);
            FenceInSidePoint.Add(inSidePos);
            meshVerts.Add(inSidePos - this.transform.position);
        }

        //12=0
        meshVerts.Add(FenceOutSidePoint[0] - this.transform.position);
        //13=1
        meshVerts.Add(Vector3.Lerp(FenceOutSidePoint[0], middlePos, EdgeWidth) - this.transform.position);

        //0~end
        float alldis = 0;
        for (int i = 0; i < allcount - 1; i++)
        {
            var eachDis = Vector3.Distance(FenceOutSidePoint[i], FenceOutSidePoint[i + 1]);
            EdgeEachDis.Add(eachDis);
            alldis += eachDis;
        }

        //last(0-end)
        float lastdis = Vector3.Distance(FenceOutSidePoint[0], FenceOutSidePoint[FenceOutSidePoint.Count - 1]);
        EdgeEachDis.Add(lastdis);
        alldis += lastdis;


        EdgeUVPercent.Add(0);
        for (int i = 0; i < EdgeEachDis.Count; i++)
        {
            var percent = EdgeEachDis[i] / alldis;
            EdgeUVPercent.Add(percent);
        }

        for (int n = 0; n <= allcount - 1; n++)
        {
            float x = 0;

            for (int i = 0; i <= n; i++)
            {
                x += EdgeUVPercent[i];
            }

            Vector2 up = new Vector2(x, 0.5f);
            meshUvs.Add(up);

            Vector2 down = new Vector2(x, 0);
            meshUvs.Add(down);
        }

        meshUvs.Add(new Vector2(1, 0.5f));
        meshUvs.Add(new Vector2(1, 0));



        for (int n = 0; n <= allcount - 1; n++)
        {
            meshTriangles.Add(2 * n);
            meshTriangles.Add(2 * n + 2);
            meshTriangles.Add(2 * n + 1);

            meshTriangles.Add(2 * n + 2);
            meshTriangles.Add(2 * n + 3);
            meshTriangles.Add(2 * n + 1);
        }

        DrawMesh("Fence");
    }

    [Button("生成模型【内部】")]
    public void FullHole()
    {
        meshVerts = new List<Vector3>();
        meshUvs = new List<Vector2>();
        meshTriangles = new List<int>();

        var allcount = FenceOutSidePoint.Count;
        var middlePos = this.transform.position;

        for (int i = 0; i < allcount; i++)
        {
            var inSidePos = Vector3.Lerp(FenceOutSidePoint[i], middlePos, EdgeWidth);
            meshVerts.Add(inSidePos - this.transform.position);
        }


        meshVerts.Add(middlePos - this.transform.position);

        for (int n = 0; n < meshVerts.Count-1; n++)
        {
            if (n == meshVerts.Count - 1)
            {
                meshTriangles.Add(n);
                meshTriangles.Add(0);
                meshTriangles.Add(meshVerts.Count - 1);
            }
            else
            {
                if (n == meshVerts.Count - 2)
                {
                    meshTriangles.Add(n);
                    meshTriangles.Add(0);
                    meshTriangles.Add(meshVerts.Count - 1);
                }
                else
                {
                    meshTriangles.Add(n);
                    meshTriangles.Add(n + 1);
                    meshTriangles.Add(meshVerts.Count - 1);
                }
            }
        }

        DrawMesh("Hole");
    }

    public void DrawMesh(string inname)
    {
        Vector3[] baseVerts = meshVerts.ToArray();
        Vector2[] baseUVs = meshUvs.ToArray();
        int[] baseTriangles = meshTriangles.ToArray();

        Mesh meshData = new Mesh();
        meshData.vertices = baseVerts;
        meshData.uv = baseUVs;
        meshData.triangles = baseTriangles;
        meshData.RecalculateNormals();


        var obj = new GameObject(inname);
        obj.transform.SetParent(this.transform);
        obj.transform.localPosition = Vector3.zero;
        obj.transform.localScale = Vector3.one;
        obj.transform.localRotation = Quaternion.identity;
        obj.AddComponent<MeshFilter>().sharedMesh = meshData;
        obj.AddComponent<MeshRenderer>().sharedMaterial = mat;
    }



}
