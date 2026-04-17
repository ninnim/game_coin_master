using System;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;

namespace CoinMasterClone.Raid
{
    /// <summary>
    /// A single tappable mound in the 3x3 raid grid.
    ///
    /// Editor setup:
    ///  - Add this script to each grid tile
    ///  - Give the GameObject a Collider (3D) or GraphicRaycaster (UI)
    ///  - Wire up [moundMesh], [dugMesh], [coinText] in the inspector
    /// </summary>
    public class HoleTile : MonoBehaviour, IPointerClickHandler
    {
        [HideInInspector] public int index;

        [Header("Visuals (swap on reveal)")]
        public GameObject moundMesh;
        public GameObject dugMesh;
        public TextMeshProUGUI coinText;
        public GameObject coinPilePrefab;
        public GameObject emptyIndicator;

        [Header("Selected highlight")]
        public GameObject selectedHighlight;

        public Action OnClicked;

        void Awake()
        {
            if (dugMesh != null) dugMesh.SetActive(false);
            if (coinText != null) coinText.gameObject.SetActive(false);
            if (emptyIndicator != null) emptyIndicator.SetActive(false);
            if (selectedHighlight != null) selectedHighlight.SetActive(false);
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            OnClicked?.Invoke();
        }

        // Fallback if the object uses a 3D collider instead of UI raycasts
        void OnMouseDown()
        {
            OnClicked?.Invoke();
        }

        public void ShowSelected()
        {
            if (selectedHighlight != null) selectedHighlight.SetActive(true);
        }

        public void RevealCoins(long amount)
        {
            if (moundMesh != null) moundMesh.SetActive(false);
            if (dugMesh != null) dugMesh.SetActive(true);

            if (amount > 0)
            {
                if (coinPilePrefab != null)
                {
                    Instantiate(coinPilePrefab, transform.position + Vector3.up * 0.2f, Quaternion.identity, transform);
                }
                if (coinText != null)
                {
                    coinText.text = $"+{amount:N0}";
                    coinText.gameObject.SetActive(true);
                }
            }
            else
            {
                if (emptyIndicator != null) emptyIndicator.SetActive(true);
                if (coinText != null)
                {
                    coinText.text = "empty";
                    coinText.color = new Color(1f, 1f, 1f, 0.5f);
                    coinText.gameObject.SetActive(true);
                }
            }
        }
    }
}
