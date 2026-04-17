using UnityEngine;

namespace CoinMasterClone.Core
{
    /// <summary>
    /// Plays game sound effects through a pool of AudioSources so sounds can overlap.
    ///
    /// Editor setup:
    ///  - Create an empty GameObject called "AudioManager" in the boot scene
    ///  - Attach this script
    ///  - Drag your AudioClips into the public fields
    /// </summary>
    public class AudioManager : MonoBehaviour
    {
        public static AudioManager Instance { get; private set; }

        [Header("SFX Clips")]
        public AudioClip spinStart;
        public AudioClip reelStop;
        public AudioClip coinWin;
        public AudioClip jackpot;
        public AudioClip attack;
        public AudioClip raid;
        public AudioClip shield;
        public AudioClip energy;
        public AudioClip buttonTap;
        public AudioClip buildUpgrade;
        public AudioClip villageComplete;

        [Header("Music")]
        public AudioClip backgroundMusic;

        [Header("Settings")]
        [Range(0f, 1f)] public float sfxVolume = 0.8f;
        [Range(0f, 1f)] public float musicVolume = 0.4f;
        public int poolSize = 6;

        private AudioSource[] _sfxPool;
        private int _poolIndex;
        private AudioSource _musicSource;

        void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);

            _sfxPool = new AudioSource[poolSize];
            for (int i = 0; i < poolSize; i++)
            {
                _sfxPool[i] = gameObject.AddComponent<AudioSource>();
                _sfxPool[i].playOnAwake = false;
                _sfxPool[i].volume = sfxVolume;
            }

            _musicSource = gameObject.AddComponent<AudioSource>();
            _musicSource.loop = true;
            _musicSource.volume = musicVolume;
            _musicSource.playOnAwake = false;

            if (backgroundMusic != null)
            {
                _musicSource.clip = backgroundMusic;
                _musicSource.Play();
            }
        }

        public void PlaySpinStart()      => Play(spinStart);
        public void PlayReelStop()       => Play(reelStop);
        public void PlayCoinWin()        => Play(coinWin);
        public void PlayJackpot()        => Play(jackpot);
        public void PlayAttack()         => Play(attack);
        public void PlayRaid()           => Play(raid);
        public void PlayShield()         => Play(shield);
        public void PlayEnergy()         => Play(energy);
        public void PlayButtonTap()      => Play(buttonTap, 0.5f);
        public void PlayBuildUpgrade()   => Play(buildUpgrade);
        public void PlayVillageComplete()=> Play(villageComplete);

        private void Play(AudioClip clip, float volumeScale = 1f)
        {
            if (clip == null || _sfxPool == null) return;
            var src = _sfxPool[_poolIndex];
            _poolIndex = (_poolIndex + 1) % _sfxPool.Length;
            src.volume = sfxVolume * volumeScale;
            src.PlayOneShot(clip);
        }

        public void ToggleMusic(bool on)
        {
            if (_musicSource == null) return;
            if (on && !_musicSource.isPlaying) _musicSource.Play();
            else if (!on && _musicSource.isPlaying) _musicSource.Pause();
        }
    }
}
