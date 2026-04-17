using System;
using System.Collections;
using UnityEngine;

namespace CoinMasterClone.Slot
{
    /// <summary>
    /// A single 3D reel — a cylinder with 6 symbol planes arranged around its X-axis.
    ///
    /// Editor setup:
    ///  - Create an empty GameObject "Reel_0" / "Reel_1" / "Reel_2"
    ///  - Attach this script
    ///  - Create a child "SymbolRing" (empty GameObject) — set this as [symbolRing]
    ///  - Inside SymbolRing, place 6 quad/plane children, each textured with a symbol
    ///    (Coin, Attack, Raid, Shield, Energy, Bonus — in that order to match backend)
    ///    positioned around the X-axis at: y = sin(i·60°)·R, z = cos(i·60°)·R
    ///    and rotated so they face outward.
    ///  - See SETUP.md for a step-by-step layout.
    /// </summary>
    public class ReelController : MonoBehaviour
    {
        [Header("Identity")]
        public int reelIndex;

        [Header("References")]
        [Tooltip("Child GameObject containing the 6 symbol planes arranged in a ring.")]
        public Transform symbolRing;

        [Header("Tuning")]
        public int symbolCount = 6;
        [Tooltip("Spin speed in degrees per second.")]
        public float maxSpinSpeed = 900f;
        [Tooltip("Time (seconds) for the smooth deceleration to the target symbol.")]
        public float decelerationDuration = 1.1f;
        [Tooltip("Extra full rotations before landing (adds drama).")]
        public float extraRotations = 2.5f;

        // Runtime state
        private float _angle;
        private bool _isSpinning;
        private bool _isDecelerating;
        private float _decelStartAngle;
        private float _targetAngle;
        private float _decelStartTime;

        /// <summary>Invoked when this reel finishes decelerating on its target symbol.</summary>
        public event Action<int> OnStopped;

        /// <summary>Begins the continuous free spin.</summary>
        public void StartSpin()
        {
            _isSpinning = true;
            _isDecelerating = false;
        }

        /// <summary>
        /// Decelerates to land centered on [targetSymbol] (0..symbolCount-1),
        /// after [delay] seconds. Call this for each of the 3 reels with a
        /// staggered delay so they stop in sequence.
        /// </summary>
        public void StopAt(int targetSymbol, float delay)
        {
            StartCoroutine(StopAtCo(targetSymbol, delay));
        }

        private IEnumerator StopAtCo(int targetSymbol, float delay)
        {
            if (delay > 0f) yield return new WaitForSeconds(delay);

            float anglePerSymbol = 360f / symbolCount;
            _decelStartAngle = _angle;

            // Current rotation normalised to 0..360
            float baseMod = Mathf.Repeat(_angle, 360f);
            float desired = -targetSymbol * anglePerSymbol;
            float desiredMod = Mathf.Repeat(desired, 360f);
            float delta = Mathf.Repeat(desiredMod - baseMod, 360f);

            _targetAngle = _angle + extraRotations * 360f + delta;
            _decelStartTime = Time.time;
            _isDecelerating = true;
        }

        void Update()
        {
            if (_isDecelerating)
            {
                float elapsed = Time.time - _decelStartTime;
                float t = Mathf.Clamp01(elapsed / decelerationDuration);
                float eased = 1f - Mathf.Pow(1f - t, 3f); // ease-out cubic
                _angle = Mathf.Lerp(_decelStartAngle, _targetAngle, eased);

                if (t >= 1f)
                {
                    _angle = _targetAngle;
                    _isDecelerating = false;
                    _isSpinning = false;
                    OnStopped?.Invoke(reelIndex);
                }
            }
            else if (_isSpinning)
            {
                _angle += maxSpinSpeed * Time.deltaTime;
            }

            if (symbolRing != null)
            {
                symbolRing.localRotation = Quaternion.Euler(_angle, 0f, 0f);
            }
        }
    }
}
