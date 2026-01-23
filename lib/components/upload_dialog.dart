import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/models/flashcard_model.dart';

const double _cardRadius = 8.0;

enum UploadMode { none, files, link, text }

class UploadDialog extends StatefulWidget {
  const UploadDialog({super.key});

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  final PromptService _promptService = PromptService();
  final FlashcardSetService _flashcardService = FlashcardSetService();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  UploadMode _selectedMode = UploadMode.none;
  bool _isLoading = false;
  String? _error;
  bool _isSaved = false;
  int _cardCount = 0;
  String _setTitle = '';
  final List<_UploadedFile> _uploadedFiles = [];

  @override
  void dispose() {
    _linkController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp', 'txt'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
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
      setState(() {
        _error = 'Failed to pick files: $e';
      });
    }
  }

  Future<void> _processContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String result;

      if (_selectedMode == UploadMode.files && _uploadedFiles.isNotEmpty) {
        if (_uploadedFiles.length == 1) {
          final file = _uploadedFiles.first;
          if (file.mimeType == 'application/pdf') {
            result = await _promptService.generateFromPdf(file.bytes);
          } else if (file.mimeType.startsWith('image/')) {
            result = await _promptService.generateFromImage(file.bytes, file.mimeType);
          } else if (file.mimeType == 'text/plain') {
            final text = String.fromCharCodes(file.bytes);
            result = await _promptService.generateFromText(text);
          } else {
            throw Exception('Unsupported file type: ${file.mimeType}');
          }
        } else {
          final fileInputs = _uploadedFiles
              .map((f) => FileInput(bytes: f.bytes, mimeType: f.mimeType, fileName: f.name))
              .toList();
          result = await _promptService.generateFromMultipleFiles(fileInputs);
        }
      } else if (_selectedMode == UploadMode.link && _linkController.text.trim().isNotEmpty) {
        final link = _linkController.text.trim();
        if (_promptService.isYouTubeUrl(link)) {
          result = await _promptService.generateFromYouTube(link);
        } else {
          result = await _promptService.generateFromUrl(link);
        }
      } else if (_selectedMode == UploadMode.text && _textController.text.trim().isNotEmpty) {
        result = await _promptService.generateFromText(_textController.text.trim());
      } else {
        throw Exception('Please provide content to generate flashcards.');
      }

      final cleanResult = _cleanJsonResponse(result);
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

  void _removeFile(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _uploadedFiles.clear();
      _linkController.clear();
      _textController.clear();
      _selectedMode = UploadMode.none;
      _error = null;
      _isSaved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: _isLoading
            ? _buildLoadingState(theme, colorScheme)
            : _isSaved
                ? _buildSuccessState(theme, colorScheme)
                : _selectedMode == UploadMode.none
                    ? _buildModeSelection(theme, colorScheme, isDark)
                    : _buildInputState(theme, colorScheme, isDark),
      ),
    );
  }

  Widget _buildModeSelection(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Create Flashcards', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface.withAlpha(153)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to create your flashcards',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(153)),
          ),
          const SizedBox(height: 24),
          _UploadOptionCard(
            icon: Icons.upload_file_rounded,
            title: 'Upload Files',
            subtitle: 'PDF, images, or text files',
            onTap: () => setState(() => _selectedMode = UploadMode.files),
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _UploadOptionCard(
            icon: Icons.link_rounded,
            title: 'Paste Link',
            subtitle: 'YouTube videos or web URLs',
            onTap: () => setState(() => _selectedMode = UploadMode.link),
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _UploadOptionCard(
            icon: Icons.notes_rounded,
            title: 'Enter Text',
            subtitle: 'Paste notes, articles, or content',
            onTap: () => setState(() => _selectedMode = UploadMode.text),
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
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
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary)),
          ),
          const SizedBox(height: 20),
          Text('Generating flashcards...', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('This may take a moment', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(153))),
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
            decoration: BoxDecoration(color: colorScheme.primary.withAlpha(26), borderRadius: BorderRadius.circular(32)),
            child: Icon(Icons.check_circle, size: 40, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Flashcards Created!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '$_cardCount cards added to "$_setTitle"',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(153)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'View your new set in the Library',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(102)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
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

  Widget _buildInputState(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface.withAlpha(153)),
                onPressed: () => setState(() => _selectedMode = UploadMode.none),
              ),
              Expanded(
                child: Text(
                  _selectedMode == UploadMode.files ? 'Upload Files' : _selectedMode == UploadMode.link ? 'Paste Link' : 'Enter Text',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.onSurface.withAlpha(153)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.error.withAlpha(26),
                borderRadius: BorderRadius.circular(_cardRadius),
                border: Border.all(color: colorScheme.error.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_selectedMode == UploadMode.files) _buildFileSection(theme, colorScheme, isDark),
          if (_selectedMode == UploadMode.link) ...[
            Text('Enter a YouTube video URL or any web link', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(153))),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _linkController,
              hint: 'https://youtube.com/watch?v=... or any URL',
              icon: Icons.link_rounded,
              theme: theme,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
          ],
          if (_selectedMode == UploadMode.text) ...[
            Text('Paste your study notes, articles, or any text content', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(153))),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _textController,
              hint: 'Paste your content here...',
              icon: Icons.notes_rounded,
              maxLines: 8,
              theme: theme,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canGenerate() ? _processContent : null,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: colorScheme.primary.withAlpha(51),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
              ),
              child: Text('Generate Flashcards', style: theme.textTheme.labelLarge),
            ),
          ),
        ],
      ),
    );
  }

  bool _canGenerate() {
    if (_selectedMode == UploadMode.files) return _uploadedFiles.isNotEmpty;
    if (_selectedMode == UploadMode.link) return _linkController.text.trim().isNotEmpty;
    if (_selectedMode == UploadMode.text) return _textController.text.trim().isNotEmpty;
    return false;
  }

  Widget _buildFileSection(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select one or more files to generate flashcards', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(153))),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickFiles,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: colorScheme.outline.withAlpha(isDark ? 255 : 51), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 40, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text('Click to upload', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('PDF, images, or text files', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(153))),
              ],
            ),
          ),
        ),
        if (_uploadedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Selected files (${_uploadedFiles.length})', style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurface.withAlpha(153))),
          const SizedBox(height: 8),
          ..._uploadedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(_cardRadius),
                border: Border.all(color: colorScheme.outline.withAlpha(isDark ? 255 : 51)),
              ),
              child: Row(
                children: [
                  Icon(_getFileIcon(file.mimeType), size: 20, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(file.name, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: colorScheme.onSurface.withAlpha(153)),
                    onPressed: () => _removeFile(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      style: theme.textTheme.bodyMedium,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(102)),
        filled: true,
        fillColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
        prefixIcon: maxLines == 1 ? Padding(padding: const EdgeInsets.only(left: 12, right: 8), child: Icon(icon, color: colorScheme.onSurface.withAlpha(153), size: 20)) : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 14 : 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_cardRadius), borderSide: BorderSide(color: colorScheme.outline.withAlpha(isDark ? 255 : 51))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_cardRadius), borderSide: BorderSide(color: colorScheme.outline.withAlpha(isDark ? 255 : 51))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_cardRadius), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf_rounded;
    if (mimeType.startsWith('image/')) return Icons.image_rounded;
    return Icons.description_rounded;
  }
}

class _UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isDark;

  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: colorScheme.outline.withAlpha(isDark ? 255 : 51)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: colorScheme.primary.withAlpha(26), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(153))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurface.withAlpha(102)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadedFile {
  final Uint8List bytes;
  final String name;
  final String mimeType;

  _UploadedFile({required this.bytes, required this.name, required this.mimeType});
}
