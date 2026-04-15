import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/data/services/mock_ai_evaluator.dart';
import 'package:talk_gym/data/services/mock_training_api.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_bloc.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_event.dart';
import 'package:talk_gym/feature/behavioral_training/bloc/training_state.dart';
import 'package:talk_gym/feature/behavioral_training/models/highlight_info.dart';
import 'package:talk_gym/feature/behavioral_training/screens/final_interview_simulation.dart';
import 'package:talk_gym/feature/behavioral_training/widgets/ai_call_counter.dart';
import 'package:talk_gym/feature/behavioral_training/widgets/evaluation_card.dart';
import 'package:talk_gym/feature/behavioral_training/widgets/highlighted_text_editor.dart';
import 'package:talk_gym/feature/behavioral_training/widgets/improvement_popup.dart';

class TrainingEditorScreen extends StatelessWidget {
  const TrainingEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrainingBloc>(
      create: (_) => TrainingBloc(
        trainingApi: MockTrainingApi(),
        aiEvaluator: MockAiEvaluator(),
      )..add(const LoadQuestionsEvent()),
      child: const _TrainingEditorView(),
    );
  }
}

class _TrainingEditorView extends StatefulWidget {
  const _TrainingEditorView();

  @override
  State<_TrainingEditorView> createState() => _TrainingEditorViewState();
}

class _TrainingEditorViewState extends State<_TrainingEditorView> {
  late final HighlightingTextEditingController _answerController;
  int _lastPopupRequestId = 0;
  int _lastFinalInterviewRequestId = 0;

  @override
  void initState() {
    super.initState();
    _answerController = HighlightingTextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _showEvaluationWarning({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) async {
    final bool? allowed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Use AI evaluation?'),
          content: const Text('This will use 1 of your 2 AI evaluations. Continue?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF222222),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (allowed == true) {
      onConfirm();
    }
  }

  Future<void> _openImprovementPopup(BuildContext context, HighlightInfo info) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ImprovementPopupDialog(
            highlight: info,
            onApply: (String updatedSentence) {
              HapticFeedback.lightImpact();
              context.read<TrainingBloc>().add(
                    ApplySuggestionEvent(info.sentence, updatedSentence),
                  );
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Behavioral Training')),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<TrainingBloc, TrainingState>(
          listener: (BuildContext context, TrainingState state) {
            _answerController.setHighlights(state.highlightedSentences.values);

            if (_answerController.text != state.currentAnswer) {
              _answerController.value = _answerController.value.copyWith(
                text: state.currentAnswer,
                selection: TextSelection.collapsed(offset: state.currentAnswer.length),
                composing: TextRange.empty,
              );
            }

            if (state.popupHighlight != null && state.popupRequestId != _lastPopupRequestId) {
              _lastPopupRequestId = state.popupRequestId;
              final TrainingBloc bloc = context.read<TrainingBloc>();
              _openImprovementPopup(context, state.popupHighlight!).then((_) {
                if (!mounted) {
                  return;
                }
                bloc.add(const DismissImprovementPopupEvent());
              });
            }

            if (state.systemMessage != null && state.systemMessage!.isNotEmpty) {
              if (state.status == FormzStatus.submissionSuccess) {
                HapticFeedback.mediumImpact();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.systemMessage!)),
              );
              context.read<TrainingBloc>().add(const ClearSystemMessageEvent());
            }

            if (state.finalInterviewRequestId != _lastFinalInterviewRequestId) {
              _lastFinalInterviewRequestId = state.finalInterviewRequestId;
              final String questionText =
                  state.selectedQuestion?.text ?? 'Behavioral interview question';
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FinalInterviewSimulationScreen(
                    questionText: questionText,
                    preparedAnswer: state.currentAnswer,
                  ),
                ),
              );
            }
          },
          builder: (BuildContext context, TrainingState state) {
            final TrainingBloc bloc = context.read<TrainingBloc>();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: AiCallCounter(remaining: state.aiCallsRemaining),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select Behavioral Question',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: state.selectedQuestion?.id,
                    decoration: const InputDecoration(
                      fillColor: Color(0xFFF8F9FA),
                    ),
                    items: state.questions
                        .map(
                          (q) => DropdownMenuItem<String>(
                            value: q.id,
                            child: Text(q.text),
                          ),
                        )
                        .toList(),
                    onChanged: (String? id) {
                      if (id != null) {
                        bloc.add(SelectQuestionEvent(id));
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    state.selectedQuestion == null
                        ? 'Example Answer to Practice With'
                        : 'Your Original Answer (from your profile)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.originalContent.isEmpty
                          ? 'Loading original content...'
                          : state.originalContent,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your Improved Answer (edit directly here)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  HighlightedTextEditor(
                    controller: _answerController,
                    onChanged: (String value) => bloc.add(UpdateAnswerEvent(value)),
                    onHighlightTap: (HighlightInfo info) {
                      bloc.add(ShowImprovementPopupEvent(info.sentence, info.suggestion));
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Problematic sentences appear in red text with a light red background.',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: state.isAnalyzing
                            ? null
                            : () => bloc.add(const HighlightSentencesEvent()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF222222),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 48),
                        ),
                        child: Text(state.isAnalyzing ? 'Analyzing...' : 'Analyze & Highlight'),
                      ),
                      Tooltip(
                        message: state.aiCallsRemaining == 0
                            ? 'No AI calls remaining. Practice with manual edits or start a new question.'
                            : 'Run AI evaluation',
                        child: OutlinedButton(
                          onPressed: (!state.canEvaluate || state.currentAnswer.trim().isEmpty)
                              ? null
                              : () {
                                  _showEvaluationWarning(
                                    context: context,
                                    onConfirm: () {
                                      bloc.add(const RequestEvaluationEvent());
                                    },
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(140, 48),
                          ),
                          child: Text(state.isEvaluating ? 'Evaluating...' : 'Get AI Evaluation'),
                        ),
                      ),
                      if (state.evaluationResult != null && state.aiCallsRemaining == 1)
                        OutlinedButton(
                          onPressed: state.isEvaluating
                              ? null
                              : () {
                                  _showEvaluationWarning(
                                    context: context,
                                    onConfirm: () {
                                      bloc.add(const RequestSecondEvaluationEvent());
                                    },
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(170, 48),
                          ),
                          child: const Text('Request Final Polish (2nd Call)'),
                        ),
                      OutlinedButton(
                        onPressed: state.canTakeFinalInterview
                            ? () => bloc.add(const StartFinalInterviewEvent())
                            : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(160, 48),
                        ),
                        child: const Text('Take Final Interview'),
                      ),
                    ],
                  ),
                  if (state.evaluationResult != null) ...<Widget>[
                    const SizedBox(height: 16),
                    EvaluationCard(
                      result: state.evaluationResult!,
                      aiCallsRemaining: state.aiCallsRemaining,
                      onApplySuggestions: () {
                        bloc.add(const ApplyImprovedVersionEvent());
                      },
                      onEditManually: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Continue editing your answer below.')),
                        );
                      },
                      onRequestFinalPolish: () {
                        if (state.aiCallsRemaining > 0) {
                          _showEvaluationWarning(
                            context: context,
                            onConfirm: () => bloc.add(const RequestSecondEvaluationEvent()),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
