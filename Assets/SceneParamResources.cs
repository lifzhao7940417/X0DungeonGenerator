using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using Sirenix.OdinInspector;

namespace GameWish.Game
{
    [CreateAssetMenu]
    public class SceneParamResources : ScriptableObject
    {
        [Serializable]
        public class SceneParams
        {
            [LabelText("太阳24h颜色")]
            public UnityEngine.Gradient MainLightColor = new UnityEngine.Gradient();

            [LabelText("太阳24h高度角")]
            public AnimationCurve MainLightAngle;

            [LabelText("太阳24h阴影")]
            public AnimationCurve MainLightShadow;

            [LabelText("阴影整体强度")]
            public float ShadowStrength=1;

            [LabelText("场景特效染色")]
            public UnityEngine.Gradient EffectColor = new UnityEngine.Gradient();

            [LabelText("风力")]
            [Range(1, 5)]
            public float WindAllCtrl;

            public Texture CloudNoiseTex;

        }

        [Title("SceneParams", bold: false)]
        [HideLabel]
        public SceneParams sceneParams;
    }
}
