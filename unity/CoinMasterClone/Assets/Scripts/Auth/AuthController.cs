using System.Threading.Tasks;
using CoinMasterClone.Api;
using CoinMasterClone.Api.Models;
using CoinMasterClone.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace CoinMasterClone.Auth
{
    /// <summary>
    /// Login / register screen. Wire up TMP_InputFields and Buttons in the Editor.
    /// </summary>
    public class AuthController : MonoBehaviour
    {
        [Header("Inputs")]
        public TMP_InputField emailField;
        public TMP_InputField passwordField;
        public TMP_InputField displayNameField; // used for register only

        [Header("Buttons")]
        public Button loginButton;
        public Button registerButton;

        [Header("Status")]
        public TextMeshProUGUI statusText;

        async void Start()
        {
            if (loginButton != null) loginButton.onClick.AddListener(() => _ = DoLogin());
            if (registerButton != null) registerButton.onClick.AddListener(() => _ = DoRegister());

            // Auto-login if we already have a valid token
            if (ApiClient.Instance != null && ApiClient.Instance.IsAuthenticated)
            {
                try
                {
                    await GameManager.Instance.RefreshPlayerState();
                    GameManager.Instance.LoadMainGame();
                }
                catch
                {
                    ApiClient.Instance.ClearToken();
                }
            }
        }

        private async Task DoLogin()
        {
            SetStatus("Logging in...", Color.white);
            try
            {
                var resp = await ApiClient.Instance.Post<AuthResponse>(
                    ApiEndpoints.Login,
                    new LoginRequest
                    {
                        Email = emailField.text,
                        Password = passwordField.text
                    });
                ApiClient.Instance.Token = resp.Token;
                await GameManager.Instance.RefreshPlayerState();
                GameManager.Instance.LoadMainGame();
            }
            catch (ApiException e)
            {
                SetStatus($"Login failed: {e.Message}", Color.red);
            }
        }

        private async Task DoRegister()
        {
            SetStatus("Creating account...", Color.white);
            try
            {
                var resp = await ApiClient.Instance.Post<AuthResponse>(
                    ApiEndpoints.Register,
                    new RegisterRequest
                    {
                        Email = emailField.text,
                        Password = passwordField.text,
                        DisplayName = displayNameField != null ? displayNameField.text : emailField.text
                    });
                ApiClient.Instance.Token = resp.Token;
                await GameManager.Instance.RefreshPlayerState();
                GameManager.Instance.LoadMainGame();
            }
            catch (ApiException e)
            {
                SetStatus($"Register failed: {e.Message}", Color.red);
            }
        }

        private void SetStatus(string msg, Color color)
        {
            if (statusText == null) return;
            statusText.text = msg;
            statusText.color = color;
        }
    }
}
