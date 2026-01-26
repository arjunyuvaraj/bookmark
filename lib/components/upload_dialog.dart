import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/models/flashcard_model.dart';

const double _cardRadius = 8.0;

// Limits
const int maxFiles = 5;
const int maxLinks = 3;
const int maxTextLength = 10000;

class UploadDialog extends StatefulWidget {
  final bool startInCustomMode;

  const UploadDialog({super.key, this.startInCustomMode = false});

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  final PromptService _promptService = PromptService();
  final FlashcardSetService _flashcardService = FlashcardSetService();
  final TextEditingController _textController = TextEditingController();

  bool _isCustomMode = false;
  bool _isLoading = false;
  String? _error;
  bool _isSaved = false;
  int _cardCount = 0;
  String _setTitle = '';

  // Combined content
  final List<_UploadedFile> _uploadedFiles = [];
  final List<String> _links = [];
  final TextEditingController _linkInputController = TextEditingController();

  // Custom mode
  final TextEditingController _customTitleController = TextEditingController();
  final List<_CustomCard> _customCards = [_CustomCard()];

  @override
  void initState() {
    super.initState();
    _isCustomMode = widget.startInCustomMode;
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkInputController.dispose();
    _customTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    if (_uploadedFiles.length >= maxFiles) {
      setState(() => _error = 'Maximum $maxFiles files allowed');
      return;
    }

    try {
      final result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp', 'txt'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _error = null;
          for (final file in result.files) {
            if (_uploadedFiles.length >= maxFiles) break;
            if (file.bytes != null) {
              _uploadedFiles.add(
                _UploadedFile(
                  bytes: file.bytes!,
                  name: file.name,
                  mimeType: FileInput.getMimeType(file.name),
                ),
              );
            }
          }
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick files: $e');
    }
  }

  void _addLink() {
    final link = _linkInputController.text.trim();
    if (link.isEmpty) return;

    if (_links.length >= maxLinks) {
      setState(() => _error = 'Maximum $maxLinks links allowed');
      return;
    }

    if (!Uri.tryParse(link)!.hasScheme) {
      setState(() => _error = 'Please enter a valid URL');
      return;
    }

    setState(() {
      _error = null;
      _links.add(link);
      _linkInputController.clear();
    });
  }

  void _removeLink(int index) {
    setState(() => _links.removeAt(index));
  }

  void _removeFile(int index) {
    setState(() => _uploadedFiles.removeAt(index));
  }

  Future<void> _processContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String result;

      // Combine all content
      List<String> allContent = [];

      // Process files
      if (_uploadedFiles.isNotEmpty) {
        if (_uploadedFiles.length == 1) {
          final file = _uploadedFiles.first;
          if (file.mimeType == 'application/pdf') {
            result = await _promptService.generateFromPdf(file.bytes);
            allContent.add(result);
          } else if (file.mimeType.startsWith('image/')) {
            result = await _promptService.generateFromImage(file.bytes, file.mimeType);
            allContent.add(result);
          } else if (file.mimeType == 'text/plain') {
            final text = String.fromCharCodes(file.bytes);
            allContent.add('File content: $text');
          }
        } else {
          final fileInputs = _uploadedFiles
              .map((f) => FileInput(bytes: f.bytes, mimeType: f.mimeType, fileName: f.name))
              .toList();
          result = await _promptService.generateFromMultipleFiles(fileInputs);
          allContent.add(result);
        }
      }

      // Process links
      for (final link in _links) {
        if (_promptService.isYouTubeUrl(link)) {
          result = await _promptService.generateFromYouTube(link);
        } else {
          result = await _promptService.generateFromUrl(link);
        }
        allContent.add(result);
      }

      // Process text
      if (_textController.text.trim().isNotEmpty) {
        result = await _promptService.generateFromText(_textController.text.trim());
        allContent.add(result);
      }

      if (allContent.isEmpty) {
        throw Exception('Please add at least one file, link, or text content.');
      }

      // Use the first valid result (most content already generates complete JSON)
      final cleanResult = _cleanJsonResponse(allContent.first);
      final setData = await _saveToFirebase(cleanResult);

