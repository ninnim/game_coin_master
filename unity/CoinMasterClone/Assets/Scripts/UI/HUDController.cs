using CoinMasterClone.Core;
using TMPro;
using UnityEngine;

namespace CoinMasterClone.UI
{
    /// <summary>
    /// Top HUD: coin count, spins, shields, level.
    /// Subscribes to <see cref="GameManager.OnPlayerStateChanged"/>.
    ///
    /// Editor setup:
    ///  - Create a Canvas with a horizontal bar
    ///  - Drag the TMP texts into the inspector fields
    ///  - Place shield icons with the "shieldIcons" array
    /// </summary>
    public class HUDController : MonoBehaviour
    {
        [Header("Texts")]
        public TextMeshProUGUI coinText;
        public TextMeshProUGUI spinText;
        public TextMeshProUGUI levelText;

        [Header("Shields")]
        [Tooltip("Exactly 3 shield icons (GameObjects) — enabled if player has that many shields.")]
        public GameObject[] shieldIcons = new GameObject[3];

        [Header("Active Colors")]
        public Color shieldActiveColor = new Color(0f, 0.9f, 1f, 1f);
        public Color shieldInactiveColor = new Color(1f, 1f, 1f, 0.25f);

        void OnEnable()
        {
            if (GameManager.Instance != null)
            {
                GameManager.Instance.OnPlayerStateChanged += Refresh;
            }
            Refresh();
        }

        void OnDisable()
        {
            if (GameManager.Instance != null)
            {
                GameManager.Instance.OnPlayerStateChanged -= Refresh;
            }
        }

        public void Refresh()
        {
            var u = GameManager.Instance?.User;
            if (u == null) return;

            if (coinText != null) coinText.text = FormatCompact(u.Coins);
            if (spinText != null) spinText.text = u.Spins.ToString();
            if (levelText != null) levelText.text = u.VillageLevel.ToString();

            for (int i = 0; i < shieldIcons.Length; i++)
            {
                if (shieldIcons[i] == null) continue;
                var img = shieldIcons[i].GetComponent<UnityEngine.UI.Image>();
                if (img != null)
                {
                    img.color = (i < u.ShieldCount) ? shieldActiveColor : shieldInactiveColor;
                }
            }
        }

        public static string FormatCompact(long n)
        {
            if (n >= 1_000_000_000) return (n / 1_000_000_000d).ToString("0.#") + "B";
            if (n >= 1_000_000) return (n / 1_000_000d).ToString("0.#") + "M";
            if (n >= 1_000) return (n / 1_000d).ToString("0.#") + "K";
            return n.ToString("N0");
        }
    }
}
