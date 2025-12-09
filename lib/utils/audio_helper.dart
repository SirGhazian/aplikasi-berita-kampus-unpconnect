import 'package:audioplayers/audioplayers.dart';

class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playError() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/notif_error.MP3'));
    } catch (e) {
      // Ignore audio errors
    }
  }

  static Future<void> playSuccess() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/notif_posting.MP3'));
    } catch (e) {
      // Ignore audio errors
    }
  }
}
