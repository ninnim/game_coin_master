using System.Collections.Generic;
using System.Threading.Tasks;
using CoinMasterClone.Api;
using CoinMasterClone.Api.Models;
using CoinMasterClone.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace CoinMasterClone.Raid
{
    /// <summary>
    /// Raid mini-game. Auto-fetches a random public target, shows a 3x3 grid of
    /// mounds, the player taps 3 (or 4 with Foxy pet), the pig digs and reveals
    /// coins or an empty hole per pick.
    ///
    /// Editor setup:
    ///  - Create a "Raid" scene with a 3x3 grid of GameObjects each having a
    ///    Collider/Button (add the HoleTile component)
    ///  - Drag the 9 tiles into [tiles] (positions 0..8 left-to-right, top-to-bottom)
    ///  - Add a pig 3D model as [pig]
    /// </summary>
    public class RaidScreenController : MonoBehaviour
    {
        [Header("Target UI")]
        public TextMeshProUGUI targetNameText;
        public TextMeshProUGUI targetBankText;
        public TextMeshProUGUI instructionText;

        [Header("3x3 grid tiles")]
        public HoleTile[] tiles = new HoleTile[9];

        [Header("Pig character")]
        public Transform pig;

        [Header("Result UI")]
        public GameObject resultPanel;
        public TextMeshProUGUI totalText;
        public Button continueButton;

        private PlayerTargetModel _target;
        private readonly List<int> _picks = new();
        private int _maxPicks = 3;
        private RaidResultModel _result;

        async void Start()
        {
            if (continueButton != null)
                continueButton.onClick.AddListener(() => GameManager.Instance.LoadMainGame());
            if (resultPanel != null) resultPanel.SetActive(false);

            // Wire up tile click callbacks
            for (int i = 0; i < tiles.Length; i++)
            {
                if (tiles[i] == null) continue;
                int idx = i;
                tiles[i].index = idx;
                tiles[i].OnClicked = () => OnTileClicked(idx);
            }

            await LoadTarget();
        }

        private async Task LoadTarget()
        {
            try
            {
                var targets = await ApiClient.Instance.Get<List<PlayerTargetModel>>(
                    ApiEndpoints.PlayerTargets);
                if (targets == null || targets.Count == 0)
                {
                    GameManager.Instance.LoadMainGame();
                    return;
                }
                _target = targets[Random.Range(0, targets.Count)];
                if (targetNameText != null) targetNameText.text = _target.DisplayName;
                if (targetBankText != null)
                    targetBankText.text = $"🐷 {_target.PigBankCoins:N0}";
                if (instructionText != null)
                    instructionText.text = $"Pick {_maxPicks} holes to dig!";
            }
            catch (ApiException e)
            {
                Debug.LogError($"Failed to load raid target: {e.Message}");
                GameManager.Instance.LoadMainGame();
            }
        }

        private async void OnTileClicked(int idx)
        {
            if (_picks.Contains(idx) || _picks.Count >= _maxPicks || _result != null) return;
            _picks.Add(idx);
            tiles[idx].ShowSelected();
            AudioManager.Instance?.PlayButtonTap();

            if (instructionText != null)
                instructionText.text = _picks.Count < _maxPicks
                    ? $"Pick {_maxPicks - _picks.Count} more!"
                    : "Digging...";

            if (_picks.Count >= _maxPicks)
            {
                await ExecuteRaid();
            }
        }

        private async Task ExecuteRaid()
        {
            AudioManager.Instance?.PlayRaid();

            try
            {
                _result = await ApiClient.Instance.Post<RaidResultModel>(
                    ApiEndpoints.Raid,
                    new RaidRequest
                    {
                        VictimId = _target.UserId,
                        HolePositions = _picks.ToArray()
                    });
            }
            catch (ApiException e)
            {
                Debug.LogError($"Raid API failed: {e.Message}");
                GameManager.Instance.LoadMainGame();
                return;
            }

            // Reveal each hole one by one
            foreach (var hr in _result.HoleResults)
            {
                if (hr.Position < 0 || hr.Position >= tiles.Length) continue;
                var tile = tiles[hr.Position];
                if (tile == null) continue;

                // Move pig over to the hole
                if (pig != null)
                {
                    pig.position = tile.transform.position + Vector3.up * 0.5f;
                }
                await Task.Delay(300);
                tile.RevealCoins(hr.CoinsFound);
                if (hr.CoinsFound > 0) AudioManager.Instance?.PlayCoinWin();
                await Task.Delay(600);
            }

            ShowResult();
            await GameManager.Instance.RefreshPlayerState();
        }

        private void ShowResult()
        {
            if (resultPanel != null) resultPanel.SetActive(true);
            if (totalText != null)
                totalText.text = $"+{_result.TotalCoinsStolen:N0} coins stolen!";
        }
    }
}
