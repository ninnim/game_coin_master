using System.Collections.Generic;
using System.Threading.Tasks;
using CoinMasterClone.Api;
using CoinMasterClone.Api.Models;
using CoinMasterClone.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace CoinMasterClone.Village
{
    /// <summary>
    /// Village build scene. Renders the current village's buildings as 3D
    /// prefabs, each tappable. Tapping opens an upgrade panel; confirming
    /// POSTs to /api/buildings/{id}/upgrade and animates the building's
    /// level change.
    ///
    /// Editor setup:
    ///  - Create a "Village" scene with a ground plane and sky
    ///  - Place 9 BuildingTile prefabs at their (positionX, positionY) from the backend
    ///    (or arrange them manually and let this controller just bind data to them)
    ///  - Drag all 9 BuildingTile instances into [tiles]
    ///  - Build an upgrade panel canvas and drag its fields in
    /// </summary>
    public class VillageController : MonoBehaviour
    {
        [Header("Scene references")]
        public BuildingTile[] tiles;

        [Header("Top bar")]
        public TextMeshProUGUI villageNameText;
        public TextMeshProUGUI progressText;
        public Slider progressBar;

        [Header("Upgrade panel")]
        public GameObject upgradePanel;
        public TextMeshProUGUI upgradeNameText;
        public TextMeshProUGUI upgradeLevelText;
        public TextMeshProUGUI upgradeCostText;
        public TextMeshProUGUI coinsText;
        public Button upgradeButton;
        public Button closeButton;

        [Header("Village complete dialog")]
        public GameObject villageCompleteDialog;
        public Button villageCompleteContinueButton;

        private BuildingTile _selected;
        private bool _upgrading;

        async void Start()
        {
            if (upgradePanel != null) upgradePanel.SetActive(false);
            if (villageCompleteDialog != null) villageCompleteDialog.SetActive(false);

            if (upgradeButton != null) upgradeButton.onClick.AddListener(() => _ = DoUpgrade());
            if (closeButton != null) closeButton.onClick.AddListener(CloseUpgradePanel);
            if (villageCompleteContinueButton != null)
                villageCompleteContinueButton.onClick.AddListener(() => GameManager.Instance.LoadMainGame());

            // Wire up tile click callbacks
            if (tiles != null)
            {
                foreach (var tile in tiles)
                {
                    if (tile == null) continue;
                    tile.OnClicked = () => Select(tile);
                }
            }

            await RefreshFromPlayerState();
        }

        private async Task RefreshFromPlayerState()
        {
            await GameManager.Instance.RefreshPlayerState();
            var ps = GameManager.Instance.PlayerState;
            if (ps == null) return;

            if (villageNameText != null)
                villageNameText.text = ps.CurrentVillage?.Name ?? "Village";

            // Bind tile data by index (assumes tiles ordered the same as backend)
            int count = Mathf.Min(tiles?.Length ?? 0, ps.Buildings?.Count ?? 0);
            for (int i = 0; i < count; i++)
            {
                tiles[i].Bind(ps.Buildings[i]);
            }

            UpdateProgress(ps.Buildings);
            UpdateCoinsText();
        }

        private void UpdateProgress(List<UserBuildingModel> buildings)
        {
            if (buildings == null) return;
            int totalStars = 0;
            int maxStars = buildings.Count * 4;
            foreach (var b in buildings)
            {
                if (!b.IsDestroyed) totalStars += b.UpgradeLevel;
            }
            if (progressText != null) progressText.text = $"⭐ {totalStars}/{maxStars}";
            if (progressBar != null)
                progressBar.value = maxStars > 0 ? (float)totalStars / maxStars : 0f;
        }

        private void UpdateCoinsText()
        {
            if (coinsText != null && GameManager.Instance.User != null)
            {
                coinsText.text = $"Your coins: {GameManager.Instance.User.Coins:N0}";
            }
        }

        public void Select(BuildingTile tile)
        {
            _selected = tile;
            AudioManager.Instance?.PlayButtonTap();
            if (upgradePanel != null) upgradePanel.SetActive(true);
            var b = tile.Data;
            if (b == null) return;
            if (upgradeNameText != null) upgradeNameText.text = b.BuildingName;
            if (upgradeLevelText != null)
                upgradeLevelText.text = b.UpgradeLevel >= 4
                    ? "⭐ Fully upgraded!"
                    : (b.IsDestroyed ? "💥 Destroyed" : $"Level {b.UpgradeLevel} → {b.UpgradeLevel + 1}");
            if (upgradeCostText != null)
                upgradeCostText.text = b.UpgradeLevel >= 4
                    ? "-"
                    : $"💰 {b.NextUpgradeCost:N0}";
            if (upgradeButton != null)
                upgradeButton.interactable = b.CanAfford && b.UpgradeLevel < 4 && !b.IsDestroyed && !_upgrading;
            UpdateCoinsText();
        }

        public void CloseUpgradePanel()
        {
            if (upgradePanel != null) upgradePanel.SetActive(false);
            _selected = null;
        }

        private async Task DoUpgrade()
        {
            if (_selected == null || _upgrading) return;
            _upgrading = true;
            if (upgradeButton != null) upgradeButton.interactable = false;

            try
            {
                var result = await ApiClient.Instance.Post<BuildResultModel>(
                    ApiEndpoints.UpgradeBuilding(_selected.Data.BuildingId),
                    null);

                AudioManager.Instance?.PlayBuildUpgrade();

                // Update local state & tile
                _selected.Data.UpgradeLevel = result.NewLevel;
                _selected.ApplyLevelVisuals();

                if (GameManager.Instance.User != null)
                    GameManager.Instance.User.Coins = result.CoinsRemaining;

                if (result.VillageCompleted)
                {
                    AudioManager.Instance?.PlayVillageComplete();
                    if (villageCompleteDialog != null) villageCompleteDialog.SetActive(true);
                }

                await RefreshFromPlayerState();
                CloseUpgradePanel();
            }
            catch (ApiException e)
            {
                Debug.LogError($"Upgrade failed: {e.Message}");
            }
            finally
            {
                _upgrading = false;
                if (upgradeButton != null && _selected != null) Select(_selected);
            }
        }
    }
}
