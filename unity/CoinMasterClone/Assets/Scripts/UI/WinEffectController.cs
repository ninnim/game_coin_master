using System.Collections;
using CoinMasterClone.Api.Models;
using CoinMasterClone.Core;
using TMPro;
using UnityEngine;

namespace CoinMasterClone.UI
{
    /// <summary>
    /// Full-screen win overlay. Listens to <see cref="SlotMachineController.OnSpinComplete"/>
    /// (wire in Editor or via code) and shows the correct effect:
    ///  - 3 attacks/raids: navigate to Attack/Raid scenes
    ///  - 3 shields: shield flash
    ///  - Coins/jackpot: animated coin shower
    ///
    /// Editor setup:
    ///  - Create a Canvas overlay with the text and particle system disabled by default
    ///  - Drag the elements into the fields
    /// </summary>
    public class WinEffectController : MonoBehaviour
    {
        [Header("Overlay root (toggled on/off)")]
        public GameObject overlay;

        [Header("Texts")]
        public TextMeshProUGUI titleText;
        public TextMeshProUGUI amountText;
        public TextMeshProUGUI iconText; // use emoji glyphs

        [Header("Particle systems (optional)")]
        public ParticleSystem coinShower;
        public ParticleSystem jackpotBurst;

        [Header("Timing")]
        public float displayDuration = 2.2f;

        void Awake()
        {
            if (overlay != null) overlay.SetActive(false);
        }

        public void Show(SpinResultModel result)
        {
            if (result == null) return;
            // 3-of-a-kind attacks / raids jump to their mini-game scenes
            if (result.SpecialAction == "attack")
            {
                AudioManager.Instance?.PlayAttack();
                ShowBanner("ATTACK!", "⚔️", "", new Color(1f, 0.1f, 0.25f));
                StartCoroutine(DelayThenScene(() => GameManager.Instance.LoadAttack()));
                return;
            }
            if (result.SpecialAction == "raid")
            {
                AudioManager.Instance?.PlayRaid();
                ShowBanner("RAID!", "🐷", "", new Color(1f, 0.45f, 0f));
                StartCoroutine(DelayThenScene(() => GameManager.Instance.LoadRaid()));
                return;
            }
            if (result.SpecialAction == "shield")
            {
                AudioManager.Instance?.PlayShield();
                ShowBanner("SHIELD!", "🛡️", "", new Color(0f, 0.9f, 1f));
                StartCoroutine(AutoHide());
                return;
            }
            if (result.SpecialAction == "energy")
            {
                AudioManager.Instance?.PlayEnergy();
                ShowBanner($"+{result.SpinsEarned} SPINS", "⚡", "", Color.yellow);
                StartCoroutine(AutoHide());
                return;
            }
            if (result.IsJackpot)
            {
                AudioManager.Instance?.PlayJackpot();
                ShowBanner("JACKPOT!", "🎰", $"+{result.CoinsEarned:N0}", new Color(1f, 0.85f, 0f));
                jackpotBurst?.Play();
                StartCoroutine(AutoHide());
                return;
            }
            if (result.CoinsEarned > 0)
            {
                AudioManager.Instance?.PlayCoinWin();
                ShowBanner("", "💰", $"+{result.CoinsEarned:N0}", new Color(1f, 0.85f, 0f));
                coinShower?.Play();
                StartCoroutine(AutoHide());
            }
        }

        private void ShowBanner(string title, string icon, string amount, Color tint)
        {
            if (overlay != null) overlay.SetActive(true);
            if (titleText != null) { titleText.text = title; titleText.color = tint; }
            if (amountText != null) amountText.text = amount;
            if (iconText != null) iconText.text = icon;
        }

        private IEnumerator AutoHide()
        {
            yield return new WaitForSeconds(displayDuration);
            if (overlay != null) overlay.SetActive(false);
        }

        private IEnumerator DelayThenScene(System.Action loadScene)
        {
            yield return new WaitForSeconds(displayDuration);
            if (overlay != null) overlay.SetActive(false);
            loadScene?.Invoke();
        }
    }
}
