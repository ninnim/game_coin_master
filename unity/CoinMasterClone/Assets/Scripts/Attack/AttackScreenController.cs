using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using CoinMasterClone.Api;
using CoinMasterClone.Api.Models;
using CoinMasterClone.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace CoinMasterClone.Attack
{
    /// <summary>
    /// Attack mini-game. Auto-fetches a random public target, shows their 3D village,
    /// drops an animated hammer onto a random building, then posts the attack.
    ///
    /// Editor setup:
    ///  - Create an "Attack" scene with:
    ///      * 3D village camera + directional light
    ///      * Child GameObjects for each building (drag into [buildings])
    ///      * A hammer 3D model (drag into [hammer])
    ///      * UI canvas with target name / level / result texts
    /// </summary>
    public class AttackScreenController : MonoBehaviour
    {
        [Header("Target UI")]
        public TextMeshProUGUI targetNameText;
        public TextMeshProUGUI targetLevelText;

        [Header("Village buildings (drag 5-9 GameObjects)")]
        public GameObject[] buildings;

        [Header("Hammer")]
        public Transform hammer;
        [Tooltip("World-space Y position where the hammer starts, above the screen.")]
        public float hammerStartY = 10f;
        [Tooltip("World-space Y position where the hammer strikes.")]
        public float hammerEndY = 0f;
        public float hammerFallDuration = 0.7f;

        [Header("FX")]
        public ParticleSystem explosionFx;
        public GameObject shieldBlockVfx;

        [Header("Result UI")]
        public GameObject resultPanel;
        public TextMeshProUGUI resultTitleText;
        public TextMeshProUGUI resultSubtitleText;
        public Button continueButton;

        private PlayerTargetModel _target;
        private int _destroyedIdx;

        async void Start()
        {
            if (continueButton != null)
                continueButton.onClick.AddListener(() => GameManager.Instance.LoadMainGame());
            if (resultPanel != null) resultPanel.SetActive(false);
            if (shieldBlockVfx != null) shieldBlockVfx.SetActive(false);
            if (hammer != null) hammer.gameObject.SetActive(false);

            await LoadTarget();
            await Task.Delay(600);
            await ExecuteAttack();
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
                if (targetLevelText != null) targetLevelText.text = $"Village {_target.VillageLevel}";
                _destroyedIdx = Random.Range(0, buildings?.Length ?? 1);
            }
            catch (ApiException e)
            {
                Debug.LogError($"Failed to load targets: {e.Message}");
                GameManager.Instance.LoadMainGame();
            }
        }

        private async Task ExecuteAttack()
        {
            AudioManager.Instance?.PlayAttack();

            // Animate hammer falling
            if (hammer != null)
            {
                hammer.gameObject.SetActive(true);
                Vector3 start = hammer.position; start.y = hammerStartY;
                Vector3 end = hammer.position; end.y = hammerEndY;
                hammer.position = start;
                float t = 0f;
                while (t < hammerFallDuration)
                {
                    t += Time.deltaTime;
                    float p = Mathf.Clamp01(t / hammerFallDuration);
                    float ease = 1f - Mathf.Pow(1f - p, 2f); // ease-in
                    hammer.position = Vector3.Lerp(start, end, ease);
                    hammer.rotation = Quaternion.Euler(0f, 0f, Mathf.Lerp(-35f, 0f, ease));
                    await Task.Yield();
                }
            }

            // Camera shake
            Camera.main?.transform.DOShake(0.4f, 0.3f);

            AttackResultModel result = null;
            try
            {
                result = await ApiClient.Instance.Post<AttackResultModel>(
                    ApiEndpoints.Attack,
                    new AttackRequest { TargetUserId = _target.UserId });
            }
            catch (ApiException e)
            {
                Debug.LogError($"Attack failed: {e.Message}");
            }

            if (result == null) { GameManager.Instance.LoadMainGame(); return; }

            // Visual outcome
            if (result.WasBlocked)
            {
                if (shieldBlockVfx != null) shieldBlockVfx.SetActive(true);
                AudioManager.Instance?.PlayShield();
                ShowResult("BLOCKED BY SHIELD!", "", new Color(0f, 0.9f, 1f));
            }
            else
            {
                // Destroy building visually
                if (buildings != null && _destroyedIdx < buildings.Length
                    && buildings[_destroyedIdx] != null)
                {
                    if (explosionFx != null)
                    {
                        explosionFx.transform.position = buildings[_destroyedIdx].transform.position;
                        explosionFx.Play();
                    }
                    buildings[_destroyedIdx].SetActive(false);
                }
                AudioManager.Instance?.PlayCoinWin();
                ShowResult("ATTACK SUCCESS!",
                    $"+{result.CoinsStolen:N0} coins!",
                    new Color(1f, 0.85f, 0f));
            }

            // Refresh local player state
            await GameManager.Instance.RefreshPlayerState();
        }

        private void ShowResult(string title, string subtitle, Color tint)
        {
            if (resultPanel != null) resultPanel.SetActive(true);
            if (resultTitleText != null) { resultTitleText.text = title; resultTitleText.color = tint; }
            if (resultSubtitleText != null) resultSubtitleText.text = subtitle;
        }
    }

    /// <summary>Tiny helper for camera shake (no DOTween dependency required).</summary>
    public static class TransformShakeExt
    {
        public static void DOShake(this Transform t, float magnitude, float duration)
        {
            var runner = t.GetComponent<ShakeRunner>() ?? t.gameObject.AddComponent<ShakeRunner>();
            runner.StartShake(magnitude, duration);
        }
    }

    public class ShakeRunner : MonoBehaviour
    {
        public void StartShake(float m, float d) => StartCoroutine(Run(m, d));
        private IEnumerator Run(float mag, float dur)
        {
            Vector3 origin = transform.localPosition;
            float t = 0f;
            while (t < dur)
            {
                t += Time.deltaTime;
                float dx = (Random.value - 0.5f) * mag;
                float dy = (Random.value - 0.5f) * mag;
                transform.localPosition = origin + new Vector3(dx, dy, 0f);
                yield return null;
            }
            transform.localPosition = origin;
        }
    }
}
