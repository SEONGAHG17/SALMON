import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

class EditDialogs {
  // 1. 분석 기록 수정 다이얼로그
  static Future<void> showHistoryEditDialog({
    required BuildContext context,
    required Map<String, dynamic> item,
    required List<String> categories,
    required VoidCallback onUpdated,
  }) async {
    final summaryController = TextEditingController(text: item['summary'] ?? '');
    String selectedCategory = categories.contains(item['category'])
        ? item['category']
        : (categories.isNotEmpty ? categories.first : '기타');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("분석 기록 수정"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: summaryController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "요약 내용",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCategory = val);
                },
                decoration: const InputDecoration(
                  labelText: "카테고리",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                final response = await http.patch(
                  Uri.parse('$baseUrl/api/v1/history/${item['id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'summary': summaryController.text.trim(),
                    'category': selectedCategory,
                  }),
                );
                if (response.statusCode == 200 && ctx.mounted) {
                  Navigator.pop(ctx);
                  onUpdated();
                }
              },
              child: const Text("저장"),
            ),
          ],
        ),
      ),
    );
  }

  // 2. 단일 항목 삭제 확인 다이얼로그
  static Future<void> showDeleteConfirmDialog({
    required BuildContext context,
    required int itemId,
    required VoidCallback onDeleted,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("데이터 삭제"),
        content: const Text("이 분석 결과 및 연결된 캘린더 일정이 모두 삭제됩니다. 계속하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final response = await http.delete(Uri.parse('$baseUrl/api/v1/history/$itemId'));
              if (response.statusCode == 200 && ctx.mounted) {
                Navigator.pop(ctx);
                onDeleted();
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 3. 캘린더 일정 수정/추가 다이얼로그 (시작일, 종료일 지원)
  static Future<void> showCalendarEditDialog({
    required BuildContext context,
    Map<String, dynamic>? event,
    DateTime? initialDate,
    required VoidCallback onSaved,
  }) async {
    final isEditing = event != null;
    final titleController = TextEditingController(text: isEditing ? event['title'] : '');
    
    String startDateStr = isEditing
        ? event['event_date'].toString().substring(0, 10)
        : (initialDate != null
            ? "${initialDate.year}-${initialDate.month.toString().padLeft(2, '0')}-${initialDate.day.toString().padLeft(2, '0')}"
            : DateTime.now().toString().substring(0, 10));

    String endDateStr = isEditing
        ? (event['end_date'] ?? event['event_date']).toString().substring(0, 10)
        : startDateStr;

    final startController = TextEditingController(text: startDateStr);
    final endController = TextEditingController(text: endDateStr);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "일정 수정" : "새 일정 등록"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "일정 제목", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: startController,
              decoration: const InputDecoration(labelText: "시작일 (YYYY-MM-DD)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endController,
              decoration: const InputDecoration(labelText: "종료일 (YYYY-MM-DD)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          if (isEditing)
            TextButton(
              onPressed: () async {
                final res = await http.delete(Uri.parse('$baseUrl/api/v1/calendar/${event['id']}'));
                if (res.statusCode == 200 && ctx.mounted) {
                  Navigator.pop(ctx);
                  onSaved();
                }
              },
              child: const Text("삭제", style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              http.Response res;
              final payload = {
                'title': titleController.text.trim(),
                'event_date': startController.text.trim(),
                'end_date': endController.text.trim(),
              };

              if (isEditing) {
                res = await http.patch(
                  Uri.parse('$baseUrl/api/v1/calendar/${event['id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                );
              } else {
                res = await http.post(
                  Uri.parse('$baseUrl/api/v1/calendar/'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                );
              }
              if (res.statusCode == 200 && ctx.mounted) {
                Navigator.pop(ctx);
                onSaved();
              }
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }
}

