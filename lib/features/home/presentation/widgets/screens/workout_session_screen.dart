import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/data/workout_database.dart';
import '../../../../../core/models/coach_persona.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../components/live_coach_orb.dart';

/// Live guided workout session. The coach calls out each exercise aloud as
/// the session runs, so the user can train without looking at the screen.
class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutPlan workout;

  const WorkoutSessionScreen({super.key, required this.workout});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int _exerciseIndex = 0;
  int _secondsLeft = 0;
  bool _running = false;
  bool _completed = false;

  Exercise get _current => widget.workout.exercises[_exerciseIndex];

  @override
  void initState() {
    super.initState();
    _secondsLeft = _current.durationSec > 0 ? _current.durationSec : 0;
  }

  /// Speaks a coaching cue, unless the user has muted the coach.
  void _say(String text) {
    final state = context.read<AppState>();
    if (!state.voiceEnabled) return;
    AppServices.voice.speak(text, voice: state.coachVoice);
  }

  void _toggleTimer() {
    if (_current.durationSec <= 0) return;
    setState(() => _running = !_running);
    if (_running) {
      _say('Starting ${_current.name}.');
      _tick();
    } else {
      _say('Paused.');
    }
  }

  Future<void> _tick() async {
    while (_running && _secondsLeft > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_running) return;
      setState(() => _secondsLeft--);
      // A single spoken warning is enough; counting every second would talk
      // over the user for the whole set.
      if (_secondsLeft == 5) _say('Five seconds left.');
      if (_secondsLeft == 0) _nextExercise();
    }
  }

  void _nextExercise() {
    _running = false;
    if (_exerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _exerciseIndex++;
        _secondsLeft = _current.durationSec > 0 ? _current.durationSec : 0;
      });
      final cue = _current.durationSec > 0
          ? 'Next up, ${_current.name}, for ${_current.durationSec} seconds.'
          : 'Next up, ${_current.name}, ${_current.reps} reps.';
      context.read<AppState>().setCoachState(CoachMood.celebrating, cue);
      _say(cue);
    } else {
      setState(() => _completed = true);
      context.read<AppState>().completeWorkout(widget.workout);
      _say(
        'Session complete. Well done — that is ${widget.workout.exercises.length} '
        'exercises finished.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (_completed) return _buildComplete(state);
        final progress = (_exerciseIndex + 1) / widget.workout.exercises.length;
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: Text(widget.workout.title),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: const Color(0xFF00E676),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exercise ${_exerciseIndex + 1} of ${widget.workout.exercises.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                const LiveCoachOrb(size: 132, openOnTap: false),
                const SizedBox(height: 24),
                Text(
                  _current.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _current.muscleGroup,
                  style: const TextStyle(color: Color(0xFF00E676), fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (_current.durationSec > 0)
                  Text(
                    '${_secondsLeft}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Text(
                    '${_current.reps} reps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _current.instructions,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (_current.durationSec > 0)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleTimer,
                          icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                          label: Text(_running ? 'Pause' : 'Start Timer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    if (_current.durationSec > 0) const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _nextExercise,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00E676),
                          side: const BorderSide(color: Color(0xFF00E676)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComplete(AppState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LiveCoachOrb(size: 150, openOnTap: false),
              const SizedBox(height: 24),
              const Text(
                'Workout Complete!',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                'You burned ~${widget.workout.totalCalories} kcal in ${widget.workout.totalMinutes} min',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
