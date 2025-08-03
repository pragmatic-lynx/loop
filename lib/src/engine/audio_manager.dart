// lib/src/engine/audio_manager.dart
import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_audio' as web_audio;

/// Singleton audio manager for playing sound effects.
///
/// Provides fail-safe audio playback - missing files or unsupported
/// platforms will log warnings but not crash the game.
class AudioManager {
  static AudioManager? _instance;
  static AudioManager get i => _instance ??= AudioManager._();

  /// Set to true to disable audio file loading (useful for faster startup)
  static bool disableAudioLoading = true;

  AudioManager._();

  web_audio.AudioContext? _audioContext;
  final Map<String, List<web_audio.AudioBuffer>> _loadedSounds = {};
  final Map<String, web_audio.AudioBufferSourceNode?> _loopingSounds = {};
  final Set<String> _warnedMissing = {};
  final Random _random = Random();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize the audio system. Call this early in app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _audioContext = web_audio.AudioContext();
      
      // Modern browsers require user interaction before audio can play
      // The context starts in 'suspended' state until user interacts
      if (_audioContext!.state == 'suspended') {
        print('AudioContext suspended - will resume on first user interaction');
      }
      
      await _scanAudioFiles();
      _initialized = true;
      print('AudioManager initialized successfully');
    } catch (e) {
      print('AudioManager failed to initialize: $e');
      // Continue without audio - fail-safe behavior
    }
  }

  /// Scan the assets/audio/sfx directory for audio files
  Future<void> _scanAudioFiles() async {
    if (_audioContext == null) return;

    // Skip audio loading if disabled
    if (disableAudioLoading) {
      print('Audio file loading disabled - skipping audio file scan');
      return;
    }

    // For web builds, we need to predefine the expected files
    // since we can't scan directories dynamically
    final expectedFiles = [
      'player/arrow_release_01.ogg',
      'player/arrow_impact_wood_01.ogg', 
      'player/magic_cast_01.ogg',
      'player/magic_hit_01.ogg',
      'player/player_hurt_01.ogg',
      'enemy/enemy_death_01.ogg',
      'ui/ui_confirm_01.ogg',
      'ui/ui_cancel_01.ogg',
      'loot/coin_pickup_01.ogg',
      'loops/mage_charge_loop.ogg',
      'stingers/level_up_01.ogg',
      'stingers/pause_toggle_01.ogg',
    ];

    for (final filePath in expectedFiles) {
      await _tryLoadAudioFile(filePath);
    }
  }

  /// Attempt to load a single audio file
  Future<void> _tryLoadAudioFile(String filePath) async {
    if (_audioContext == null) return;

    try {
      final response = await html.HttpRequest.request(
        'assets/audio/sfx/$filePath',
        responseType: 'arraybuffer',
      );

      if (response.status == 200) {
        final audioData = response.response as ByteBuffer;
        final audioBuffer = await _audioContext!.decodeAudioData(audioData);
        
        // Extract the ID (filename without extension and variation number)
        final id = _extractSoundId(filePath);
        
        _loadedSounds.putIfAbsent(id, () => []).add(audioBuffer);
      }
    } catch (e) {
      // Silently ignore missing files - this is expected fail-safe behavior
    }
  }

  /// Extract sound ID from file path
  /// Example: 'player/arrow_release_01.ogg' -> 'player_arrow_release'
  String _extractSoundId(String filePath) {
    final parts = filePath.split('/');
    final directory = parts.first;
    final fileName = parts.last;
    final nameWithoutExt = fileName.split('.').first;
    
    // Remove variation numbers (_01, _02, etc.)
    final baseName = nameWithoutExt.replaceAll(RegExp(r'_\d+$'), '');
    
    // Combine directory and filename: 'player/magic_cast_01.ogg' -> 'player_magic_cast'
    return '${directory}_$baseName';
  }

  /// Play a sound effect
  void play(String id, {double volume = 1.0, double pitchVar = 0.05}) {
    if (!_initialized || _audioContext == null) return;

    // Resume audio context if suspended (browser requirement)
    _resumeAudioContext();

    final sounds = _loadedSounds[id];
    if (sounds == null || sounds.isEmpty) {
      _warnOnce(id);
      return;
    }

    try {
      // Pick a random variation if multiple exist
      final audioBuffer = sounds[_random.nextInt(sounds.length)];
      
      final source = _audioContext!.createBufferSource();
      source.buffer = audioBuffer;
      
      // Apply pitch variation
      if (pitchVar > 0) {
        final pitchOffset = (_random.nextDouble() - 0.5) * 2 * pitchVar;
        source.playbackRate?.value = 1.0 + pitchOffset;
      }
      
      // Apply volume
      final gainNode = _audioContext!.createGain();
      gainNode.gain?.value = volume;
      
      source.connectNode(gainNode);
      gainNode.connectNode(_audioContext!.destination!);
      
      source.start();
    } catch (e) {
      print('Error playing sound $id: $e');
    }
  }

  /// Start looping a sound
  void loop(String id, {double volume = 1.0}) {
    if (!_initialized || _audioContext == null) return;

    // Resume audio context if suspended (browser requirement)
    _resumeAudioContext();

    // Stop existing loop if any
    stopLoop(id);

    final sounds = _loadedSounds[id];
    if (sounds == null || sounds.isEmpty) {
      _warnOnce(id);
      return;
    }

    try {
      final audioBuffer = sounds[_random.nextInt(sounds.length)];
      
      final source = _audioContext!.createBufferSource();
      source.buffer = audioBuffer;
      source.loop = true;
      
      final gainNode = _audioContext!.createGain();
      gainNode.gain?.value = volume;
      
      source.connectNode(gainNode);
      gainNode.connectNode(_audioContext!.destination!);
      
      source.start();
      _loopingSounds[id] = source;
    } catch (e) {
      print('Error looping sound $id: $e');
    }
  }

  /// Stop a looping sound
  void stopLoop(String id) {
    final source = _loopingSounds[id];
    if (source != null) {
      try {
        source.stop();
      } catch (e) {
        // Ignore - source may already be stopped
      }
      _loopingSounds.remove(id);
    }
  }

  /// Check if a sound effect is available
  bool isSfxAvailable(String id) {
    return _loadedSounds.containsKey(id) && _loadedSounds[id]!.isNotEmpty;
  }

  /// Resume audio context if suspended (required by modern browsers)
  void _resumeAudioContext() {
    if (_audioContext?.state == 'suspended') {
      _audioContext!.resume().catchError((e) {
        print('Failed to resume AudioContext: $e');
      });
    }
  }

  /// Log warning once per session for missing sounds
  void _warnOnce(String id) {
    if (_warnedMissing.add(id)) {
      print('Audio file not found for SFX ID: $id');
    }
  }

  /// Clean up audio resources
  void dispose() {
    for (final source in _loopingSounds.values) {
      try {
        source?.stop();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    _loopingSounds.clear();
    _loadedSounds.clear();
    _audioContext?.close();
    _audioContext = null;
    _initialized = false;
  }
}
