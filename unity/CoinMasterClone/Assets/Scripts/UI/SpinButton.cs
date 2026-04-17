using CoinMasterClone.Core;
using CoinMasterClone.Slot;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace CoinMasterClone.UI
{
    /// <summary>
    /// Wires the SPIN button to the <see cref="SlotMachineController"/>.
    /// Disables itself when a spin is in-flight or the player can't afford the current bet.
    /// </summary>
    [RequireComponent(typeof(Button))]
    public class SpinButton : MonoBehaviour
    {
        [Header("References")]
        public SlotMachineController slotMachine;
        public WinEffectController winEffect;
        public TextMeshProUGUI label;

        private Button _button;

        void Awake()
        {
            _button = GetComponent<Button>();
            _button.onClick.AddListener(OnClick);
        }

        void Start()
        {
            if (slotMachine != null)
                slotMachine.OnSpinComplete += OnSpinComplete;
            if (GameManager.Instance != null)
                GameManager.Instance.OnPlayerStateChanged += Refresh;
            Refresh();
        }

        void OnDestroy()
        {
            if (slotMachine != null)
                slotMachine.OnSpinComplete -= OnSpinComplete;
            if (GameManager.Instance != null)
                GameManager.Instance.OnPlayerStateChanged -= Refresh;
        }

        private void OnClick()
        {
            AudioManager.Instance?.PlayButtonTap();
            _ = slotMachine?.DoSpin();
        }

        private void OnSpinComplete(Api.Models.SpinResultModel result)
        {
            winEffect?.Show(result);
            Refresh();
        }

        private void Refresh()
        {
            var gm = GameManager.Instance;
            bool canSpin = gm != null && gm.User != null
                && gm.User.Spins >= gm.CurrentBet
                && (slotMachine == null || !slotMachine.IsSpinning);

            if (_button != null) _button.interactable = canSpin;
            if (label != null)
                label.text = canSpin ? "SPIN" : (gm?.User?.Spins < gm?.CurrentBet ? "NO SPINS" : "...");
        }
    }
}
