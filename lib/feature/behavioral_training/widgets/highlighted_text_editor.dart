import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talk_gym/core/appcolor.dart';
import 'package:talk_gym/feature/behavioral_training/models/highlight_info.dart';

typedef HighlightTapCallback = void Function(HighlightInfo info);

class HighlightingTextEditingController extends TextEditingController {
  HighlightingTextEditingController({String? text}) : super(text: text);

  List<HighlightInfo> _highlights = <HighlightInfo>[];

  void setHighlights(Iterable<HighlightInfo> highlights) {
    _highlights = highlights.toList()..sort((HighlightInfo a, HighlightInfo b) => a.startIndex.compareTo(b.startIndex));
    notifyListeners();
  }

  HighlightInfo? findHighlightByOffset(int offset) {
    for (final HighlightInfo info in _highlights) {
      if (offset >= info.startIndex && offset <= info.endIndex) {
        return info;
      }
    }
    return null;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_highlights.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;

    for (final HighlightInfo info in _highlights) {
      final int start = info.startIndex.clamp(0, text.length);
      final int end = info.endIndex.clamp(0, text.length);
      if (start < cursor || start >= end) {
        continue;
      }

      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start), style: style));
      }

      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: (style ?? const TextStyle()).copyWith(
            color: const Color(0xFFE53935),
            backgroundColor: const Color(0xFFFFEBEE),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      cursor = end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return TextSpan(style: style, children: spans);
  }
}

class HighlightedTextEditor extends StatelessWidget {
  const HighlightedTextEditor({
    required this.controller,
    required this.onChanged,
    required this.onHighlightTap,
    super.key,
  });

  final HighlightingTextEditingController controller;
  final ValueChanged<String> onChanged;
  final HighlightTapCallback onHighlightTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Red text indicates sentence that can be improved. Double tap for coaching tips.',
      child: Container(
        constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: TextField(
          controller: controller,
          maxLines: null,
          minLines: 10,
          onChanged: onChanged,
          onTap: () {
            final int offset = controller.selection.baseOffset;
            if (offset < 0) {
              return;
            }
            final HighlightInfo? selected = controller.findHighlightByOffset(offset);
            if (selected != null) {
              HapticFeedback.selectionClick();
              onHighlightTap(selected);
            }
          },
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            hintText: 'Edit your answer here',
            filled: false,
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
