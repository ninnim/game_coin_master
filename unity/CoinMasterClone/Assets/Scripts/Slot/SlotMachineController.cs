using System.Collections.Generic;
using System.Threading.Tasks;
using CoinMasterClone.Api;
using CoinMasterClone.Api.Models;
using CoinMasterClone.Core;
using UnityEngine;

namespace CoinMasterClone.Slot
{
    /// <summary>
    /// Orchestrates the full spin flow:
    ///  1. Play spin-start sound + begin all 3 reel animations
    ///  2. POST /api/spin in parallel
    ///  3. When API returns, stagger-stop the reels on the result symbols
    ///  4. Fire OnSpinComplete when the last reel lands so UI can show effects
    ///
    /// Editor setup:
    ///  - Create a parent GameObject "SlotMachine"
    ///  - Attach this script
    ///  - Drag the 3 Reel_0/1/2 transforms into [reels]
    /// </summary>
    public class SlotMachineController : MonoBehaviour
    {
        [Header("Reels (left, middle, right)")]
        public ReelController[] reels = new ReelController[3];

        [Header("Stagger")]
        [Tooltip("Delay between reel 0, 1, 2 stops (seconds).")]
        public float reelStopStagger = 0.4f;

        [Header("Safety")]
        [Tooltip("Minimum time the reels spin before stopping (seconds).")]
        public float minSpinTime = 1.2f;

        public bool IsSpinning { get; private set; }

        /// <summary>Fires after all 3 reels have landed with the final API result.</summary>
        public event System.Action<SpinResultModel> OnSpinComplete;

        private readonly HashSet<int> _stoppedReels = new();
        private SpinResultModel _pendingResult;

        void Start()
        {
            foreach (var r in reels)
            {
                if (r != null) r.OnStopped += OnReelStopped;
            }
        }

        /// <summary>
        /// Runs a complete spin. Uses current bet from <see cref="GameManager.CurrentBet"/>.
        /// </summary>
        public async Task DoSpin()
        {
            if (IsSpinning) return;
            var gm = GameManager.Instance;
            int bet = gm.CurrentBet;

            if (gm.User == null || gm.User.Spins < bet)
            {
                AudioManager.Instance?.PlayButtonTap();
                Debug.LogWarning("Not enough spins");
                return;
            }

            IsSpinning = true;
            _stoppedReels.Clear();
            _pendingResult = null;

            AudioManager.Instance?.PlaySpinStart();
            foreach (var r in reels) r?.StartSpin();

            // Ensure the reels actually spin for a minimum duration even if API is fast
            var spinStartTime = Time.time;

            SpinResultModel result = null;
            try
            {
                result = await ApiClient.Instance.Post<SpinResultModel>(
                    ApiEndpoints.Spin,
                    new SpinRequest { BetMultiplier = bet });
            }
            catch (ApiException e)
            {
                Debug.LogError($"Spin API failed: {e.Message}");
                IsSpinning = false;
                foreach (var r in reels) r?.StopAt(0, 0f);
                return;
            }

            // Enforce min spin time for visual satisfaction
            float elapsed = Time.time - spinStartTime;
            if (elapsed < minSpinTime)
            {
                await Task.Delay(Mathf.RoundToInt((minSpinTime - elapsed) * 1000f));
            }

            _pendingResult = result;

            // Stagger the three stops
            int s1 = SymbolIndex(result.Slot1);
            int s2 = SymbolIndex(result.Slot2);
            int s3 = SymbolIndex(result.Slot3);
            reels[0]?.StopAt(s1, 0f);
            reels[1]?.StopAt(s2, reelStopStagger);
            reels[2]?.StopAt(s3, reelStopStagger * 2f);
        }

        private void OnReelStopped(int reelIndex)
        {
            AudioManager.Instance?.PlayReelStop();
            _stoppedReels.Add(reelIndex);
            if (_stoppedReels.Count >= 3 && _pendingResult != null)
            {
                IsSpinning = false;
                GameManager.Instance.ApplySpinResult(_pendingResult);
                OnSpinComplete?.Invoke(_pendingResult);
                _pendingResult = null;
            }
        }

        /// <summary>
        /// Maps the backend slot string to the symbol ring index.
        /// Order MUST match how you placed the 6 symbol planes in the Editor:
        /// 0=Coin, 1=Attack, 2=Raid, 3=Shield, 4=Energy, 5=Bonus
        /// </summary>
        public static int SymbolIndex(string slot)
        {
            return slot switch
            {
                "coin_small" or "coin_medium" or "coin_large" => 0,
                "attack" => 1,
                "raid" => 2,
                "shield" => 3,
                "energy" => 4,
                "jackpot" => 5,
                _ => 0,
            };
        }
    }
}
