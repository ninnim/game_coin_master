using System;
using System.Collections;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.Networking;

namespace CoinMasterClone.Api
{
    /// <summary>
    /// Singleton HTTP client for the ASP.NET Core backend.
    /// Uses UnityWebRequest with async/await. Persists the JWT token in PlayerPrefs.
    /// </summary>
    public class ApiClient : MonoBehaviour
    {
        public static ApiClient Instance { get; private set; }

        private const string TokenKey = "coinmaster_jwt";
        private string _token;

        public string Token
        {
            get => _token ??= PlayerPrefs.GetString(TokenKey, string.Empty);
            set
            {
                _token = value;
                PlayerPrefs.SetString(TokenKey, value ?? string.Empty);
                PlayerPrefs.Save();
            }
        }

        public bool IsAuthenticated => !string.IsNullOrEmpty(Token);

        void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        public void ClearToken()
        {
            _token = null;
            PlayerPrefs.DeleteKey(TokenKey);
            PlayerPrefs.Save();
        }

        // ═════════ GET ═════════
        public async Task<T> Get<T>(string path)
        {
            using var req = UnityWebRequest.Get(ApiEndpoints.BaseUrl + path);
            AttachHeaders(req);
            await SendAsync(req);
            return Deserialize<T>(req);
        }

        // ═════════ POST ═════════
        public async Task<T> Post<T>(string path, object body = null)
        {
            using var req = new UnityWebRequest(ApiEndpoints.BaseUrl + path, "POST");
            if (body != null)
            {
                var json = JsonConvert.SerializeObject(body);
                var bytes = Encoding.UTF8.GetBytes(json);
                req.uploadHandler = new UploadHandlerRaw(bytes);
            }
            req.downloadHandler = new DownloadHandlerBuffer();
            req.SetRequestHeader("Content-Type", "application/json");
            AttachHeaders(req);
            await SendAsync(req);
            return Deserialize<T>(req);
        }

        public async Task PostVoid(string path, object body = null)
        {
            await Post<object>(path, body);
        }

        // ═════════ Helpers ═════════
        private void AttachHeaders(UnityWebRequest req)
        {
            req.SetRequestHeader("Accept", "application/json");
            if (!string.IsNullOrEmpty(Token))
            {
                req.SetRequestHeader("Authorization", $"Bearer {Token}");
            }
        }

        private static Task SendAsync(UnityWebRequest req)
        {
            var tcs = new TaskCompletionSource<bool>();
            var op = req.SendWebRequest();
            op.completed += _ =>
            {
                if (req.result == UnityWebRequest.Result.Success)
                {
                    tcs.SetResult(true);
                }
                else
                {
                    tcs.SetException(new ApiException(
                        $"{req.method} {req.url} failed: {req.responseCode} {req.error}\n{req.downloadHandler?.text}",
                        (int)req.responseCode));
                }
            };
            return tcs.Task;
        }

        private static T Deserialize<T>(UnityWebRequest req)
        {
            var text = req.downloadHandler?.text ?? string.Empty;
            if (string.IsNullOrEmpty(text)) return default;
            try
            {
                return JsonConvert.DeserializeObject<T>(text);
            }
            catch (Exception e)
            {
                throw new ApiException($"JSON parse error: {e.Message}\nBody: {text}", 0);
            }
        }
    }

    public class ApiException : Exception
    {
        public int StatusCode { get; }
        public ApiException(string message, int statusCode) : base(message)
        {
            StatusCode = statusCode;
        }
    }
}
