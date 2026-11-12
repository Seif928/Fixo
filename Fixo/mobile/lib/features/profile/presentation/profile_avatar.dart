import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/fixo_colors.dart';
import '../data/avatar_repository.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    super.key,
    required this.userId,
    this.version,
    this.hasAvatar = false,
    this.size = 64,
  });
  final String userId;
  final String? version;
  final bool hasAvatar;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = CircleAvatar(
      radius: size / 2,
      backgroundColor: context.fixoPalette.surfaceHigh,
      child: Icon(
        Icons.person_outline,
        size: size / 2,
        color: context.fixoPalette.deepForest,
      ),
    );
    if (!hasAvatar || version == null) return placeholder;
    return ref
        .watch(privateAvatarProvider('$userId:$version'))
        .when(
          data: (bytes) => bytes == null
              ? placeholder
              : ClipOval(
                  child: Image.memory(
                    bytes,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    gaplessPlayback: false,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
                ),
          loading: () => placeholder,
          error: (_, _) => placeholder,
        );
  }
}
