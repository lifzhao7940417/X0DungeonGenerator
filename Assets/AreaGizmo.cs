using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

public class AreaGizmo : MonoBehaviour
{
    private Vector3 ���� = new Vector3();
    private Vector3 ���� = new Vector3();
    private Vector3 ���� = new Vector3();
    private Vector3 ���� = new Vector3();


    public Vector2 Size;

    private void OnDrawGizmos()
    {
        float BaseSize = 0.5f;

        ���� = this.transform.position - new Vector3(-BaseSize * Size.x, 0, BaseSize * Size.y);
        ���� = this.transform.position - new Vector3(-BaseSize * Size.x, 0, -BaseSize * Size.y);
        ���� = this.transform.position - new Vector3(BaseSize * Size.x, 0, -BaseSize * Size.y);
        ���� = this.transform.position - new Vector3(BaseSize * Size.x, 0, BaseSize * Size.y);

        Gizmos.DrawLine(����, ����);
        Gizmos.DrawLine(����, ����);
        Gizmos.DrawLine(����, ����);
        Gizmos.DrawLine(����, ����);
    }
}
