using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Text;
using System.IO;
using System.Threading;
using UnityEditor.Experimental.GraphView;

namespace UnityFBXExporter
{
    public class MeshCombineAndExport
    {
#if UNITY_EDITOR
        [MenuItem("GameObject/@X0 GameTools/按材质球合并模型", false, 2)]
        static void Merge()
        {
            if (Selection.transforms.Length == 0)
            {
                GUILayout.Label("选中的transform下没有问题！");
            }
            else
            {
                CombineObjsByRoot(Selection.transforms);
            }
        }

        [MenuItem("GameObject/@X0 GameTools/选择模型->调整UV", false, 2)]
        static void ExportMeshFBXWithAdjustUV()
        {
            if (Selection.transforms.Length == 0)
            {
                GUILayout.Label("选中的transform下没有问题！");
            }
            else
            {
                var selections = Selection.transforms;

                for (int i = 0; i < selections.Length; i++)
                {
                    Transform currentRoot = selections[i];
                    var tag = currentRoot.gameObject.GetComponent<UVEvaluation>();
                    if (tag)
                        tag.UVChecker();
                }
            }
        }

        static string selectedPath;
        [MenuItem("GameObject/@X0 GameTools/选择模型->生成FBX文件", false, 2)]
        static void ExportMeshFBX()
        {
            if (Selection.transforms.Length == 0)
            {
                Debug.LogError("没有选择物体！");
            }
            else if (!Selection.transforms[0].GetComponent<MeshFilter>())
            {
                Debug.LogError("选中的模型没有MeshFilter组件！");
            }
            else
            {

                selectedPath = EditorUtility.OpenFolderPanel("Select export output folder", "", "");

                if (selectedPath == null)
                {
                    selectedPath = Application.dataPath;
                }
                else
                {
                    GameObject selected = Selection.transforms[0].gameObject;
                    string newPath = selectedPath + "/" + selected.name + ".fbx";
                    bool exportAsBinary = false;

                    if (!FBXExporter.ExportGameObjToFBX(selected, newPath, exportAsBinary, false, false))
                    {
                        EditorUtility.DisplayDialog("Warning", "ExportGameObjToFBX returned false", "Okay");
                    }
                    else
                    {
                        EditorUtility.DisplayDialog("", "Exported to " + newPath, ":)");
                    }
                }
            }
        }




#endif

        /// <summary>
        /// 是否存入 tangents
        /// </summary>
        private static bool useTangents = true;

        static Dictionary<string, List<MeshFilter>> meshByMaterial;
        static Transform currentMaterialParent;

        /// <summary>
        /// 根节点 合并mesh
        /// </summary>
        /// <param name="selections"></param>
        public static void CombineObjsByRoot(Transform[] selections)
        {
            GetAllMeshFilter(selections);

            string combineObjName = "";
            if (selections.Length == 1)
            {
                combineObjName = selections[0].name;
            }

            CreateCobmineMeshObjCus(combineObjName);
        }

        /// <summary>
        /// 获取所有物体的 meshFilter
        /// </summary>
        private static void GetAllMeshFilter(Transform[] selections)
        {
            meshByMaterial = new Dictionary<string, List<MeshFilter>>();
            meshByMaterial.Clear();
            for (int i = 0; i < selections.Length; i++)
            {
                List<MeshFilter> meshFilters = new List<MeshFilter>();

                Transform currentRoot = selections[i];
                GetComponentsInChildRecursively<MeshFilter>(selections[i], meshFilters);

                //只有可见的物体 才记录
                if (currentRoot.GetComponent<MeshFilter>() && currentRoot.gameObject.activeInHierarchy)
                {
                    meshFilters.Add(currentRoot.GetComponent<MeshFilter>());
                }

                foreach (MeshFilter meshFilter in meshFilters)
                {
                    string materialName = meshFilter.gameObject.GetComponent<MeshRenderer>().sharedMaterial.name;

                    if (!meshByMaterial.ContainsKey(materialName))
                    {
                        meshByMaterial.Add(materialName, new List<MeshFilter>());
                    }
                    else { }

                    if (!meshByMaterial[materialName].Contains(meshFilter))
                    {
                        meshByMaterial[materialName].Add(meshFilter);
                    }
                    else
                    {
                        Debug.Log(materialName + " Contains   " + meshFilter.gameObject.name);
                    }
                }
            }
        }

        static void CreateCobmineMeshObjCus(string name)
        {
            GameObject newObjsRoot = new GameObject(name + "__combine");
            newObjsRoot.transform.position = Vector3.zero;

            Debug.Log("materials " + meshByMaterial.Count);

            foreach (KeyValuePair<string, List<MeshFilter>> keyPair in meshByMaterial)
            {
                MeshFilter[] inMeshFilter = keyPair.Value.ToArray();
                MergeMeshRoot(inMeshFilter, keyPair.Key, newObjsRoot.transform);
            }
        }

        /// <summary>
        /// 模型合并
        /// </summary>
        /// <param name="meshFilters">所有子物体的网格</param>
        static void MergeMeshRoot(MeshFilter[] meshFilters, string name, Transform parent = null)
        {
            CombineInstance[] combineInstances = new CombineInstance[meshFilters.Length]; //新建一个合并组，长度与 meshfilters一致

            for (int i = 0; i < meshFilters.Length; i++)                                  //遍历
            {
                combineInstances[i].mesh = meshFilters[i].sharedMesh;                   //将共享mesh，赋值
                combineInstances[i].transform = meshFilters[i].transform.localToWorldMatrix; //本地坐标转矩阵，赋值
            }
            Mesh newMesh = new Mesh();                                  //声明一个新网格对象
            newMesh.CombineMeshes(combineInstances);                    //将combineInstances数组传入函数
            GameObject go = new GameObject(name);
            go.transform.SetParent(parent);
            go.AddComponent<MeshFilter>().sharedMesh = newMesh; //给当前空物体，添加网格组件；将合并后的网格，给到自身网格
            go.AddComponent<MeshRenderer>().sharedMaterial = meshFilters[meshFilters.Length - 1].GetComponent<MeshRenderer>().sharedMaterial;
            //AssetDatabase.CreateAsset(newMesh, "Assets/" + name + ".asset");
        }

        /// <summary>
        /// 查找组件
        /// </summary>
        /// <param name="_transform"></param>
        /// <param name="target"></param>
        /// <typeparam name="T"></typeparam>
        public static void GetComponentInChildRecursively<T>(Transform _transform, ref T target)
        {

            foreach (Transform t in _transform)
            {
                T[] components = t.GetComponents<T>();

                foreach (T component in components)
                {
                    if (component != null)
                    {
                        // Debug.Log(" component != null ");

                        target = component;
                        return;
                    }
                }

                if (target == null)
                {
                    GetComponentInChildRecursively<T>(t, ref target);
                }

            }

        }

        /// <summary>
        /// 查找组件
        /// </summary>
        /// <param name="_transform"></param>
        /// <param name="_componentList"></param>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        private static List<T> GetComponentsInChildRecursively<T>(Transform _transform, List<T> _componentList)
        {

            foreach (Transform t in _transform)
            {
                T[] components = t.GetComponents<T>();

                foreach (T component in components)
                {
                    if (component != null)
                    {
                        _componentList.Add(component);
                    }
                }

                GetComponentsInChildRecursively<T>(t, _componentList);
            }


            return _componentList;
        }

    }
}

