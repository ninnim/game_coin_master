using System;
using CoinMasterClone.Api.Models;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;

namespace CoinMasterClone.Village
{
    /// <summary>
    /// A single building in the village scene. Holds the <see cref="UserBuildingModel"/>
    /// data and swaps between 5 level-visuals (index 0 = under construction,
    /// 1-4 = progressive upgrades).
    ///
    /// Editor setup:
    ///  - Create an empty GameObject "Building_Castle" (etc.)
    ///  - Attach this script + a Collider (so clicks raycast)
    ///  - Create 5 child GameObjects as [levelStages]:
    ///      [0] construction site prefab (scaffolding)
    ///      [1..4] progressively built / decorated versions
    ///  - Add a floating TMP label for the name + level dots (optional)
    /// </summary>
    public class BuildingTile : MonoBehaviour, IPointerClickHandler
    {
        [Header("Visual stages — 5 child GameObjects toggled by level (0=construction, 4=max)")]
        public GameObject[] levelStages = new GameObject[5];

        [Header("Labels (optional)")]
        public TextMeshPro nameLabel;
        public GameObject destroyedOverlay;
        public GameObject[] levelDots = new GameObject[4]; // visual star/dot indicators

        [Header("Complete glow (shown when level == 4)")]
        public GameObject completeGlow;

        public Action OnClicked;
        public UserBuildingModel Data { get; private set; }

        public void Bind(UserBuildingModel data)
        {
            Data = data;
            if (nameLabel != null) nameLabel.text = data.BuildingName;
            if (destroyedOverlay != null) destroyedOverlay.SetActive(data.IsDestroyed);
            ApplyLevelVisuals();
        }

        public void ApplyLevelVisuals()
        {
            if (Data == null) return;
            int level = Data.UpgradeLevel;
            for (int i = 0; i < levelStages.Length; i++)
            {
                if (levelStages[i] != null)
                    levelStages[i].SetActive(i == level);
            }
            for (int i = 0; i < levelDots.Length; i++)
            {
                if (levelDots[i] != null)
                    levelDots[i].SetActive(i < level);
            }
            if (completeGlow != null) completeGlow.SetActive(level >= 4);
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            OnClicked?.Invoke();
        }

        void OnMouseDown()
        {
            OnClicked?.Invoke();
        }
    }
}
