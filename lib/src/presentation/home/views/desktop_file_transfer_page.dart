import 'package:connect/src/data/models/browse_res.dart';
import 'package:connect/src/domain/bloc/file_transfer/file_transfer_cubit.dart';
import 'package:connect/src/domain/bloc/server/server_bloc.dart';
import 'package:connect/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class DesktopFileTransferPage extends StatefulWidget {
  const DesktopFileTransferPage({super.key});

  @override
  State<DesktopFileTransferPage> createState() =>
      _DesktopFileTransferPageState();
}

class _DesktopFileTransferPageState extends State<DesktopFileTransferPage> {
  final FocusNode _focusNode = FocusNode();

  // --- Drag Select State ---
  Offset? _startPoint;
  Offset? _endPoint;
  bool _isDragging = false;

  // Stores files currently under the blue box
  final Set<FileElement> _dragSelectedItems = {};

  // Keys to locate items on screen
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServerBloc, ServerState>(
      builder: (_, serverState) => BlocProvider(
        create: (_) => FileTransferCubit(
          baseUrl: "http://${serverState.devices.firstOrNull?.device.ip ?? ""}",
        )..browse(),
        child: BlocBuilder<FileTransferCubit, FileTransferState>(
          builder: (context, state) {
            // 1. Path Parsing
            List<String> pathSegments = state.currentPath.split('/');

            // 2. Loading State
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // 3. Sync Keys (Ensure we have a key for every file)
            if (_itemKeys.length != state.files.length) {
              _itemKeys.clear();
              for (int i = 0; i < state.files.length; i++) {
                _itemKeys[i] = GlobalKey();
              }
            }

            return LayoutBuilder(
              builder: (_, constraints) => CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.keyA, control: true):
                      context.read<FileTransferCubit>().onSelectAll,
                },
                child: Focus(
                  focusNode: _focusNode,
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    return KeyEventResult.ignored;
                  },
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      // --- Breadcrumbs ---
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pathSegments.length,
                          separatorBuilder: (_, i) =>
                              const Icon(Icons.navigate_next, size: 16),
                          itemBuilder: (_, i) {
                            return InkWell(
                              onTap: () {
                                String newPath = pathSegments
                                    .sublist(0, i + 1)
                                    .join("/");
                                context
                                    .read<FileTransferCubit>()
                                    .updateCurrentDirectory(newPath);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  pathSegments[i].isEmpty
                                      ? '/'
                                      : pathSegments[i],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const Divider(height: 1),

                      // --- File Grid Area ---
                      Expanded(
                        child: GestureDetector(
                          // IMPORTANT: Catches clicks on empty space
                          behavior: HitTestBehavior.translucent,

                          // 1. Handle Click on Blank Space -> Clear Selection
                          onTap: () {
                            // Ensure you add clearSelection() to your Cubit
                            context.read<FileTransferCubit>().clearSelection();
                            setState(() {
                              _dragSelectedItems.clear();
                            });
                          },

                          // 2. Start Dragging
                          onPanStart: (details) {
                            // Also clear selection when starting a NEW drag on empty space
                            context.read<FileTransferCubit>().clearSelection();

                            setState(() {
                              _isDragging = true;
                              _startPoint = details.localPosition;
                              _endPoint = details.localPosition;
                              _dragSelectedItems.clear();
                            });
                          },

                          // Update Drag Box
                          onPanUpdate: (details) {
                            setState(() {
                              _endPoint = details.localPosition;
                            });
                            _updateDragSelection(state.files);
                          },

                          // End Dragging
                          onPanEnd: (details) {
                            final cubit = context.read<FileTransferCubit>();
                            // Add dragged items to the main selection
                            for (var file in _dragSelectedItems) {
                              if (!state.selectedFiles.contains(file)) {
                                cubit.onToggleSelect(file);
                              }
                            }

                            setState(() {
                              _isDragging = false;
                              _startPoint = null;
                              _endPoint = null;
                              _dragSelectedItems.clear();
                            });
                          },
                          child: Stack(
                            children: [
                              // Layer 1: The Grid
                              GridView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: state.files.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          (constraints.maxWidth / 128).ceil(),
                                      mainAxisExtent: 128,
                                      childAspectRatio: 3 / 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                    ),
                                itemBuilder: (_, i) {
                                  FileElement f = state.files[i];

                                  // Determine Selection State
                                  bool isSelected =
                                      state.selectedFiles.contains(f) ||
                                      _dragSelectedItems.contains(f);

                                  return KeyedSubtree(
                                    key: _itemKeys[i], // Attach GlobalKey
                                    child: InkWell(
                                      onSecondaryTapDown: (details) =>
                                          _showContextMenu(context, details, f),
                                      onTap: () => context
                                          .read<FileTransferCubit>()
                                          .onToggleSelect(f),
                                      onDoubleTap: () {
                                        if (f.path != null) {
                                          context
                                              .read<FileTransferCubit>()
                                              .updateCurrentDirectory(f.path!);
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _buildIcon(state, f),
                                            const SizedBox(height: 8),
                                            Text(
                                              f.name ?? "",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Layer 2: The Selection Rectangle Painter
                              if (_isDragging &&
                                  _startPoint != null &&
                                  _endPoint != null)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _SelectionPainter(
                                        rect: Rect.fromPoints(
                                          _startPoint!,
                                          _endPoint!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
    );
  }

  // --- Logic Helpers ---

  void _updateDragSelection(List<FileElement> files) {
    if (_startPoint == null || _endPoint == null) return;

    final selectionRect = Rect.fromPoints(_startPoint!, _endPoint!);
    final newDragSelection = <FileElement>{};

    for (int i = 0; i < files.length; i++) {
      final key = _itemKeys[i];
      if (key == null) continue;

      final context = key.currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final offset = box.localToGlobal(
          Offset.zero,
          ancestor: context.findAncestorRenderObjectOfType<RenderStack>(),
        );

        if (offset != null) {
          final itemRect = offset & box.size;
          if (selectionRect.overlaps(itemRect)) {
            newDragSelection.add(files[i]);
          }
        }
      }
    }

    if (newDragSelection.length != _dragSelectedItems.length ||
        !newDragSelection.containsAll(_dragSelectedItems)) {
      setState(() {
        _dragSelectedItems.clear();
        _dragSelectedItems.addAll(newDragSelection);
      });
    }
  }

  void _showContextMenu(
    BuildContext context,
    TapDownDetails details,
    FileElement f,
  ) {
    final offset = details.globalPosition;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        MediaQuery.of(context).size.width - offset.dx,
        MediaQuery.of(context).size.height - offset.dy,
      ),
      items: [
        if (f.isDir ?? false)
          PopupMenuItem(
            child: const Text('Open'),
            onTap: () {
              if (f.path != null) {
                context.read<FileTransferCubit>().updateCurrentDirectory(
                  f.path!,
                );
              }
            },
          ),
        PopupMenuItem(
          child: const Text('Save'),
          onTap: () {
            // Implement download logic here
          },
        ),
      ],
    );
  }

  Widget _buildIcon(FileTransferState state, FileElement element) {
    double size = 48;
    if (element.isDir ?? false) {
      return Icon(BoxIcons.bx_folder, size: size, color: Colors.amber);
    }

    final name = element.name?.toLowerCase() ?? "";
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      String finalPath =
          "${state.baseUrl}:8080${element.path?.replaceAll('/storage/emulated/0', '/files/') ?? ""}";

      return Image.network(
        finalPath,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(BoxIcons.bx_image, size: size),
      );
    }

    return Icon(BoxIcons.bx_file, size: size, color: Colors.grey);
  }
}

class _SelectionPainter extends CustomPainter {
  final Rect rect;
  _SelectionPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
