using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;

[ExecuteInEditMode]
public class LineTools : MonoBehaviour
{
    [ReadOnly]
    public Transform StartPos;
    [ReadOnly]
    public Transform EndPos;
    [ReadOnly]
    public LineRenderer lineRenderer;
    [ReadOnly]
    public float distance;
    private float lastDis;

    [Range(15,60)]
    public float ScaleX;

    void Init()
    {
        while (this.transform.childCount > 0)
        {
            var go = this.transform.GetChild(0).gameObject;
            GameObject.DestroyImmediate(go);
        }

        StartPos = new GameObject("StartPos").transform;
        StartPos.transform.SetParent(this.transform);
        EndPos = new GameObject("EndPos").transform;
        EndPos.transform.SetParent(this.transform);
        lineRenderer = this.GetComponent<LineRenderer>();

        StartPos.transform.position = lineRenderer.GetPosition(0);
        EndPos.transform.position = lineRenderer.GetPosition(1);

        distance = Vector3.Distance(StartPos.transform.position, EndPos.transform.position);
        lastDis = distance;

        MaterialPropertyBlock props = new MaterialPropertyBlock();
        props.SetFloat("_ScaleX", lastDis / ScaleX);
        this.transform.GetComponent<LineRenderer>().SetPropertyBlock(props);
    }

    private void OnValidate()
    {
        if (StartPos != null && EndPos != null && lineRenderer != null)
        {
            lineRenderer.SetPosition(0, StartPos.transform.position);
            lineRenderer.SetPosition(1, EndPos.transform.position);

            lastDis = Vector3.Distance(StartPos.transform.position, EndPos.transform.position);

            MaterialPropertyBlock props = new MaterialPropertyBlock();
            props.SetFloat("_ScaleX", lastDis / ScaleX);
            this.transform.GetComponent<LineRenderer>().SetPropertyBlock(props);
        }
        else
        {
            Init();
        }
    }


    void Update()
    {
        if (StartPos != null && EndPos != null && lineRenderer!=null)
        {
            lineRenderer.SetPosition(0, StartPos.transform.position);
            lineRenderer.SetPosition(1, EndPos.transform.position);

            distance = Vector3.Distance(StartPos.transform.position, EndPos.transform.position);

            if (distance != lastDis)
            {
                lastDis = distance;

                MaterialPropertyBlock props = new MaterialPropertyBlock();
                props.SetFloat("_ScaleX", lastDis / ScaleX);
                this.transform.GetComponent<LineRenderer>().SetPropertyBlock(props);
            }
        }
        else
        {
            Init();
        }
    }
}
