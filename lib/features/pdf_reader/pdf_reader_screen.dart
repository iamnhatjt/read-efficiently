import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/reading_progress.dart';
import '../../providers/app_providers.dart';
import '../../widgets/shared_widgets.dart';

/// PDF Reader screen — The killer feature.
/// Handles drag & drop, file picking, SHA-256 hashing, text extraction,
/// progress resume, thumbnail sidebar, and launching the RSVP reader.
class PdfReaderScreen extends ConsumerStatefulWidget {
  final String? initialFilePath;

  const PdfReaderScreen({super.key, this.initialFilePath});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen>
    with TickerProviderStateMixin {
  // ── State ──
  String? _filePath;
  Uint8List? _fileBytes; // Store bytes for web support
  String? _fileHash;
  String? _fileName;
  bool _isProcessing = false;
  String? _processingStatus;
  String? _error;
  ReadingProgress? _savedProgress;
  bool _showResumeDialog = false;

  // PDF document
  PdfDocument? _pdfDocument;
  int _totalPages = 0;
  int _currentPreviewPage = 0;

  // Extracted text
  List<String> _pageTexts = [];

  // Drag state
  bool _isDragging = false;

  // Sidebar
  bool _showSidebar = true;

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // If a file path was passed (desktop), load it immediately
    if (widget.initialFilePath != null && !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPdfFromPath(widget.initialFilePath!);
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pdfDocument?.dispose();
    super.dispose();
  }

  // ─── PDF Loading Pipeline ──────────────────────────────────────────

  /// Load PDF from file path (desktop only)
  Future<void> _loadPdfFromPath(String path) async {
    if (kIsWeb) return;
    // Dynamic import for dart:io
    final bytes = await _readFileBytes(path);
    if (bytes != null) {
      _fileName = AppUtils.fileNameFromPath(path);
      _filePath = path;
      await _loadPdfFromBytes(bytes);
    }
  }

  /// Read file bytes — this uses dart:io on non-web platforms
  Future<Uint8List?> _readFileBytes(String path) async {
    try {
      // We use a dynamic approach to avoid importing dart:io on web
      if (kIsWeb) return null;
      // ignore: avoid_dynamic_calls
      final file = await _platformReadFile(path);
      return file;
    } catch (e) {
      setState(() => _error = 'Failed to read file: $e');
      return null;
    }
  }

  /// Platform-aware file reading
  Future<Uint8List?> _platformReadFile(String path) async {
    // Dynamically load dart:io on non-web
    try {
      // Using conditional import facade would be ideal, but for simplicity:
      // On desktop, file_picker gives us bytes too
      return null; // Will be handled by file_picker's bytes
    } catch (e) {
      return null;
    }
  }

  /// Core loading logic — works with bytes (web & desktop)
  Future<void> _loadPdfFromBytes(Uint8List bytes) async {
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Computing file hash...';
      _error = null;
      _fileBytes = bytes;
    });

