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
            [LabelText("̫��24h��ɫ")]
            public UnityEngine.Gradient MainLightColor = new UnityEngine.Gradient();

            [LabelText("̫��24h�߶Ƚ�")]
            public AnimationCurve MainLightAngle;

            [LabelText("̫��24h��Ӱ")]
            public AnimationCurve MainLightShadow;

            [LabelText("��Ӱ����ǿ��")]
            public float ShadowStrength=1;

            [LabelText("������ЧȾɫ")]
            public UnityEngine.Gradient EffectColor = new UnityEngine.Gradient();

            [LabelText("����")]
            [Range(1, 5)]
            public float WindAllCtrl;

            public Texture CloudNoiseTex;

        }

        [Title("SceneParams", bold: false)]
        [HideLabel]
        public SceneParams sceneParams;
    }
}
