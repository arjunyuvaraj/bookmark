import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bookmark/services/chat_service.dart';
import 'package:bookmark/services/chat_history_service.dart';
import 'package:bookmark/services/notes_service.dart';
import 'package:bookmark/models/note_model.dart';
import 'package:bookmark/models/chat_model.dart';
import 'package:bookmark/theme/color_scheme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final NotesService _notesService = NotesService();
  final List<ChatMessage> _messages = [];
  final List<ChatAttachment> _attachments = [];
  bool _isLoading = false;
  StreamSubscription<String>? _streamSubscription;

  // Chat persistence
  String? _currentChatId;
  List<ChatModel> _chatHistory = [];
  bool _isLoadingHistory = false;

  // Rate limiting and character limits
  static const int _maxInputLength = 2000;
  static const Duration _rateLimitDuration = Duration(seconds: 2);
  DateTime? _lastMessageTime;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initializeChatService();
    _messageController.addListener(_onTextChanged);
    _loadChatHistory();
  }

  Future<void> _initializeChatService() async {
    await _chatService.initialize();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null) return;
    setState(() => _isLoadingHistory = true);
    try {
      final chats = await _chatHistoryService.getUserChats(_userId!);
      setState(() {
        _chatHistory = chats;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _canSendMessage() {
    if (_lastMessageTime == null) return true;
    return DateTime.now().difference(_lastMessageTime!) >= _rateLimitDuration;
  }

  Future<void> _saveChat() async {
    if (_userId == null || _messages.isEmpty) return;

    final chatMessages = _messages.map((m) => ChatMessageModel(
      text: m.text,
      isUser: m.isUser,
      timestamp: m.timestamp,
      attachments: m.attachments.map((a) => ChatAttachmentModel(
        type: a.type == AttachmentType.note ? 'note' : 'file',
        name: a.name,
        content: a.content,
      )).toList(),
    )).toList();

    final title = _chatHistoryService.generateTitle(_messages.first.text);
    final now = DateTime.now();

    if (_currentChatId != null) {
      // Update existing chat
      final chat = ChatModel(
        id: _currentChatId,
        title: title,
        createdAt: _chatHistory.firstWhere((c) => c.id == _currentChatId).createdAt,
        updatedAt: now,
        messages: chatMessages,
      );
      await _chatHistoryService.updateChat(_userId!, _currentChatId!, chat);
    } else {
      // Create new chat
      final chat = ChatModel(
        title: title,
        createdAt: now,
        updatedAt: now,
        messages: chatMessages,
      );
      final chatId = await _chatHistoryService.createChat(_userId!, chat);
      if (chatId != null) {
        setState(() => _currentChatId = chatId);
      }
    }

    // Refresh chat history
    _loadChatHistory();
  }

  Future<void> _loadChat(ChatModel chat) async {
    setState(() {
      _currentChatId = chat.id;
      _messages.clear();
      _messages.addAll(chat.messages.map((m) => ChatMessage(
        text: m.text,
        isUser: m.isUser,
        timestamp: m.timestamp,
        attachments: m.attachments.map((a) => ChatAttachment(
          type: (a.type == 'note' || a.type == 'studySet') ? AttachmentType.note : AttachmentType.file,
          name: a.name,
          content: a.content,
        )).toList(),
      )));
    });

    // Reset chat service and replay conversation for context
    _chatService.resetChat();
    for (final message in _messages) {
      if (message.isUser) {
        // Replay user messages to rebuild context (without streaming)
        await _chatService.sendMessage(message.text);
      }
    }

    _scrollToBottom();
  }

  Future<void> _deleteChat(String chatId) async {
    if (_userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatHistoryService.deleteChat(_userId!, chatId);
      if (_currentChatId == chatId) {
        _startNewChat();
      }
      _loadChatHistory();
    }
  }

  Future<void> _sendMessage([String? prefillText]) async {
    final text = prefillText ?? _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Check rate limiting
    if (!_canSendMessage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please wait a moment before sending another message'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey[800],
        ),
      );
      return;
    }

    // Check character limit
    if (text.length > _maxInputLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message too long. Maximum $_maxInputLength characters allowed.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey[800],
        ),
      );
      return;
    }

    _lastMessageTime = DateTime.now();

    // Build the full message with attachments
    String fullMessage = text;
    if (_attachments.isNotEmpty) {
      final attachmentContext = _attachments.map((a) {
        if (a.type == AttachmentType.note) {
          return '\n\n[Note: ${a.name}]\n${a.content}';
        }
        return '\n\n[File: ${a.name}]';
      }).join('');
      fullMessage = '$text$attachmentContext';
    }

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        attachments: List.from(_attachments),
      ));
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      ));
      _attachments.clear();
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final stream = _chatService.sendMessageStream(fullMessage);
      _streamSubscription = stream.listen(
        (response) {
          setState(() {
            if (_messages.isNotEmpty && !_messages.last.isUser) {
              _messages[_messages.length - 1] = ChatMessage(
                text: response,
                isUser: false,
                timestamp: DateTime.now(),
                isStreaming: true,
              );
            }
          });
          _scrollToBottom();
        },
        onDone: () {
          setState(() {
            if (_messages.isNotEmpty && !_messages.last.isUser) {
              _messages[_messages.length - 1] = ChatMessage(
                text: _messages.last.text,
                isUser: false,
                timestamp: DateTime.now(),
                isStreaming: false,
              );
            }
            _isLoading = false;
          });
          // Auto-save after AI response
          _saveChat();
        },
        onError: (e) {
          setState(() {
            if (_messages.isNotEmpty && !_messages.last.isUser) {
              _messages[_messages.length - 1] = ChatMessage(
                text: "Sorry, I encountered an error. Please try again.",
                isUser: false,
                timestamp: DateTime.now(),
                isStreaming: false,
              );
            }
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages[_messages.length - 1] = ChatMessage(
            text: "Sorry, I encountered an error. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: false,
          );
        }
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewChat() {
    _streamSubscription?.cancel();
    setState(() {
      _messages.clear();
      _attachments.clear();
      _currentChatId = null;
      _chatService.resetChat();
      _isLoading = false;
    });
  }

  void _showAttachmentDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? darkSurface : lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: _AttachmentDialog(
            isDark: isDark,
            onNoteSelected: (note) {
              Navigator.pop(context);
              _addNoteAttachment(note);
            },
            notesService: _notesService,
          ),
        ),
      ),
    );
  }

  void _addNoteAttachment(NoteModel note) {
    final jsonContent = jsonEncode({
      'title': note.title,
      'subject': note.subject,
      'notes': note.notes,
    });

    setState(() {
      _attachments.add(ChatAttachment(
        type: AttachmentType.note,
        name: note.title,
        content: jsonContent,
      ));
    });
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? darkBackground : lightBackground;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      endDrawer: _userId != null ? _buildHistoryDrawer(isDark) : null,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen(isDark)
                : _buildMessageList(isDark),
          ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(bool isDark) {
    final bgColor = isDark ? darkBackground : lightBackground;
    final surfaceColor = isDark ? darkSurface : lightSurface;
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;
    final borderColor = isDark ? darkBorder : lightBorder;

    return Drawer(
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Text(
                    'Chat History',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startNewChat();
                    },
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: subtitleColor, size: 20),
                    tooltip: 'New chat',
                    style: IconButton.styleFrom(
                      backgroundColor: surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            // Chat list
            Expanded(
              child: _isLoadingHistory
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: subtitleColor,
                      ),
                    )
                  : _chatHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedBubbleChat,
                                size: 32,
                                color: subtitleColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No chats yet',
                                style: TextStyle(color: subtitleColor),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _chatHistory.length,
                          itemBuilder: (context, index) {
                            final chat = _chatHistory[index];
                            final isSelected = chat.id == _currentChatId;
                            return _ChatHistoryTile(
                              chat: chat,
                              isSelected: isSelected,
                              isDark: isDark,
                              onTap: () {
                                Navigator.pop(context);
                                _loadChat(chat);
                              },
                              onDelete: () => _deleteChat(chat.id!),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;
    final borderColor = isDark ? darkBorder : lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Mark',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI Assistant',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_messages.isNotEmpty)
            IconButton(
              onPressed: _startNewChat,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: subtitleColor,
                size: 20,
              ),
              tooltip: 'New chat',
            ),
          if (_userId != null)
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMenu01,
                color: subtitleColor,
                size: 20,
              ),
              tooltip: 'Chat history',
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(bool isDark) {
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mark icon
            SvgPicture.asset(
              'assets/mark-icon.svg',
              width: 80,
              height: 80,
              colorFilter: ColorFilter.mode(
                isDark ? darkTextSecondary : lightTextSecondary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hey, I\'m Mark',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal study assistant',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: 'Explain a concept',
                  onTap: () => _sendMessage('Explain a concept to me in detail'),
                  isDark: isDark,
                ),
                _SuggestionChip(
                  label: 'Quiz me',
                  onTap: () => _sendMessage('Quiz me on my study material'),
                  isDark: isDark,
                ),
                _SuggestionChip(
                  label: 'Study tips',
                  onTap: () => _sendMessage('Give me comprehensive study tips'),
                  isDark: isDark,
                ),
                _SuggestionChip(
                  label: 'Summarize',
                  onTap: () => _sendMessage('Help me summarize my notes'),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              if (message.isUser) {
                return _buildUserMessage(message, isDark);
              } else {
                return _buildAIMessage(message, isDark);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message, bool isDark) {
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;
    final surfaceColor = isDark ? darkSurface : lightSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: message.attachments.map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: a.type == AttachmentType.note
                            ? HugeIcons.strokeRoundedNote
                            : HugeIcons.strokeRoundedAttachment01,
                        size: 14,
                        color: subtitleColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        a.name,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIMessage(ChatMessage message, bool isDark) {
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;

    if (message.text.isEmpty && message.isStreaming) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _TypingIndicator(isDark: isDark),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _MarkdownContent(
        text: message.text,
        isDark: isDark,
        textColor: textColor,
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    final bgColor = isDark ? darkBackground : lightBackground;
    final surfaceColor = isDark ? darkSurface : lightSurface;
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final hintColor = isDark ? darkTextTertiary : lightTextTertiary;
    final iconColor = isDark ? darkTextSecondary : lightTextSecondary;
    final borderColor = isDark ? darkBorder : lightBorder;
    final hasText = _messageController.text.trim().isNotEmpty || _attachments.isNotEmpty;
    final currentLength = _messageController.text.length;
    final isOverLimit = currentLength > _maxInputLength;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: bgColor,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attachments preview
                if (_attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final attachment = entry.value;
                        return _AttachmentChip(
                          attachment: attachment,
                          onRemove: () => _removeAttachment(index),
                          isDark: isDark,
                        );
                      }).toList(),
                    ),
                  ),
                // Input container - rectangular with rounded corners
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Text input area
                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Hey, Ask anything',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: true,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          hintStyle: TextStyle(color: hintColor, fontSize: 15),
                        ),
                        style: TextStyle(color: textColor, fontSize: 15),
                        maxLines: 5,
                        minLines: 1,
                        cursorColor: textColor,
                        cursorWidth: 1,
                        mouseCursor: SystemMouseCursors.text,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                      // Bottom toolbar with controls
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Row(
                          children: [
                            // Left side - action buttons
                            IconButton(
                              onPressed: _showAttachmentDialog,
                              icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: iconColor, size: 20),
                              tooltip: 'Add attachment',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Right side - character count and send button
                            if (currentLength > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  '$currentLength / $_maxInputLength',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOverLimit
                                        ? Colors.red
                                        : (isDark ? darkTextTertiary : lightTextTertiary),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: (_isLoading || isOverLimit || !hasText) ? null : () => _sendMessage(),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: (hasText && !isOverLimit)
                                      ? (isDark ? darkTextPrimary : lightTextPrimary)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: (hasText && !isOverLimit)
                                      ? null
                                      : Border.all(color: borderColor, width: 1),
                                ),
                                child: Center(
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedArrowUp02,
                                    color: (hasText && !isOverLimit)
                                        ? (isDark ? darkBackground : lightBackground)
                                        : iconColor,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Chat history tile
class _ChatHistoryTile extends StatelessWidget {
  final ChatModel chat;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatHistoryTile({
    required this.chat,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;
    final selectedColor = isDark ? darkSurface : lightSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(chat.updatedAt),
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                size: 16,
                color: subtitleColor,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Markdown content with LaTeX support
class _MarkdownContent extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color textColor;

  const _MarkdownContent({
    required this.text,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final processedWidgets = _buildContentWidgets();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: processedWidgets,
    );
  }

  List<Widget> _buildContentWidgets() {
    final widgets = <Widget>[];
    final parts = _splitByLatex(text);

    for (final part in parts) {
      if (part.isLatex) {
        widgets.add(_buildLatexWidget(part));
      } else if (part.content.trim().isNotEmpty) {
        widgets.add(_buildMarkdownWidget(part.content));
      }
    }

    return widgets.isEmpty
        ? [SelectableText(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.6))]
        : widgets;
  }

  Widget _buildLatexWidget(_LatexPart part) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: part.isBlock ? 12 : 4),
      child: part.isBlock
          ? Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _SafeLatex(
                  latex: part.content,
                  textStyle: TextStyle(color: textColor, fontSize: 18),
                  isDark: isDark,
                ),
              ),
            )
          : _SafeLatex(
              latex: part.content,
              textStyle: TextStyle(color: textColor, fontSize: 15),
              isDark: isDark,
            ),
    );
  }

  Widget _buildMarkdownWidget(String content) {
    final borderColor = isDark ? darkBorder : lightBorder;
    final surfaceColor = isDark ? darkSurface : lightSurface;

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: textColor, fontSize: 15, height: 1.6),
        h1: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
        h2: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
        h3: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold, height: 1.4),
        h4: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold, height: 1.4),
        strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
        code: TextStyle(
          color: textColor,
          backgroundColor: surfaceColor,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(6),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquote: TextStyle(color: textColor.withAlpha(180), fontStyle: FontStyle.italic),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        listBullet: TextStyle(color: textColor),
        tableHead: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        tableBody: TextStyle(color: textColor),
        tableBorder: TableBorder.all(
          color: borderColor,
          width: 1,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  List<_LatexPart> _splitByLatex(String input) {
    final parts = <_LatexPart>[];

    // Pattern for block LaTeX: $$...$$ or \[...\]
    final blockPattern = RegExp(r'\$\$([\s\S]*?)\$\$|\\\[([\s\S]*?)\\\]');
    // Pattern for inline LaTeX: $...$ or \(...\) - but not $$
    final inlinePattern = RegExp(r'(?<!\$)\$(?!\$)([^\$\n]+?)\$(?!\$)|\\\((.*?)\\\)');

    int lastEnd = 0;

    // Process block LaTeX first
    final blockMatches = blockPattern.allMatches(input).toList();
    for (final match in blockMatches) {
      if (match.start > lastEnd) {
        // Add text before this match (will process inline later)
        parts.add(_LatexPart(input.substring(lastEnd, match.start), false, false));
      }
      final content = match.group(1) ?? match.group(2) ?? '';
      parts.add(_LatexPart(content.trim(), true, true));
      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      parts.add(_LatexPart(input.substring(lastEnd), false, false));
    }

    if (parts.isEmpty) {
      parts.add(_LatexPart(input, false, false));
    }

    // Now process inline LaTeX in non-LaTeX parts
    final finalParts = <_LatexPart>[];
    for (final part in parts) {
      if (part.isLatex) {
        finalParts.add(part);
      } else {
        finalParts.addAll(_processInlineLatex(part.content, inlinePattern));
      }
    }

    return finalParts.isEmpty ? [_LatexPart(input, false, false)] : finalParts;
  }

  List<_LatexPart> _processInlineLatex(String text, RegExp pattern) {
    final parts = <_LatexPart>[];
    int lastEnd = 0;

    final matches = pattern.allMatches(text).toList();
    for (final match in matches) {
      if (match.start > lastEnd) {
        parts.add(_LatexPart(text.substring(lastEnd, match.start), false, false));
      }
      final content = match.group(1) ?? match.group(2) ?? '';
      if (content.isNotEmpty) {
        parts.add(_LatexPart(content.trim(), true, false));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      parts.add(_LatexPart(text.substring(lastEnd), false, false));
    }

    return parts.isEmpty ? [_LatexPart(text, false, false)] : parts;
  }
}

// Safe LaTeX widget with error handling
class _SafeLatex extends StatelessWidget {
  final String latex;
  final TextStyle textStyle;
  final bool isDark;

  const _SafeLatex({
    required this.latex,
    required this.textStyle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? darkSurface : lightSurface;

    try {
      return Math.tex(
        latex,
        textStyle: textStyle,
        onErrorFallback: (error) {
          // Fallback to showing the raw LaTeX in a code-style format
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              latex,
              style: textStyle.copyWith(
                fontFamily: 'monospace',
                fontSize: (textStyle.fontSize ?? 15) - 1,
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Fallback for any other errors
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          latex,
          style: textStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: (textStyle.fontSize ?? 15) - 1,
          ),
        ),
      );
    }
  }
}

class _LatexPart {
  final String content;
  final bool isLatex;
  final bool isBlock;

  _LatexPart(this.content, this.isLatex, this.isBlock);
}

// Attachment dialog
class _AttachmentDialog extends StatelessWidget {
  final bool isDark;
  final Function(NoteModel) onNoteSelected;
  final NotesService notesService;

  const _AttachmentDialog({
    required this.isDark,
    required this.onNoteSelected,
    required this.notesService,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;
    final borderColor = isDark ? darkBorder : lightBorder;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Add to chat',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: subtitleColor, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),
          Text(
            'NOTES',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (userId == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Sign in to access your notes',
                  style: TextStyle(color: subtitleColor),
                ),
              ),
            )
          else
            Expanded(
              child: FutureBuilder<List<NoteModel>>(
                future: notesService.getUserNotes(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: subtitleColor,
                      ),
                    );
                  }

                  final notes = snapshot.data ?? [];
                  if (notes.isEmpty) {
                    return Center(
                      child: Text(
                        'No notes yet',
                        style: TextStyle(color: subtitleColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteTile(
                        note: note,
                        isDark: isDark,
                        onTap: () => onNoteSelected(note),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final NoteModel note;
  final bool isDark;
  final VoidCallback onTap;

  const _NoteTile({
    required this.note,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;
    final surfaceColor = isDark ? darkSurfaceElevated : lightSurfaceElevated;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNote,
                size: 18,
                color: subtitleColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    note.subject,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: 18,
              color: subtitleColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final ChatAttachment attachment;
  final VoidCallback onRemove;
  final bool isDark;

  const _AttachmentChip({
    required this.attachment,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;
    final surfaceColor = isDark ? darkSurface : lightSurface;
    final borderColor = isDark ? darkBorder : lightBorder;

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: attachment.type == AttachmentType.note
                ? HugeIcons.strokeRoundedNote
                : HugeIcons.strokeRoundedAttachment01,
            size: 14,
            color: subtitleColor,
          ),
          const SizedBox(width: 6),
          Text(
            attachment.name,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              size: 16,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? darkBorder : lightBorder;
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final bool isDark;

  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isDark ? darkTextSecondary : lightTextSecondary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.25;
            final value = (_controller.value + delay) % 1.0;
            final scale = 0.5 + (value < 0.5 ? value : 1 - value) * 0.5;
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor.withAlpha((scale * 255).toInt()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

enum AttachmentType { note, file }

class ChatAttachment {
  final AttachmentType type;
  final String name;
  final String? content;

  ChatAttachment({
    required this.type,
    required this.name,
    this.content,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;
  final List<ChatAttachment> attachments;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
    this.attachments = const [],
  });
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatbotScreen();
  }
}
