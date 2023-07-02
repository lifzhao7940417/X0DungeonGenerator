using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using System;

namespace GameWish.Game
{
    public class SceneParameters : MonoBehaviour
    {
        [LabelText("时钟（1s->1min）")][Range(0,24)]
        public float Times;

        public SceneParamResources parametersInEditor;

        [LabelText("太阳24h颜色")]
        public UnityEngine.Gradient MainLightColor = new UnityEngine.Gradient();

        [LabelText("太阳24h高度角")]
        public AnimationCurve MainLightAngle;

        [LabelText("太阳24h阴影")]
        public AnimationCurve MainLightShadow;

        [LabelText("阴影整体强度")]
        public float ShadowStrength;

        [LabelText("场景特效染色")]
        public UnityEngine.Gradient EffectColor = new UnityEngine.Gradient();

        [LabelText("风力")][Range(1, 5)]
        public float WindAllCtrl;

        public Texture CloudNoiseTex;


        #region ReadyOnly
        [ReadOnly]
        public Light MainLight;
        [ReadOnly]
        public float curTime;
        [ReadOnly]
        public float percent;
        #endregion

        [Button("从资源获取环境数据")]
        void GetDataFromAssets()
        {
            if (parametersInEditor != null)
            {
                MainLightColor = parametersInEditor.sceneParams.MainLightColor;
                MainLightAngle = parametersInEditor.sceneParams.MainLightAngle;
                MainLightShadow = parametersInEditor.sceneParams.MainLightShadow;
                ShadowStrength = parametersInEditor.sceneParams.ShadowStrength;
                EffectColor = parametersInEditor.sceneParams.EffectColor;
                WindAllCtrl = parametersInEditor.sceneParams.WindAllCtrl;
                CloudNoiseTex = parametersInEditor.sceneParams.CloudNoiseTex;
            }
        }

        Light GetMainLight()
        {
            if (this.gameObject.GetComponent<Light>() == null)
            {
                var light = this.gameObject.AddComponent<Light>();
                light.type = LightType.Directional;
                light.color = Color.white;
                light.shadows = LightShadows.Soft;
                return light;
            }
            else
            {
                var light = this.gameObject.GetComponent<Light>();
                light.type = LightType.Directional;
                light.color = Color.white;
                light.shadows = LightShadows.Soft;
                return light;
            }
        }

        void Check(float inTime=-1)
        {
            if(inTime!=-1)
                curTime = inTime;

            percent = curTime / 24.0f;

            if (MainLight == null)
                MainLight = GetMainLight();

            if (MainLight!=null)
            {
                MainLight.shadowStrength = MainLightShadow.Evaluate(percent)* ShadowStrength;
                var xangle = MainLightAngle.Evaluate(percent) * 100;
                MainLight.transform.localRotation = Quaternion.Euler(xangle, -45, 45);
            }

            if (CloudNoiseTex != null)
                Shader.SetGlobalTexture("_CloudNoiseTex", CloudNoiseTex);

            if (MainLightColor != null)
                Shader.SetGlobalColor("_MainLightColor", GetMainLightColor());

            if(EffectColor!=null)
                Shader.SetGlobalColor("_SceneColor", GetSceneLightColor());

            Shader.SetGlobalFloat("_WindAllCtrl", WindAllCtrl);
        }

        private void OnValidate()
        {
            Check(Times);
        }

        Color GetMainLightColor()
        {
            percent = curTime / 24.0f;
            return MainLightColor.Evaluate(percent);
        }

        Color GetSceneLightColor()
        {
            percent = curTime / 24.0f;
            return EffectColor.Evaluate(percent);
        }

        void Start()
        {
            Check();
        }

        void Update()
        {
            curTime += Time.deltaTime *0.01665f;

            if (curTime >= 24)
            {
                curTime = 0;
            }

            percent = curTime / 24.0f;

            Check();
        }
    }
}
