import 'package:bookmark/services/flashcard_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;
import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/services/authentication_service.dart';

class NewSetScreen extends StatefulWidget {
  final SetModel? existingSet;
  final List<Flashcard>? preloadedCards;

  const NewSetScreen({super.key, this.existingSet, this.preloadedCards});

  @override
  State<NewSetScreen> createState() => _NewSetScreenState();
}

class _NewSetScreenState extends State<NewSetScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<_FlashcardItem> _cards = [];
  bool _isLoading = false;

  final FlashcardSetService _setService = FlashcardSetService();
  final AuthenticationService _authService = AuthenticationService();

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Load existing set or preloaded cards
    if (widget.existingSet != null) {
      _loadExistingSet();
    } else if (widget.preloadedCards != null) {
      _loadPreloadedCards();
    } else {
      _addNewCard();
      _addNewCard();
    }

    _animationController.forward();
  }

  void _loadExistingSet() {
    _titleController.text = widget.existingSet!.title;
    _descriptionController.text = widget.existingSet!.description;
    _cards = widget.existingSet!.cards
        .map(
          (card) => _FlashcardItem(
            questionController: TextEditingController(text: card.question),
            answerController: TextEditingController(text: card.answer),
          ),
        )
        .toList();
  }

  void _loadPreloadedCards() {
    _cards = widget.preloadedCards!
        .map(
          (card) => _FlashcardItem(
            questionController: TextEditingController(text: card.question),
            answerController: TextEditingController(text: card.answer),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    for (var card in _cards) {
      card.questionController.dispose();
      card.answerController.dispose();
    }
    super.dispose();
  }

  void _addNewCard() {
    setState(() {
      _cards.add(
        _FlashcardItem(
          questionController: TextEditingController(),
          answerController: TextEditingController(),
        ),
      );
    });

    // Scroll to bottom after card is added
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

  void _removeCard(int index) {
    if (_cards.length > 2) {
      setState(() {
        _cards[index].questionController.dispose();
        _cards[index].answerController.dispose();
        _cards.removeAt(index);
      });
    } else {
      _showSnackbar('You must have at least 2 cards');
    }
  }

  Future<void> _saveSet() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar('Please fill in all required fields');
      return;
    }

    if (_cards.any(
      (card) =>
          card.questionController.text.trim().isEmpty ||
          card.answerController.text.trim().isEmpty,
    )) {
      _showSnackbar('All cards must have a question and answer');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        _showSnackbar('You must be logged in to create a set');
        return;
      }

      final flashcards = _cards
          .map(
            (card) => Flashcard(
              question: card.questionController.text.trim(),
              answer: card.answerController.text.trim(),
            ),
          )
          .toList();

      final setModel = SetModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cards: flashcards,
        dateAdded: DateTime.now(),
        sessions: 0,
      );

      if (widget.existingSet != null) {
        // Update existing set
        final success = await _setService.updateSet(
          user.uid,
          widget.existingSet!.id!,
          setModel,
        );

        if (success) {
          _showSnackbar('Set updated successfully!');
          Navigator.pop(context);
        } else {
          _showSnackbar('Failed to update set');
        }
      } else {
        // Create new set
        final setId = await _setService.createSet(user.uid, setModel);

        if (setId != null) {
          _showSnackbar('Set created successfully!');
          Navigator.pop(context);
        } else {
          _showSnackbar('Failed to create set');
        }
      }
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.mediumGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.almostBlack,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSetInfo(),
                        const SizedBox(height: 32),
                        _buildCardsSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colors.darkGray,
        border: Border(
          bottom: BorderSide(
            color: colors.borderGray.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingSet != null
                      ? 'Edit Set'
                      : 'Create a new study set',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_cards.length} cards',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.textGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isLoading ? null : _saveSet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? colors.primaryBlueDark
                      : colors.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            color: colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.existingSet != null ? 'Save' : 'Create',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderGray.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _titleController,
            label: 'Title',
            hint: 'Enter a title, like "Biology - Chapter 3"',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description (optional)',
            hint: 'Add a description...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textGray,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 15, color: colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: colors.textGray.withOpacity(0.5),
            ),
            filled: true,
            fillColor: colors.mediumGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF453A)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cards',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.white,
                ),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _addNewCard,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.mediumGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderGray, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        color: colors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add card',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ..._cards.asMap().entries.map((entry) {
          final index = entry.key;
          final card = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCardItem(index, card),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCardItem(int index, _FlashcardItem card) {
    return Container(
      decoration: BoxDecoration(
        color: colors.darkGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderGray.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.borderGray.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (_cards.length > 2)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _removeCard(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.mediumGray,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colors.textGray,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCardTextField(
                  controller: card.questionController,
                  label: 'QUESTION',
                  hint: 'Enter question',
                ),
                const SizedBox(height: 16),
                _buildCardTextField(
                  controller: card.answerController,
                  label: 'ANSWER',
                  hint: 'Enter answer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textGray,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 15, color: colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: colors.textGray.withOpacity(0.4),
            ),
            filled: true,
            fillColor: colors.mediumGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlashcardItem {
  final TextEditingController questionController;
  final TextEditingController answerController;

  _FlashcardItem({
    required this.questionController,
    required this.answerController,
  });
}
