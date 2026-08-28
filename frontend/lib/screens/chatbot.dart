import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../styles/app_theme.dart';
import 'chathistory.dart';

class ChatbotScreen extends StatefulWidget {
  final String? initialQuery;

  const ChatbotScreen({super.key, this.initialQuery});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _currentSessionId;
  String _currentSessionTitle = 'AI 챗봇 비서';
  
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startNewChat();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessageWithText(widget.initialQuery!.trim());
      });
    }
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _currentSessionTitle = 'AI 챗봇 비서';
      _messages = [
        {
          'role': 'assistant',
          'content': '안녕하세요! 스크린샷에서 분석된 일정, 장소, 링크 등에 대해 물어보세요.',
          'time': _getCurrentTime(),
        }
      ];
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return _getCurrentTime();
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return _getCurrentTime();
    }
  }

  Future<void> _loadSessionMessages(String sessionId, String title) async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/chat/sessions/$sessionId'));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> raw = data['messages'] ?? [];
        setState(() {
          _currentSessionId = sessionId;
          _currentSessionTitle = title;
          _messages = raw.map<Map<String, String>>((m) => {
            'role': m['sender'] == 'user' ? 'user' : 'assistant',
            'content': m['message'] ?? '',
            'time': _formatTime(m['created_at']),
          }).toList();
        });
        _scrollToBottom();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;
    _textController.clear();
    await _sendMessageWithText(text);
  }

  Future<void> _sendMessageWithText(String text) async {
    final curTime = _getCurrentTime();
    setState(() {
      _messages.add({'role': 'user', 'content': text, 'time': curTime});
      _isLoading = true;
    });
    _scrollToBottom();

    final historyPayload = _messages
        .where((m) => m != _messages.last)
        .take(6)
        .map((m) => {'role': m['role']!, 'content': m['content']!})
        .toList();

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'session_id': _currentSessionId,
          'user_id': 'default_user',
          'history': historyPayload,
          'limit': 12,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final reply = data['reply'] ?? '응답을 가져오지 못했습니다.';
        final newSessionId = data['session_id'];
        final newTitle = data['session_title'] ?? _currentSessionTitle;

        if (mounted) {
          setState(() {
            _currentSessionId = newSessionId;
            _currentSessionTitle = newTitle;
            _messages.add({
              'role': 'assistant',
              'content': reply,
              'time': _getCurrentTime(),
            });
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': '서버 통신 오류가 발생했습니다. (${res.statusCode})',
              'time': _getCurrentTime(),
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '네트워크 오류가 발생했습니다: $e',
            'time': _getCurrentTime(),
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSofter,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          _currentSessionTitle,
          style: AppTypography.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.textPrimary),
            tooltip: '새 대화',
            onPressed: _startNewChat,
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textPrimary),
            tooltip: '대화 기록',
            onPressed: () async {
              final selectedSession = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
              if (selectedSession != null && selectedSession['id'] != null) {
                _loadSessionMessages(selectedSession['id'].toString(), selectedSession['title'] ?? '대화');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final timeText = msg['time'] ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isUser && timeText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 2),
                          child: Text(
                            timeText,
                            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.brand : AppColors.cardBg,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppRadius.lg),
                            topRight: const Radius.circular(AppRadius.lg),
                            bottomLeft: Radius.circular(isUser ? AppRadius.lg : 2),
                            bottomRight: Radius.circular(isUser ? 2 : AppRadius.lg),
                          ),
                          border: isUser ? null : Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: Text(
                          msg['content'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.45,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                      ),
                      if (!isUser && timeText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6, bottom: 2),
                          child: Text(
                            timeText,
                            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: AppColors.brand, strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'SALMON-CHATBOT이 답변을 작성 중입니다...',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ), 
            ), 
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgSoft,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: '저장된 정보에 대해 물어보세요...',
                          hintStyle: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