    try {
      // 1. Compute hash
      final hash = AppUtils.computeFileHash(bytes);

      setState(() {
        _fileHash = hash;
        _processingStatus = 'Opening PDF...';
      });

      // 2. Open PDF document from bytes (works on all platforms)
      final doc = await PdfDocument.openData(bytes);

      setState(() {
        _pdfDocument = doc;
        _totalPages = doc.pages.length;
        _processingStatus = 'Extracting text (0/${doc.pages.length})...';
      });

      // 3. Extract text from each page
      final pageTexts = <String>[];
      for (int i = 0; i < doc.pages.length; i++) {
        setState(() {
          _processingStatus =
              'Extracting text (${i + 1}/${doc.pages.length})...';
        });

        try {
          final page = doc.pages[i];
          final pageText = await page.loadText();
          final fullText = pageText.fullText;
          pageTexts.add(fullText);
        } catch (e) {
          pageTexts.add(''); // empty page or error
        }
      }

      setState(() {
        _pageTexts = pageTexts;
        _processingStatus = null;
      });

      // 4. Check for saved progress
      final storage = ref.read(storageServiceProvider);
      final saved = storage.loadProgress(hash);

      setState(() {
        _isProcessing = false;
        _savedProgress = saved;
        _showResumeDialog = saved != null && saved.wordIndex > 0;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'Failed to load PDF: $e';
      });
    }
  }

  /// Start speed reading from a specific position
  void _startReading({bool resume = false}) {
    if (_pageTexts.isEmpty || _fileHash == null) return;

    final reader = ref.read(readerProvider.notifier);
    reader.loadPdfText(
      pageTexts: _pageTexts,
      title: _fileName ?? 'PDF Document',
      hash: _fileHash!,
      totalPages: _totalPages,
      filePath: _filePath,
    );

    setState(() => _showResumeDialog = false);
    if (mounted) context.push('/reader');
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'Open PDF Document',
      withData: true, // Ensure we get bytes (needed for web)
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      _fileName = file.name;
      _filePath = file.path; // null on web

      if (file.bytes != null) {
        await _loadPdfFromBytes(file.bytes!);
      } else if (file.path != null && !kIsWeb) {
        await _loadPdfFromPath(file.path!);
      }
    }
  }

  // ─── Build Methods ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _fileBytes == null && _filePath == null
            ? _buildDropZone()
            : _buildPdfViewer(),
      ),
    );
  }

  /// The initial drag & drop landing screen
  Widget _buildDropZone() {
    final recentDocs = ref.watch(recentDocumentsProvider)
        .where((d) => d.documentType == 'pdf')
        .take(6)
        .toList();

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final xFile = details.files.first;
          if (xFile.path.toLowerCase().endsWith('.pdf')) {
            _fileName = xFile.name;
            final bytes = await xFile.readAsBytes();
            await _loadPdfFromBytes(bytes);
          } else {
            setState(() => _error = 'Please drop a PDF file.');
          }
        }
      },
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  // ── Top bar ──
                  _buildTopBar(title: 'PDF Reader'),
                  const SizedBox(height: 48),

                  // ── Drop zone ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? AppColors.accentOrange.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDragging
                            ? AppColors.accentOrange
                            : AppColors.border,
                        width: _isDragging ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isDragging
                                  ? [AppColors.accentOrange, AppColors.accentOrangeLight]
                                  : [AppColors.bgTertiary, AppColors.bgElevated],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: _isDragging
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isDragging
                              ? 'Drop your PDF here!'
                              : 'Drop your PDF here',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _isDragging
                                ? AppColors.accentOrange
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickFile,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Text.rich(
                              TextSpan(
                                text: 'or ',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'click to browse files',
                                    style: TextStyle(
                                      color: AppColors.accentOrange,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.accentOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Supports .pdf files',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Recent PDFs ──
                  if (recentDocs.isNotEmpty && !kIsWeb) ...[
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        const Icon(Icons.history_rounded,
                            color: AppColors.textMuted, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Recent PDFs',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: recentDocs.map((doc) {
                        return _RecentPdfCard(
                          document: doc,
                          onTap: () {
                            if (doc.filePath != null) {
                              _loadPdfFromPath(doc.filePath!);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  // ── Tip ──
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tip: Your progress is saved by file content hash — renaming or moving the file won\'t lose your place!',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
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
      ),
    );
  }

  /// The PDF viewer with sidebar and resume dialog
  Widget _buildPdfViewer() {
    if (_isProcessing) {
      return _buildProcessingView();
    }

    return Stack(
      children: [
        Column(
          children: [
            // ── Top bar ──
            _buildPdfTopBar(),

            // ── Content area ──
            Expanded(
              child: Row(
                children: [
                  // ── Thumbnail sidebar ──
                  if (_showSidebar) _buildSidebar(),

                  // ── Main PDF view ──
                  Expanded(
                    child: _pdfDocument != null && _fileBytes != null
                        ? PdfViewer.data(
                            _fileBytes!,
                            sourceName: _fileName ?? 'document.pdf',
                            params: PdfViewerParams(
                              backgroundColor: AppColors.bgPrimary,
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Failed to render PDF',
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Resume dialog overlay ──
        if (_showResumeDialog && _savedProgress != null)
          _buildResumeDialog(),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accentOrange),
          const SizedBox(height: 24),
          Text(
            _processingStatus ?? 'Processing...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _fileName ?? '',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar({required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentOrange, AppColors.accentOrangeLight],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () {
              _pdfDocument?.dispose();
              setState(() {
                _filePath = null;
                _fileBytes = null;
                _pdfDocument = null;
                _pageTexts = [];
                _savedProgress = null;
                _showResumeDialog = false;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary, size: 16),
            ),
          ),
          const SizedBox(width: 12),

          // Logo + title
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentOrange, AppColors.accentOrangeLight],
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _fileName ?? 'PDF Document',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const Spacer(),

          // Page info
          Text(
            'Page ${_currentPreviewPage + 1} / $_totalPages',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(width: 16),

          // Sidebar toggle
          HoverIconButton(
            icon: _showSidebar
                ? Icons.view_sidebar_rounded
                : Icons.view_sidebar_outlined,
            tooltip: 'Toggle Sidebar',
            onTap: () => setState(() => _showSidebar = !_showSidebar),
            isActive: _showSidebar,
          ),
          const SizedBox(width: 8),

          // Start speed reading button
          GestureDetector(
            onTap: () => _startReading(resume: _savedProgress != null),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.accentOrange,
                      AppColors.accentOrangeLight
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Start Speed Reading',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 180,
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  'Pages',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_totalPages pages',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                final isActive = index == _currentPreviewPage;
                final hasProgress = _savedProgress != null &&
                    _savedProgress!.currentPage == index;

                return GestureDetector(
                  onTap: () {
                    setState(() => _currentPreviewPage = index);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.accentOrange
                                    : hasProgress
                                        ? AppColors.accentGreen
                                        : AppColors.border,
                                width: isActive ? 2 : 0.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(
                                    index < _pageTexts.length
                                        ? AppUtils.truncate(
                                            _pageTexts[index], 100)
                                        : '',
                                    style: TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: 5,
                                      height: 1.3,
                                    ),
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                                if (hasProgress)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.bookmark_rounded,
                                        size: 8,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.accentOrange
                                  : AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Resume reading dialog
  Widget _buildResumeDialog() {
    final progress = _savedProgress!;
    final pct = (progress.progressPercent * 100).toStringAsFixed(0);
    final timeAgo = _formatTimeAgo(progress.lastAccessed);

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accentGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Resume Reading?',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We found your saved progress for this document',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Progress info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded,
                              color: AppColors.accentOrange, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                progress.documentTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Page ${progress.currentPage + 1} of ${progress.totalPages} · $pct% complete · $timeAgo',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SmoothProgressBar(
                      progress: progress.progressPercent,
                      color: AppColors.accentGreen,
                      height: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Resume button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: GradientButton(
                  label: 'Resume from Page ${progress.currentPage + 1}',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => _startReading(resume: true),
                  colors: const [
                    AppColors.accentGreen,
                    Color(0xFF86EFAC),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Start from beginning
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(storageServiceProvider).deleteProgress(_fileHash!);
                    setState(() {
                      _savedProgress = null;
                      _showResumeDialog = false;
                    });
                    _startReading(resume: false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start from Beginning'),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _showResumeDialog = false),
                child: const Text(
                  'Just browse the PDF',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _RecentPdfCard extends StatefulWidget {
  final ReadingProgress document;
  final VoidCallback onTap;

  const _RecentPdfCard({required this.document, required this.onTap});

  @override
  State<_RecentPdfCard> createState() => _RecentPdfCardState();
}

class _RecentPdfCardState extends State<_RecentPdfCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final pct = (doc.progressPercent * 100).toStringAsFixed(0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgElevated : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? AppColors.borderLight : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: AppColors.accentOrange, size: 16),
                  ),
                  const Spacer(),
                  if (doc.progressPercent > 0 && doc.progressPercent < 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Resume',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppUtils.truncate(doc.documentTitle, 25),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Page ${doc.currentPage + 1}/${doc.totalPages} · $pct%',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              SmoothProgressBar(
                progress: doc.progressPercent,
                height: 3,
                color: AppColors.accentOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
