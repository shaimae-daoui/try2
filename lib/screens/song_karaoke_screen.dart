import 'package:flutter/material.dart';
import 'dart:async';

class SongKaraokeScreen extends StatefulWidget {
  final Map<String, dynamic> song;

  SongKaraokeScreen({required this.song});

  @override
  _SongKaraokeScreenState createState() => _SongKaraokeScreenState();
}

class _SongKaraokeScreenState extends State<SongKaraokeScreen> {
  int _currentLineIndex = 0;
  List<String> _lyricsLines = [];
  Timer? _timer;
  int _secondsPerLine = 3;

  @override
  void initState() {
    super.initState();
    _lyricsLines = (widget.song['lyrics'] as String).split('|');
    _startKaraoke();
  }

  void _startKaraoke() {
    _timer = Timer.periodic(Duration(seconds: _secondsPerLine), (timer) {
      if (_currentLineIndex < _lyricsLines.length - 1) {
        setState(() {
          _currentLineIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple[900]!,
              Colors.purple[700]!,
              Colors.pink[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.song['title'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '🎵 Karaoké synchronisé',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              Spacer(),

              // Paroles avec effet karaoké
              Container(
                height: 400,
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _lyricsLines.length,
                  itemBuilder: (context, index) {
                    final isCurrentLine = index == _currentLineIndex;
                    final isPastLine = index < _currentLineIndex;
                    final isFutureLine = index > _currentLineIndex;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 500),
                          style: TextStyle(
                            fontSize: isCurrentLine ? 36 : 24,
                            fontWeight: isCurrentLine
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrentLine
                                ? Colors.yellow
                                : isPastLine
                                ? Colors.white60
                                : Colors.white30,
                            shadows: isCurrentLine
                                ? [
                              Shadow(
                                blurRadius: 20,
                                color: Colors.yellow,
                              ),
                            ]
                                : [],
                          ),
                          child: Text(
                            _lyricsLines[index],
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Spacer(),

              // Indicateur de progression
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (_currentLineIndex + 1) / _lyricsLines.length,
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_currentLineIndex + 1} / ${_lyricsLines.length}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}