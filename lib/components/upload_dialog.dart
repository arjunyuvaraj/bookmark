import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;
import 'package:bookmark/services/prompt_service.dart';

// Notion-style radius
const double _cardRadius = 8.0;

class UploadDialog extends StatefulWidget {
  const UploadDialog({super.key});

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  final PromptService _promptService = PromptService();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  bool _isLoading = false;
  String? _result;
  String? _error;
  final List<_UploadedFile> _uploadedFiles = [];

  @override
  void dispose() {
    _youtubeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp', 'txt'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.bytes != null) {
              _uploadedFiles.add(_UploadedFile(
                bytes: file.bytes!,
                name: file.name,
                mimeType: FileInput.getMimeType(file.name),
              ));
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
      _result = null;
      _error = null;
    });

    try {
      String result;

      if (_uploadedFiles.isNotEmpty) {
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
      } else if (_youtubeController.text.trim().isNotEmpty) {
        result = await _promptService.generateFromYouTube(_youtubeController.text.trim());
      } else if (_textController.text.trim().isNotEmpty) {
        result = await _promptService.generateFromText(_textController.text.trim());
      } else {
        throw Exception('Please upload files, paste a YouTube link, or enter text.');
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _uploadedFiles.clear();
      _youtubeController.clear();
      _textController.clear();
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: _isLoading
            ? _buildLoadingState()
            : _result != null
                ? _buildResultState()
                : _buildInputState(),
      ),
    );
  }

  Widget _buildLoadingState() {
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
              valueColor: AlwaysStoppedAnimation<Color>(colors.secondary),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating flashcards...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This may take a moment',
            style: GoogleFonts.inter(fontSize: 12, color: colors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Generated Output',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.white,
                  ),
                ),
              ),
              _IconBtn(
                icon: Icons.copy_rounded,
                tooltip: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _result ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                  );
                },
              ),
              _IconBtn(icon: Icons.refresh_rounded, tooltip: 'Start over', onTap: _clearAll),
              _IconBtn(icon: Icons.close_rounded, tooltip: 'Close', onTap: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          // JSON output
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.inputBackground,
                borderRadius: BorderRadius.circular(_cardRadius),
                border: Border.all(color: colors.outline),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _result ?? '',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: colors.white.withAlpha(230),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Generate Flashcards',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.white,
                  ),
                ),
              ),
              _IconBtn(icon: Icons.close_rounded, tooltip: 'Close', onTap: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 20),

          // Error
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(_cardRadius),
                border: Border.all(color: Colors.red.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // File upload section
          _SectionLabel('Upload Files'),
          const SizedBox(height: 8),
          _buildFileSection(),
          const SizedBox(height: 20),

          // YouTube section
          _SectionLabel('YouTube Link'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _youtubeController,
            hint: 'https://youtube.com/watch?v=...',
            icon: Icons.play_circle_outline_rounded,
          ),
          const SizedBox(height: 20),

          // Text section
          _SectionLabel('Paste Text'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _textController,
            hint: 'Paste study notes, articles, or any text...',
            icon: Icons.notes_rounded,
            maxLines: 5,
          ),
          const SizedBox(height: 24),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentBlue,
                foregroundColor: colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
              ),
              child: Text(
                'Generate Flashcards',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection() {
    return InkWell(
      onTap: _pickFiles,
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.inputBackground,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: colors.outline),
        ),
        child: Column(
          children: [
            if (_uploadedFiles.isEmpty) ...[
              Icon(Icons.upload_file_rounded, size: 28, color: colors.secondary),
              const SizedBox(height: 8),
              Text(
                'Click to upload files',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PDF, images, or text files',
                style: GoogleFonts.inter(fontSize: 12, color: colors.secondary),
              ),
            ] else ...[
              ..._uploadedFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(_getFileIcon(file.mimeType), size: 18, color: colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          file.name,
                          style: GoogleFonts.inter(fontSize: 13, color: colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeFile(index),
                        child: Icon(Icons.close_rounded, size: 18, color: colors.secondary),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Tap to add more files',
                style: GoogleFonts.inter(fontSize: 11, color: colors.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: colors.white, fontSize: 14),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: colors.secondary, fontSize: 14),
        filled: true,
        fillColor: colors.inputBackground,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: colors.secondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: BorderSide(color: colors.accentBlue),
        ),
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf_rounded;
    if (mimeType.startsWith('image/')) return Icons.image_rounded;
    return Icons.description_rounded;
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.secondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: colors.secondary, size: 20),
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
