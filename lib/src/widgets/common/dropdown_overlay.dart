import 'package:flutter/material.dart';

class DropdownOverlay<T> extends StatefulWidget {
  final Widget child;
  final bool isShowing;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final ValueChanged<T> onItemSelected;
  final VoidCallback? onDismissed;
  final double maxHeight;

  const DropdownOverlay({
    super.key,
    required this.child,
    required this.isShowing,
    required this.items,
    required this.itemBuilder,
    required this.onItemSelected,
    this.onDismissed,
    this.maxHeight = 200.0,
  });

  @override
  State<DropdownOverlay<T>> createState() => _DropdownOverlayState<T>();
}

class _DropdownOverlayState<T> extends State<DropdownOverlay<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void didUpdateWidget(DropdownOverlay<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShowing && !oldWidget.isShowing) {
      _showOverlay();
    } else if (!widget.isShowing && oldWidget.isShowing) {
      _hideOverlay();
    } else if (widget.isShowing && widget.items != oldWidget.items) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _overlayEntry?.markNeedsBuild();
        }
      });
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    // We delay slightly to ensure the widget is fully laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isShowing) return;

      final renderBox =
          _fieldKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      final size = renderBox.size;

      _overlayEntry = OverlayEntry(
        builder: (context) {
          return Stack(
            children: [
              if (widget.onDismissed != null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onDismissed,
                  ),
                ),
              Positioned(
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0.0, size.height + 4.0),
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(4.0),
                    color: Theme.of(context).cardColor,
                    child: Container(
                      constraints: BoxConstraints(maxHeight: widget.maxHeight),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          return InkWell(
                            onTap: () {
                              if (widget.onDismissed != null) {
                                widget.onDismissed!();
                              }
                              // A tiny delay ensures the UI has resolved the tap
                              // before potential focus or state changes.
                              Future.delayed(Duration.zero, () {
                                widget.onItemSelected(item);
                              });
                            },
                            child: widget.itemBuilder(context, item),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    });
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        key: _fieldKey,
        child: widget.child,
      ),
    );
  }
}
