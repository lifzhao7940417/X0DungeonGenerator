using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using JetBrains.Annotations;

public class RoadTools : MonoBehaviour
{
    public List<LineRenderer> lineRenderers = new List<LineRenderer>();
    public List<Vector3> linePoints= new List<Vector3>();
    public LineParamResources LineParamResources;

    private LineDes[] lineDesArray;

    [Button("（运行时用）纪录道路数据")]
    public void CollectionDataPoint()
    {
        lineRenderers = new List<LineRenderer>();
        linePoints = new List<Vector3>();

        for (int i = 0; i < this.transform.childCount; i++)
        {
            lineRenderers.Add(this.transform.GetChild(i).GetComponent<LineRenderer>());
        }

        lineDesArray = new LineDes[lineRenderers.Count];

        for (int i = 0; i < lineRenderers.Count; i++)
        {
            var road = lineRenderers[i];

            var pos0 = road.GetPosition(0);
            var pos1 = road.GetPosition(1);

            if(!linePoints.Contains(pos0))
                linePoints.Add(pos0);

            if(!linePoints.Contains(pos1))
                linePoints.Add(pos1);


            LineDes lineDes = new LineDes();
            lineDes.Color = road.startColor;
            lineDes.p0 = pos0;
            lineDes.p1 = pos1;
            lineDesArray[i]= lineDes;

            LineParamResources.lineParams.Line = lineDesArray;

        }
    }

    [Button("LinearRenderXZ交换")]
    public void ChangeYZ()
    {
        lineRenderers = new List<LineRenderer>();
        linePoints = new List<Vector3>();

        for (int i = 0; i < this.transform.childCount; i++)
        {
            lineRenderers.Add(this.transform.GetChild(i).GetComponent<LineRenderer>());
        }

        for (int i = 0; i < lineRenderers.Count; i++)
        {
            var road = lineRenderers[i];

            var pos0 = road.GetPosition(0);
            var pos1 = road.GetPosition(1);

            pos0 = new Vector3(pos0.x, 0, pos0.y);
            pos1 = new Vector3(pos1.x, 0, pos1.y);

            lineRenderers[i].SetPosition(0, pos0);
            lineRenderers[i].SetPosition(1, pos1);
        }
    }
}
