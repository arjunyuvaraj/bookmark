import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:bookmark/services/notes_service.dart';
import 'package:bookmark/models/note_model.dart';

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
  final NotesService _notesService = NotesService();
  final TextEditingController _textController = TextEditingController();

  bool _isCustomMode = false;
  bool _isLoading = false;
  String? _error;
  bool _isSaved = false;
  String _noteTitle = '';
  String _noteSubject = '';

  // Combined content
  final List<_UploadedFile> _uploadedFiles = [];
  final List<String> _links = [];
  final TextEditingController _linkInputController = TextEditingController();

  // Custom mode - for creating notes manually
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _customSubjectController = TextEditingController();
  final TextEditingController _customNotesController = TextEditingController();

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
    _customSubjectController.dispose();
    _customNotesController.dispose();
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

  SourceType _determineSourceType() {
    if (_uploadedFiles.isNotEmpty) {
      final mimeType = _uploadedFiles.first.mimeType;
      if (mimeType == 'application/pdf') return SourceType.pdf;
      if (mimeType.startsWith('image/')) return SourceType.image;
      return SourceType.text;
    }
    if (_links.isNotEmpty) {
      if (_promptService.isYouTubeUrl(_links.first)) return SourceType.video;
      return SourceType.url;
    }
    return SourceType.text;
  }

  Future<void> _processContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String result;

      // Process files
      if (_uploadedFiles.isNotEmpty) {
        if (_uploadedFiles.length == 1) {
          final file = _uploadedFiles.first;
          if (file.mimeType == 'application/pdf') {
            result = await _promptService.generateNotesFromPdf(file.bytes);
          } else if (file.mimeType.startsWith('image/')) {
            result = await _promptService.generateNotesFromImage(file.bytes, file.mimeType);
          } else if (file.mimeType == 'text/plain') {
            final text = String.fromCharCodes(file.bytes);
            result = await _promptService.generateNotesFromText(text);
          } else {
            throw Exception('Unsupported file type');
          }
        } else {
          final fileInputs = _uploadedFiles
              .map((f) => FileInput(bytes: f.bytes, mimeType: f.mimeType, fileName: f.name))
              .toList();
          result = await _promptService.generateNotesFromMultipleFiles(fileInputs);
        }
      }
      // Process links
      else if (_links.isNotEmpty) {
        final link = _links.first;
        if (_promptService.isYouTubeUrl(link)) {
          result = await _promptService.generateNotesFromYouTube(link);
        } else {
          result = await _promptService.generateNotesFromUrl(link);
        }
      }
      // Process text
      else if (_textController.text.trim().isNotEmpty) {
        result = await _promptService.generateNotesFromText(_textController.text.trim());
      } else {
        throw Exception('Please add at least one file, link, or text content.');
      }

      final cleanResult = _cleanJsonResponse(result);
      await _saveToFirebase(cleanResult);

      setState(() {
        _isLoading = false;
        _isSaved = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCustomNotes() async {
    if (_customTitleController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a title');
      return;
    }

    if (_customNotesController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter some notes content');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final note = NoteModel(
        title: _customTitleController.text.trim(),
        subject: _customSubjectController.text.trim().isNotEmpty
            ? _customSubjectController.text.trim()
            : 'General',
        notes: _customNotesController.text.trim(),
        sourceType: SourceType.text,
      );

      await _notesService.createNote(user.uid, note);

      setState(() {
        _isLoading = false;
        _isSaved = true;
        _noteTitle = note.title;
        _noteSubject = note.subject;
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

  Future<void> _saveToFirebase(String jsonResult) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final jsonData = jsonDecode(jsonResult) as Map<String, dynamic>;

    final title = jsonData['title'] as String? ?? 'Untitled Notes';
    final subject = jsonData['subject'] as String? ?? 'General';
    final notes = jsonData['notes'] as String? ?? '';

    final note = NoteModel(
      title: title,
      subject: subject,
      notes: notes,
      sourceType: _determineSourceType(),
    );

    await _notesService.createNote(user.uid, note);

    setState(() {
      _noteTitle = title;
      _noteSubject = subject;
    });
  }

  void _clearAll() {
    setState(() {
      _uploadedFiles.clear();
      _links.clear();
      _linkInputController.clear();
      _textController.clear();
      _customTitleController.clear();
      _customSubjectController.clear();
      _customNotesController.clear();
      _error = null;
      _isSaved = false;
      _isCustomMode = widget.startInCustomMode;
    });
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
                icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: colorScheme.onSurface.withAlpha(153), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Add files, links, or text to generate study notes',
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
                'Generate Notes',
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
                  'Create Notes',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: colorScheme.onSurface.withAlpha(153), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Write your own study notes from scratch',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(128)),
          ),
          const SizedBox(height: 24),

          if (_error != null) ...[
            _buildErrorBanner(theme, colorScheme),
            const SizedBox(height: 16),
          ],

          // Title
          Text('Title', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _customTitleController,
            style: theme.textTheme.bodyMedium,
            decoration: _inputDecoration('Enter a title for your notes', colorScheme, isDark),
          ),
          const SizedBox(height: 16),

          // Subject
          Text('Subject', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _customSubjectController,
            style: theme.textTheme.bodyMedium,
            decoration: _inputDecoration('e.g., Biology, History, Math', colorScheme, isDark),
          ),
          const SizedBox(height: 16),

          // Notes Content
          Text('Notes', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _customNotesController,
            style: theme.textTheme.bodyMedium,
            maxLines: 10,
            decoration: _inputDecoration('Write your notes here... (Markdown supported)', colorScheme, isDark),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveCustomNotes,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Save Notes', style: theme.textTheme.labelLarge),
            ),
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
            HugeIcon(
              icon: HugeIcons.strokeRoundedCloudUpload,
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
          HugeIcon(icon: _getFileIcon(file.mimeType), size: 18, color: colorScheme.onSurface.withAlpha(153)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(file.name, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: colorScheme.onSurface.withAlpha(102)),
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
          icon: HugeIcon(icon: HugeIcons.strokeRoundedAddCircle, size: 24, color: colorScheme.primary),
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
          HugeIcon(
            icon: isYouTube ? HugeIcons.strokeRoundedPlayCircle : HugeIcons.strokeRoundedLink01,
            size: 18,
            color: colorScheme.onSurface.withAlpha(153),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(link, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: colorScheme.onSurface.withAlpha(102)),
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
          HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: colorScheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: colorScheme.error),
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
            'Generating notes...',
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
            child: Center(
              child: HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 40, color: colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Notes Created!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '"$_noteTitle" saved to your library',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(128)),
            textAlign: TextAlign.center,
          ),
          if (_noteSubject.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _noteSubject,
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary),
              ),
            ),
          ],
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

  dynamic _getFileIcon(String mimeType) {
    if (mimeType == 'application/pdf') return HugeIcons.strokeRoundedPdf01;
    if (mimeType.startsWith('image/')) return HugeIcons.strokeRoundedImage01;
    return HugeIcons.strokeRoundedFile01;
  }
}

class _UploadedFile {
  final Uint8List bytes;
  final String name;
  final String mimeType;

  _UploadedFile({required this.bytes, required this.name, required this.mimeType});
}
