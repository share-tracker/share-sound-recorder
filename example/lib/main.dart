import 'package:flutter/material.dart';
import 'package:flutter_logger_plus/flutter_logger_plus.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(home: Audio()));
}

class Audio extends StatefulWidget {
  const Audio({super.key});

  @override
  State<StatefulWidget> createState() => _AudioState();
}

class _AudioState extends State<Audio> {
  @override
  void initState() {
    super.initState();

    _initializeRecorder();
    _initializePlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    _recorder.closeRecorder();

    super.dispose();
  }

  String formatTime(Duration duration) {
    logger.info("formatTime duration: $duration");

    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    String result = '$minutes:${seconds.toString().padLeft(2, '0')}';

    logger.info("formatTime result: $result");
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        title: const Text(
          '녹음',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
            child: Column(
              children: [
                SliderTheme(
                  data: const SliderThemeData(
                    inactiveTrackColor: Colors.grey,
                  ),
                  child: Slider(
                    min: 0,
                    max: duration.inSeconds.toDouble(),
                    value: position.inSeconds.toDouble(),
                    onChanged: (value) async {
                      setState(() {
                        position = Duration(seconds: value.toInt());
                      });
                      await _player.seekToPlayer(position);
                    },
                    activeColor: Colors.black,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatTime(position),
                        style: const TextStyle(color: Colors.brown),
                      ),
                      const SizedBox(width: 20),
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.transparent,
                        child: IconButton(
                          padding: const EdgeInsets.only(bottom: 50),
                          icon: Icon(
                            _player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.brown,
                          ),
                          iconSize: 25,
                          onPressed: () async {
                            if (_player.isPlaying) {
                              _stopAudio();
                            } else {
                              _playAudio();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        formatTime(duration),
                        style: const TextStyle(color: Colors.brown),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          SizedBox(
            child: IconButton(
              onPressed: () {
                if (_recorder.isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },
              icon: Icon(
                _recorder.isRecording ? Icons.stop : Icons.mic,
                size: 30,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: 'audio.aac');
    setState(() {});
  }

  Future<void> _stopRecording() async {
    final url = await _recorder.stopRecorder();

    logger.cyan(url);

    setState(() {});
  }

  Future<void> _playAudio() async {
    if (!_player.isPlaying) {
      final directory = await getTemporaryDirectory();

      final path = '${directory.path}/audio.aac';

      logger.cyan(path);

      await _player.startPlayer(
        fromURI: path,
        codec: Codec.defaultCodec,
      );
      setState(() {});
    }
  }

  Future<void> _stopAudio() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      setState(() {});
    }
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    if (await Permission.microphone.isGranted) {
      await _recorder.openRecorder();
    } else {
      throw "마이크 권한이 필요합니다.";
    }
  }

  Future<void> _initializePlayer() async {
    await _player.openPlayer();
  }

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();
}
