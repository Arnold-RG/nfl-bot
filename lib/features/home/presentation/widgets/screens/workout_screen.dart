import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/data/workout_database.dart';
import '../../../../../core/models/coach_persona.dart';
import '../../../../../core/providers/app_state.dart';
import '../components/live_coach_orb.dart';
import 'workout_session_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String _focus = 'Full Body';
  String _level = 'Medium';
  int _minutes = 25;

  void _generate() {
    context.read<AppState>().generateWorkout(
      focus: _focus,
      minutes: _minutes,
      level: _level,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final workout = state.currentWorkout;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home Workout',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Zero equipment · AI-generated daily plans',
                          style: TextStyle(color: Color(0xFF5F6F72)),
                        ),
                      ],
                    ),
                  ),
                  const LiveCoachOrb(size: 56),
                ],
              ),
              const SizedBox(height: 20),
              _GeneratorCard(
                focus: _focus,
                level: _level,
                minutes: _minutes,
                onFocusChanged: (v) => setState(() => _focus = v),
                onLevelChanged: (v) => setState(() => _level = v),
                onMinutesChanged: (v) => setState(() => _minutes = v),
                onGenerate: _generate,
              ),
              if (workout != null) ...[
                const SizedBox(height: 20),
                _WorkoutPlanCard(workout: workout),
              ],
              const SizedBox(height: 20),
              const Text(
                'Popular routines',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _PresetCard(
                title: 'Morning Energizer',
                subtitle: '15 min · Easy · Full body wake-up',
                icon: Icons.wb_sunny_rounded,
                onTap: () {
                  setState(() {
                    _focus = 'Full Body';
                    _level = 'Easy';
                    _minutes = 15;
                  });
                  _generate();
                },
              ),
              _PresetCard(
                title: 'Core Crusher',
                subtitle: '20 min · Medium · Abs & obliques',
                icon: Icons.fitness_center_rounded,
                onTap: () {
                  setState(() {
                    _focus = 'Core';
                    _level = 'Medium';
                    _minutes = 20;
                  });
                  _generate();
                },
              ),
              _PresetCard(
                title: 'Cardio Burn',
                subtitle: '30 min · Hard · Fat burning HIIT',
                icon: Icons.local_fire_department_rounded,
                onTap: () {
                  setState(() {
                    _focus = 'Cardio';
                    _level = 'Hard';
                    _minutes = 30;
                  });
                  _generate();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GeneratorCard extends StatelessWidget {
  final String focus;
  final String level;
  final int minutes;
  final ValueChanged<String> onFocusChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onGenerate;

  const _GeneratorCard({
    required this.focus,
    required this.level,
    required this.minutes,
    required this.onFocusChanged,
    required this.onLevelChanged,
    required this.onMinutesChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 20),
              SizedBox(width: 8),
              Text(
                'AI Workout Generator',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Focus area', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: WorkoutDatabase.focusOptions
                .map(
                  (f) => ChoiceChip(
                    label: Text(f, style: const TextStyle(fontSize: 12)),
                    selected: focus == f,
                    selectedColor: const Color(0xFF00C853),
                    labelStyle: TextStyle(
                      color: focus == f ? Colors.white : Colors.white70,
                    ),
                    onSelected: (_) => onFocusChanged(f),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text('Difficulty', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: WorkoutDatabase.levelOptions
                .map(
                  (l) => ChoiceChip(
                    label: Text(l, style: const TextStyle(fontSize: 12)),
                    selected: level == l,
                    selectedColor: const Color(0xFF00C853),
                    labelStyle: TextStyle(
                      color: level == l ? Colors.white : Colors.white70,
                    ),
                    onSelected: (_) => onLevelChanged(l),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Duration', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Expanded(
                child: Slider(
                  value: minutes.toDouble(),
                  min: 10,
                  max: 45,
                  divisions: 7,
                  activeColor: const Color(0xFF00E676),
                  label: '$minutes min',
                  onChanged: (v) => onMinutesChanged(v.round()),
                ),
              ),
              Text('$minutes min', style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.bolt_rounded),
              label: const Text("Generate Today's Workout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPlanCard extends StatelessWidget {
  final WorkoutPlan workout;

  const _WorkoutPlanCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workout.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${workout.totalMinutes} min',
                  style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            workout.description,
            style: const TextStyle(color: Color(0xFF5F6F72), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatBadge(icon: Icons.local_fire_department, label: '${workout.totalCalories} kcal'),
              const SizedBox(width: 12),
              _StatBadge(icon: Icons.fitness_center, label: '${workout.exercises.length} exercises'),
            ],
          ),
          const Divider(height: 24),
          ...workout.exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final ex = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1A1A2E),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Color(0xFF00E676), fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          ex.durationSec > 0
                              ? '${ex.durationSec}s hold · ${ex.muscleGroup}'
                              : '${ex.reps} reps · ${ex.muscleGroup}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5F6F72),
                          ),
                        ),
                        Text(
                          ex.instructions,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _difficultyColor(ex.difficulty).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ex.difficulty,
                      style: TextStyle(
                        fontSize: 10,
                        color: _difficultyColor(ex.difficulty),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AppState>().setCoachState(
                  CoachMood.celebrating,
                  'Session started. Let us get to work.',
                );
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkoutSessionScreen(workout: workout),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Workout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00C853),
                side: const BorderSide(color: Color(0xFF00C853)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Easy':
        return Colors.green;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00C853)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PresetCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF00C853)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
