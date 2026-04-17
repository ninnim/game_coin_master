using System;
using System.Threading.Tasks;
using CoinMasterClone.Api;
using CoinMasterClone.Api.Models;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CoinMasterClone.Core
{
    /// <summary>
    /// Global singleton for player state, scene transitions, and pending actions.
    /// Attach once to a GameObject in the boot scene; it survives all scene loads.
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        // ── Player state (cached locally, refreshed from API) ──
        public UserModel User { get; private set; }
        public VillageModel CurrentVillage { get; private set; }
        public PlayerStateModel PlayerState { get; private set; }

        // ── Pending actions (set by spin results) ──
        public bool PendingAttack { get; set; }
        public bool PendingRaid { get; set; }

        // ── Bet multiplier tiers (Coin Master style up to x100K) ──
        public static readonly int[] BetTiers =
        {
            1, 2, 3, 5, 10, 25, 50, 100, 200, 500,
            1000, 2000, 5000, 10000, 25000, 50000, 100000
        };

        public int CurrentBet { get; set; } = 1;

        // ── Events for UI to listen ──
        public event Action OnPlayerStateChanged;
        public event Action<SpinResultModel> OnSpinResult;

        void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        // ─ Refresh from backend ─
        public async Task RefreshPlayerState()
        {
            try
            {
                var ps = await ApiClient.Instance.Get<PlayerStateModel>(ApiEndpoints.PlayerState);
                PlayerState = ps;
                User = ps.User;
                CurrentVillage = ps.CurrentVillage;
                OnPlayerStateChanged?.Invoke();
            }
            catch (ApiException e)
            {
                Debug.LogWarning($"PlayerState refresh failed: {e.Message}");
            }
        }

        public void ApplySpinResult(SpinResultModel result)
        {
            if (User != null)
            {
                User.Coins = result.CurrentCoins;
                User.Spins = result.SpinsRemaining;
            }
            OnSpinResult?.Invoke(result);
            OnPlayerStateChanged?.Invoke();
        }

        // ─ Scene navigation helpers ─
        public void LoadMainGame() => SceneManager.LoadScene("MainGame");
        public void LoadVillage() => SceneManager.LoadScene("Village");
        public void LoadAttack() => SceneManager.LoadScene("Attack");
        public void LoadRaid() => SceneManager.LoadScene("Raid");
        public void LoadLogin() => SceneManager.LoadScene("Login");
    }
}