      setState(() {
        _isLoading = false;
        _isSaved = true;
        _cardCount = setData['cardCount'] as int;
        _setTitle = setData['title'] as String;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCustomSet() async {
    if (_customTitleController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a title');
      return;
    }

    final validCards = _customCards.where((c) =>
      c.frontController.text.trim().isNotEmpty &&
      c.backController.text.trim().isNotEmpty
    ).toList();

    if (validCards.isEmpty) {
      setState(() => _error = 'Please add at least one complete flashcard');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final cards = validCards.map((c) => Flashcard(
        question: c.frontController.text.trim(),
        answer: c.backController.text.trim(),
      )).toList();

      final set = SetModel(
        title: _customTitleController.text.trim(),
        description: 'Custom flashcard set',
        fileType: FileType.none,
        cards: cards,
      );

      await _flashcardService.createSet(user.uid, set);

      setState(() {
        _isLoading = false;
        _isSaved = true;
        _cardCount = cards.length;
        _setTitle = _customTitleController.text.trim();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  Future<Map<String, dynamic>> _saveToFirebase(String jsonResult) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final jsonData = jsonDecode(jsonResult) as Map<String, dynamic>;

    final cards = (jsonData['cards'] as List?)
            ?.map((card) => Flashcard.fromJson(card as Map<String, dynamic>))
            .toList() ?? [];

    FileType fileType = FileType.none;
    final fileTypeStr = jsonData['fileType'] as String?;
    if (fileTypeStr != null) {
      try {
        fileType = FileType.values.firstWhere(
          (e) => e.name == fileTypeStr,
          orElse: () => FileType.none,
        );
      } catch (_) {
        fileType = FileType.none;
      }
    }

    final title = jsonData['title'] as String? ?? 'Untitled Set';
    final set = SetModel(
      title: title,
      description: jsonData['description'] as String? ?? '',
      fileType: fileType,
      cards: cards,
    );

    await _flashcardService.createSet(user.uid, set);
    return {'cardCount': cards.length, 'title': title};
  }

  void _clearAll() {
    setState(() {
      _uploadedFiles.clear();
      _links.clear();
      _linkInputController.clear();
      _textController.clear();
      _customTitleController.clear();
      _customCards.clear();
      _customCards.add(_CustomCard());
      _error = null;
      _isSaved = false;
      _isCustomMode = widget.startInCustomMode;
    });
  }

  void _addCustomCard() {
    setState(() => _customCards.add(_CustomCard()));
  }

  void _removeCustomCard(int index) {
    if (_customCards.length > 1) {
      setState(() => _customCards.removeAt(index));
    }
  }

  bool _canGenerate() {
    return _uploadedFiles.isNotEmpty ||
           _links.isNotEmpty ||
           _textController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? colorScheme.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: _isLoading
            ? _buildLoadingState(theme, colorScheme)
            : _isSaved
                ? _buildSuccessState(theme, colorScheme)
                : _isCustomMode
                    ? _buildCustomMode(theme, colorScheme, isDark)
                    : _buildUploadMode(theme, colorScheme, isDark),
      ),
    );
  }

  Widget _buildUploadMode(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Upload Content',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface.withAlpha(153)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Add files, links, and text to generate flashcards',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(128)),
          ),
          const SizedBox(height: 24),

          if (_error != null) ...[
            _buildErrorBanner(theme, colorScheme),
            const SizedBox(height: 16),
          ],

          // Files Section
          _buildSectionHeader('FILES', '${_uploadedFiles.length}/$maxFiles', theme, colorScheme),
          const SizedBox(height: 12),
          _buildFileUploadArea(theme, colorScheme, isDark),
          if (_uploadedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._uploadedFiles.asMap().entries.map((e) =>
              _buildFileChip(e.key, e.value, theme, colorScheme, isDark)),
          ],
          const SizedBox(height: 24),

          // Links Section
          _buildSectionHeader('LINKS', '${_links.length}/$maxLinks', theme, colorScheme),
          const SizedBox(height: 12),
          _buildLinkInput(theme, colorScheme, isDark),
          if (_links.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._links.asMap().entries.map((e) =>
              _buildLinkChip(e.key, e.value, theme, colorScheme, isDark)),
          ],
          const SizedBox(height: 24),

          // Text Section
          _buildSectionHeader(
            'TEXT',
            '${_textController.text.length}/$maxTextLength',
            theme,
            colorScheme,
          ),
          const SizedBox(height: 12),
          _buildTextArea(theme, colorScheme, isDark),
          const SizedBox(height: 24),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canGenerate() ? _processContent : null,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: colorScheme.onSurface.withAlpha(30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                'Generate Flashcards',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: _canGenerate() ? colorScheme.onPrimary : colorScheme.onSurface.withAlpha(102),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMode(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Custom Creation',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface.withAlpha(153)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Create your own flashcards from scratch',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(128)),
          ),
          const SizedBox(height: 24),

          if (_error != null) ...[
            _buildErrorBanner(theme, colorScheme),
            const SizedBox(height: 16),
          ],

          // Title
          Text('Set Title', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _customTitleController,
            style: theme.textTheme.bodyMedium,
            decoration: _inputDecoration('Enter a title for your set', colorScheme, isDark),
          ),
          const SizedBox(height: 24),

          // Cards
          Row(
            children: [
              Expanded(
                child: Text(
                  'Flashcards (${_customCards.length})',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              TextButton.icon(
                onPressed: _addCustomCard,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Card'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._customCards.asMap().entries.map((e) =>
            _buildCustomCardItem(e.key, e.value, theme, colorScheme, isDark)),

          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveCustomSet,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Save Flashcard Set', style: theme.textTheme.labelLarge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCardItem(int index, _CustomCard card, ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Card ${index + 1}', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(102))),
              const Spacer(),
              if (_customCards.length > 1)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: colorScheme.onSurface.withAlpha(102)),
                  onPressed: () => _removeCustomCard(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: card.frontController,
            style: theme.textTheme.bodyMedium,
            decoration: _inputDecoration('Front (term or question)', colorScheme, isDark),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: card.backController,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            decoration: _inputDecoration('Back (definition or answer)', colorScheme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withAlpha(102),
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          count,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withAlpha(102),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadArea(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return InkWell(
      onTap: _uploadedFiles.length < maxFiles ? _pickFiles : null,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(
            color: colorScheme.outline.withAlpha(50),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: colorScheme.onSurface.withAlpha(102),
            ),
            const SizedBox(height: 8),
            Text(
              'Click to upload files',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, images, or text files (max $maxFiles)',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(102)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileChip(int index, _UploadedFile file, ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(_getFileIcon(file.mimeType), size: 18, color: colorScheme.onSurface.withAlpha(153)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(file.name, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colorScheme.onSurface.withAlpha(102)),
            onPressed: () => _removeFile(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkInput(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _linkInputController,
            style: theme.textTheme.bodyMedium,
            decoration: _inputDecoration('Paste YouTube or web URL', colorScheme, isDark),
            onSubmitted: (_) => _addLink(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _links.length < maxLinks ? _addLink : null,
          icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildLinkChip(int index, String link, ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final isYouTube = _promptService.isYouTubeUrl(link);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(
            isYouTube ? Icons.play_circle_outline : Icons.link,
            size: 18,
            color: colorScheme.onSurface.withAlpha(153),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(link, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colorScheme.onSurface.withAlpha(102)),
            onPressed: () => _removeLink(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return TextField(
      controller: _textController,
      style: theme.textTheme.bodyMedium,
      maxLines: 4,
      maxLength: maxTextLength,
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration('Paste notes, articles, or any text content...', colorScheme, isDark).copyWith(
        counterText: '',
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, ColorScheme colorScheme, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(102)),
      filled: true,
      fillColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.error.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.error.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: colorScheme.error),
            onPressed: () => setState(() => _error = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating flashcards...',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            'This may take a moment',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(128)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(Icons.check_circle, size: 40, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Flashcards Created!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '$_cardCount cards added to "$_setTitle"',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(128)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearAll,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: const Text('Create Another'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf_rounded;
    if (mimeType.startsWith('image/')) return Icons.image_rounded;
    return Icons.description_rounded;
  }
}

class _UploadedFile {
  final Uint8List bytes;
  final String name;
  final String mimeType;

  _UploadedFile({required this.bytes, required this.name, required this.mimeType});
}

class _CustomCard {
  final TextEditingController frontController = TextEditingController();
  final TextEditingController backController = TextEditingController();
}
