using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

public class AreaGizmo : MonoBehaviour
{
    private Vector3 左下 = new Vector3();
    private Vector3 右下 = new Vector3();
    private Vector3 左上 = new Vector3();
    private Vector3 右上 = new Vector3();


    public Vector2 Size;

    private void OnDrawGizmos()
    {
        float BaseSize = 0.5f;

        左上 = this.transform.position - new Vector3(-BaseSize * Size.x, 0, BaseSize * Size.y);
        左下 = this.transform.position - new Vector3(-BaseSize * Size.x, 0, -BaseSize * Size.y);
        右下 = this.transform.position - new Vector3(BaseSize * Size.x, 0, -BaseSize * Size.y);
        右上 = this.transform.position - new Vector3(BaseSize * Size.x, 0, BaseSize * Size.y);

        Gizmos.DrawLine(右下, 右上);
        Gizmos.DrawLine(左上, 右上);
        Gizmos.DrawLine(左上, 左下);
        Gizmos.DrawLine(右下, 左下);
    }
}
