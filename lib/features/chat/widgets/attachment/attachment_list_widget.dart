import 'package:flutter/material.dart';
import '../../../../models/chat/chat_attachment.dart';
import './attachment_chip_widget.dart';

class AttachmentListWidget extends StatefulWidget {
  final List<ChatAttachment> attachments;
  final Function(ChatAttachment) onRemoveAttachment;

  const AttachmentListWidget({
    super.key,
    required this.attachments,
    required this.onRemoveAttachment,
  });

  @override
  State<AttachmentListWidget> createState() => _AttachmentListWidgetState();
}

class _AttachmentListWidgetState extends State<AttachmentListWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.attachments.isNotEmpty) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AttachmentListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.attachments.isNotEmpty && oldWidget.attachments.isEmpty) {
      _animationController.forward();
    } else if (widget.attachments.isEmpty && oldWidget.attachments.isNotEmpty) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.attachments.map((attachment) {
                  return AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: AttachmentChipWidget(
                      key: ValueKey(attachment.id),
                      attachment: attachment,
                      onRemove: () => _handleRemove(attachment),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleRemove(ChatAttachment attachment) {
    // 添加移除动画
    widget.onRemoveAttachment(attachment);
  }
}
