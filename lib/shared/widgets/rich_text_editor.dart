import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Rich text segment
class RichTextSegment {
  final String text;
  final bool bold;
  final bool italic;
  final bool strikethrough;

  RichTextSegment({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.strikethrough = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'bold': bold,
    'italic': italic,
    'strikethrough': strikethrough,
  };

  factory RichTextSegment.fromJson(Map<String, dynamic> json) => RichTextSegment(
    text: json['text'] ?? '',
    bold: json['bold'] == true,
    italic: json['italic'] == true,
    strikethrough: json['strikethrough'] == true,
  );
}

/// Rich text editor toolbar and parser
class RichTextEditor {
  /// Parse rich text JSON string into segments
  static List<RichTextSegment> parseRichText(String? richTextJson) {
    if (richTextJson == null || richTextJson.isEmpty) return [];
    try {
      final list = jsonDecode(richTextJson) as List;
      return list.map((e) => RichTextSegment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Convert segments to JSON string
  static String toJsonString(List<RichTextSegment> segments) {
    return jsonEncode(segments.map((s) => s.toJson()).toList());
  }

  /// Build rich text spans from segments
  static List<TextSpan> buildTextSpans(List<RichTextSegment> segments, {Color color = Colors.white, double fontSize = 15}) {
    if (segments.isEmpty) return [];
    return segments.map((seg) {
      return TextSpan(
        text: seg.text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: seg.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: seg.italic ? FontStyle.italic : FontStyle.normal,
          decoration: seg.strikethrough ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      );
    }).toList();
  }

  /// Apply formatting to selected text in a controller
  static String applyFormat(TextEditingController controller, String format) {
    final text = controller.text;
    final selection = controller.selection;
    
    if (selection.isCollapsed) return text; // No selection
    
    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    
    String formatted;
    switch (format) {
      case 'bold':
        formatted = '*$selectedText*';
        break;
      case 'italic':
        formatted = '_${selectedText}_';
        break;
      case 'strikethrough':
        formatted = '~$selectedText~';
        break;
      default:
        formatted = selectedText;
    }
    
    final newText = text.replaceRange(start, end, formatted);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: start + formatted.length);
    return newText;
  }

  /// Parse markdown-like formatting into rich text segments
  static List<RichTextSegment> parseMarkdownToSegments(String text) {
    final segments = <RichTextSegment>[];
    final boldRegex = RegExp(r'\*([^*]+)\*');
    final italicRegex = RegExp(r'_([^_]+)_');
    final strikeRegex = RegExp(r'~([^~]+)~');
    
    int pos = 0;
    final combinedRegex = RegExp(r'(\*[^*]+\*)|(_[^_]+_)|(~[^~]+~)');
    
    for (final match in combinedRegex.allMatches(text)) {
      if (match.start > pos) {
        segments.add(RichTextSegment(text: text.substring(pos, match.start)));
      }
      
      final matchedText = match.group(0)!;
      if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        segments.add(RichTextSegment(text: matchedText.substring(1, matchedText.length - 1), bold: true));
      } else if (matchedText.startsWith('_') && matchedText.endsWith('_')) {
        segments.add(RichTextSegment(text: matchedText.substring(1, matchedText.length - 1), italic: true));
      } else if (matchedText.startsWith('~') && matchedText.endsWith('~')) {
        segments.add(RichTextSegment(text: matchedText.substring(1, matchedText.length - 1), strikethrough: true));
      }
      
      pos = match.end;
    }
    
    if (pos < text.length) {
      segments.add(RichTextSegment(text: text.substring(pos)));
    }
    
    return segments.isEmpty ? [RichTextSegment(text: text)] : segments;
  }

  /// Check if text has any rich text formatting
  static bool hasFormatting(String text) {
    return RegExp(r'(\*[^*]+\*)|(_[^_]+_)|(~[^~]+~)').hasMatch(text);
  }
}

/// Rich text formatting toolbar widget
class RichTextToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFormatApplied;

  const RichTextToolbar({
    super.key,
    required this.controller,
    required this.onFormatApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatButton('B', FontWeight.bold, 'bold'),
          _formatButton('I', FontStyle.italic, 'italic'),
          _formatButton('S', TextDecoration.lineThrough, 'strikethrough'),
        ],
      ),
    );
  }

  Widget _formatButton(String label, dynamic style, String format) {
    return GestureDetector(
      onTap: () {
        RichTextEditor.applyFormat(controller, format);
        onFormatApplied();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: style is FontWeight ? style : FontWeight.normal,
            fontStyle: style is FontStyle ? style : FontStyle.normal,
            decoration: style is TextDecoration ? style : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
