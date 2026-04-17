using CoinMasterClone.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace CoinMasterClone.UI
{
    /// <summary>
    /// Bet multiplier selector (x1 ... x100K). Wraps <see cref="GameManager.BetTiers"/>.
    ///
    /// Editor setup:
    ///  - Place a "-" Button, a TMP text, and a "+" Button in a horizontal layout
    ///  - Drag them into the corresponding fields
    /// </summary>
    public class BetSelector : MonoBehaviour
    {
        [Header("References")]
        public Button decreaseButton;
        public Button increaseButton;
        public TextMeshProUGUI betText;

        private int _index = 0;

        void Start()
        {
            _index = System.Array.IndexOf(GameManager.BetTiers, GameManager.Instance.CurrentBet);
            if (_index < 0) _index = 0;

            if (decreaseButton != null) decreaseButton.onClick.AddListener(Decrease);
            if (increaseButton != null) increaseButton.onClick.AddListener(Increase);
            Refresh();
        }

        public void Decrease()
        {
            if (_index > 0) _index--;
            Apply();
        }

        public void Increase()
        {
            if (_index < GameManager.BetTiers.Length - 1) _index++;
            Apply();
        }

        private void Apply()
        {
            Core.AudioManager.Instance?.PlayButtonTap();
            GameManager.Instance.CurrentBet = GameManager.BetTiers[_index];
            Refresh();
        }

        public void Refresh()
        {
            if (betText != null) betText.text = "BET " + FormatBet(GameManager.BetTiers[_index]);
        }

        private static string FormatBet(int bet)
        {
            if (bet >= 1000)
            {
                int k = bet / 1000;
                return $"x{k}K";
            }
            return $"x{bet}";
        }
    }
}
